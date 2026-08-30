Static partitioning of resources
================================

In this tutorial you will learn to statically partition CPU cores,
memory, and devices among multiple VMs running on top of L4Re. Static
partitioning ensures that each VM operates within well-defined resource
boundaries, which is important for achieving isolation, deterministic
behavior, and mixed-criticality deployments.

Please also refer to the :doc:`multiplevms` and :doc:`hwpassthrough`
tutorials for further information.

Prerequisites
-------------

This tutorial requires an SMP-enabled build with at least 4 CPU cores.

Configuring Fiasco for multi-core
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

By default, Fiasco may be configured for a single CPU. To enable SMP
support, reconfigure the kernel:

::

   [somedir/build-fiasco-aarch64] $ make menuconfig

Navigate to *System* and set ``CONFIG_MP_MAX_CPUS`` to ``4`` (or
higher). Save the configuration and rebuild:

::

   [somedir/build-fiasco-aarch64] $ make

QEMU options
~~~~~~~~~~~~

You need to tell QEMU to emulate a multi-core machine with enough
memory. Edit ``somedir/l4/conf/Makeconf.boot`` and add the
following QEMU flags:

::

   QEMU_OPTIONS += -smp 4 -m 1024

This gives the emulated machine 4 CPU cores and 1024 MB of RAM.

CPU core partitioning
---------------------

L4Re allows you to create scheduler objects that confine threads to a
specific subset of physical CPUs. A scheduler is a kernel object created
via the system factory:

.. code:: lua

   local sched_vm1 = L4.Env.user_factory:create(L4.Proto.Scheduler, 10, 2, 0x3);
   local sched_vm2 = L4.Env.user_factory:create(L4.Proto.Scheduler, 10, 2, 0xc);

The arguments after the protocol are the maximum priority, the base
priority, and a CPU affinity bitmask that determines which physical cores
the program may use. The maximum priority shall be higher than the
base priority to give programs some priorities for their own use.

Common bitmask values:

======  ============
Mask    CPUs
======  ============
0x01    CPU 0
0x02    CPU 1
0x03    CPU 0, 1
0x04    CPU 2
0x0c    CPU 2, 3
0x0f    CPU 0-3
0xf0    CPU 4-7
0xff    CPU 0-7
======  ============

The scheduler object is then passed to ``l:startv()`` via the
``scheduler`` field in the start parameters. All threads of the started
process will be confined to the scheduler's CPU set:

.. code:: lua

   l:startv({
              scheduler = sched_vm1,
              -- ...
            },
            "rom/uvmm", ...);

This constrains the VM's threads to the specified cores, preventing them
from running and thus interfering with workloads on other cores.

Memory partitioning
-------------------

Each VM receives a dedicated memory allocation as a dataspace
capability. The dataspace is created via the factory and passed to
*uvmm* as the ``ram`` capability:

.. code:: lua

   local flags = L4.Mem_alloc_flags.Continuous
                 | L4.Mem_alloc_flags.Pinned
                 | L4.Mem_alloc_flags.Super_pages;
   local align = 21;

   l:startv({
              caps = {
                ram = L4.Env.user_factory:create(L4.Proto.Dataspace,
                                                 256 * 1024 * 1024,
                                                 flags, align):m("rw"),
              },
              -- ...
            },
            "rom/uvmm", ...);

The size is specified in bytes. The memory allocation flags request
physically continuous, pinned memory backed by super pages. The
alignment of 21 corresponds to 2 MiB super pages.

Make sure the total memory allocated to all VMs plus the L4Re system
does not exceed the available RAM. In our QEMU setup with ``-m 1024``,
allocating 256 MiB and 128 MiB leaves sufficient room.

Device and interrupt isolation
------------------------------

To give a VM exclusive access to a hardware device, you need to
configure the *io* service and provide matching virtual bus and device
tree configurations. This section summarizes the approach; refer to
:doc:`hwpassthrough` for a detailed explanation.

In our scenario, only VM1 gets access to the PL031 real time clock. VM2
runs without any hardware passthrough.

io.cfg
~~~~~~

The *io* configuration describes the hardware managed by *io*. Reuse the
configuration from the :doc:`hwpassthrough` tutorial. Create
*somedir/conf/io.cfg*:

.. code:: lua

   local Res = Io.Res
   local Hw = Io.Hw

   local add_children = Io.Dt.add_children

   add_children(Io.system_bus(), function()
     rtc = Hw.Device(function()
       compatible = { "arm,pl031" };
       Resource.reg0 = Res.mmio(0x9010000, 0x9010fff);
       Resource.irq0 = Res.irq(32 + 2, Io.Resource.Irq_type_level_high);
     end)
   end)

Vbus configuration
~~~~~~~~~~~~~~~~~~

The vbus file maps the RTC device to VM1's virtual bus. Create
*somedir/conf/vm1_hw.vbus*:

.. code:: lua

   Io.add_vbusses
   {
     vm1_hw = Io.Vi.System_bus(function()
       PL031 = wrap(Io.system_bus().rtc);
     end);
   }

VM2 does not receive a vbus capability and therefore has no access to
the RTC.

Device tree
~~~~~~~~~~~

VM1 uses the PL031-enhanced device tree (*virt-arm_virt-64-pl031.dtb*)
that was built in the :doc:`hwpassthrough` tutorial. VM2 uses the
standard *virt-arm_virt-64.dtb*.

If you haven't built the PL031 device tree yet, refer to the
:doc:`hwpassthrough` tutorial for the steps.

Starting io from ned
~~~~~~~~~~~~~~~~~~~~

To start *io*, create an IPC channel for the vbus, pass its server end to
*io* as a capability, and hand the config files as command line arguments:

.. code:: lua

   local vbus_vm1 = l:new_channel();

   l:start({
             caps = {
               vm1_hw = vbus_vm1:svr(),
               icu    = L4.Env.icu,
               sigma0 = L4.Env.sigma0,
             },
             log = { "io", "red" },
           },
           "rom/io rom/io.cfg rom/vm1_hw.vbus");

The capability name ``vm1_hw`` must match the vbus name defined in
*vm1_hw.vbus*. The client end of the channel (``vbus_vm1``) will later
be passed to *uvmm* as its ``vbus`` capability.

Putting it all together
-----------------------

Ned script
~~~~~~~~~~

Save the following to *somedir/conf/uvmm-staticpart.ned*:

.. code:: lua

   local L4 = require("L4");

   local l = L4.default_loader;

   local flags = L4.Mem_alloc_flags.Continuous
                 | L4.Mem_alloc_flags.Pinned
                 | L4.Mem_alloc_flags.Super_pages;
   local align = 21;

   -- Start console multiplexer
   local cons = l:new_channel();
   l:start({ caps = { cons = cons:svr() },
             log = L4.Env.log
           },
           "rom/cons -a");

   l.log_fab = cons;

   -- Start IO service for PL031 RTC passthrough
   local vbus_vm1 = l:new_channel();

   l:start({
             caps = {
               vm1_hw = vbus_vm1:svr(),
               icu    = L4.Env.icu,
               sigma0 = L4.Env.sigma0,
             },
             log = { "io", "red" },
           },
           "rom/io rom/io.cfg rom/vm1_hw.vbus");

   -- Create schedulers for CPU partitioning
   local sched_vm1 = L4.Env.user_factory:create(L4.Proto.Scheduler, 10, 2, 0x3);
   local sched_vm2 = L4.Env.user_factory:create(L4.Proto.Scheduler, 10, 2, 0xc);

   -- VM1: CPUs 0-1, 256 MiB, PL031 RTC passthrough
   l:startv({
              caps = {
                ram = L4.Env.user_factory:create(L4.Proto.Dataspace,
                                                 256 * 1024 * 1024,
                                                 flags, align):m("rw"),
                vbus = vbus_vm1,
              },
              scheduler = sched_vm1,
              log = { "vm1", "", "key=1" },
            },
            "rom/uvmm", "-i",
               "-krom/Image.gz",
               "-rrom/ramdisk-armv8-64.cpio.gz",
               "-drom/virt-arm_virt-64-pl031.dtb",
               "-cconsole=ttyAMA0 earlyprintk=1 rdinit=/init");

   -- VM2: CPUs 2-3, 128 MiB, no device passthrough
   l:startv({
              caps = {
                ram = L4.Env.user_factory:create(L4.Proto.Dataspace,
                                                 128 * 1024 * 1024,
                                                 flags, align):m("rw"),
              },
              scheduler = sched_vm2,
              log = { "vm2", "", "key=2" },
            },
            "rom/uvmm", "-i",
               "-krom/Image.gz",
               "-rrom/ramdisk-armv8-64.cpio.gz",
               "-drom/virt-arm_virt-64.dtb",
               "-cconsole=ttyAMA0 earlyprintk=1 rdinit=/init");

VM1 is pinned to CPUs 0 and 1, gets 256 MiB of RAM, and has access to
the PL031 RTC via the *vm1_hw* vbus. VM2 is pinned to CPUs 2 and 3,
gets 128 MiB of RAM, and has no device passthrough.

Each VM is started with ``l:startv()`` which passes the *uvmm*
command line arguments individually. The ``-k``, ``-r``, ``-d`` and
``-c`` flags specify the kernel, ramdisk, device tree and kernel command
line respectively. The ``-i`` flag selects identity mapping for guest
memory.

Modules list
~~~~~~~~~~~~

Add the following entry to *somedir/l4/conf/modules.list*:

::

   entry uvmm-staticpart
   kernel fiasco -serial_esc
   roottask moe rom/uvmm-staticpart.ned
   module uvmm
   module l4re
   module ned
   module virt-arm_virt-64.dtb
   module virt-arm_virt-64-pl031.dtb
   module ramdisk-armv8-64.cpio.gz
   module uvmm-staticpart.ned
   module[uncompress] Image.gz
   module cons
   module io
   module io.cfg
   module vm1_hw.vbus

Testing the setup
-----------------

Run the scenario:

::

   [somedir/build-aarch64] $ make E=uvmm-staticpart qemu

After both VMs have booted, use the console multiplexer to switch
between them. Press *Ctrl-E 1* for VM1 and *Ctrl-E 2* for VM2 (see
:doc:`multiplevms` for details on using *cons*).

In **VM1** (CPUs 0-1, 256 MiB, RTC):

::

   / # nproc
   2
   / # date
   Wed Mar  4 14:23:01 UTC 2026

The ``nproc`` command should report 2, corresponding to the two CPUs
assigned via the scheduler. The ``date`` command should show the current
date and time, confirming the PL031 RTC is working. Running ``free -m``
should show approximately 256 MiB of total memory.

In **VM2** (CPUs 2-3, 128 MiB, no RTC):

::

   / # nproc
   2
   / # date
   Thu Jan  1 00:04:12 UTC 1970

The ``nproc`` command should also report 2. The ``date`` command shows a
date in 1970, confirming that VM2 has no access to the real time clock.
Running ``free -m`` should show approximately 128 MiB of total memory.

Conclusion
----------

In this tutorial you learned to statically partition CPU cores, memory,
and hardware devices among two Linux VMs. VM1 and VM2 run on disjoint
sets of CPU cores, have independent memory allocations, and only VM1
has access to the passed-through PL031 RTC. These techniques form the
basis for building isolated, mixed-criticality systems on L4Re.
