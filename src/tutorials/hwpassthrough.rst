Hardware pass-through to the VM
===============================

In this tutorial we will show you how to grant your VM direct access to
some of the host’s I/O peripherals. We will use QEMU and an aarch64 virtual
machine. For simplicity reasons we will be enabling access to a simple
device: the PL031 real time clock.

The issue
---------

By default, *uvmm* provides a completely virtualized environment to its
guests and allows no access to the hardware devices of the host. For
example, this pertains to the real time clock device used by Linux to
display the actual date and time. Running the *date* command in a guest
from the :doc:`multiplevms` tutorial suggests the guest cannot figure out
the exact time correctly:

::

   / # date
   Thu Jan  1 00:08:19 UTC 1970

Searching the kernel boot messages for the presence of a real time clock
device returns only a warning message:

::

   / # dmesg | grep rtc
   [   11.509784] hctosys: unable to open rtc device (rtc0)

The solution
------------

If you want your VM to be able to access some I/O peripheral, such as
the real time clock, you must explicitly configure it. This will require
some configuration changes on your side as well as new components and
configuration files.

The following subsections will take you through all that. We will
however assume you have just successfully completed the :doc:`multiplevms`
tutorial and made all the configuration steps.

By this time, you should have the following readily available:

-  a fresh aarch64 build of an up-to-date L4Re source tree,
-  an aarch64 Linux build,
-  an aarch64 RAM disk.

IO service
~~~~~~~~~~

First you are going to need a new component: *io*. As its name suggests,
*io* is an I/O service that gives access to I/O peripherals to its
clients. In our case *io*\ ’s client will be *uvmm*, which further
arranges access to the peripherals for the guest.

Make sure there is *somedir/l4/pkg/io* in your source tree and that this
component was built with all the others.

io’s config file
~~~~~~~~~~~~~~~~

Create *somedir/conf/io.cfg* with the following contents:

.. code:: lua

   local Res = Io.Res
   local Hw = Io.Hw

   local add_children = Io.Dt.add_children

   add_children(Io.system_bus(), function()
     rtc = Hw.Device(function()
       compatible = { "arm,pl031" };
       Resource.reg0 = Res.mmio(0x9010000, 0x9010fff);
       Resource.irq0 = Res.irq(32 + 2, Io.Resource.Irq_type_level_high);   -- 32 for ARM_SPI_BASE
     end)
   end)

It is a Lua script which describes what peripherals *io* should manage.
In our case, it only needs to manage the PL031 real time clock.

Note that the register range and IRQ numbers are device- and
machine-specific and will be different if you try this with a different
device or on another platform. In general, you need to know what you are
doing here. Consulting the SoC documentation, looking into the Linux
device tree or even studying QEMU source code may provide valuable
information.

In this particular case, the values were extracted from the machine’s
device tree (see below) and further modified for use by *io.cfg*. One
such modification includes adding the base of 32 for SPI type IRQs to
the IRQ number, as used on the ARM architecture.

Device tree
~~~~~~~~~~~

*io* is not the only one who needs to know what peripherals to manage.
Both *uvmm* and your Linux guest care about those too, so you must tell
them. In Linux one simply describes the available peripherals by the
means of a device tree. *uvmm* comes with its own device tree for the
virtual machine, which is located in
*somedir/l4/pkg/uvmm/configs/dts/virt-arm_virt-64.dts*.

Because of the PL031, you need a slightly modified version. A
straightforward way would be to make modifications directly to
*virt-arm_virt-64.dts*. We will, however, proceed more hygienically and
merge the PL031 bits with the *uvmm* device tree by way of a simple
out-of-tree inclusion.

Create *somedir/conf/pl031.dts* with the following content:

::

   /dts-v1/;
   /include/ "virt-arm_virt-64.dts"

   / {
           pl031@9010000 {
                   clock-names = "apb_pclk";
                   clocks = < 0x8000 >;
                   interrupts = < 0x00 0x02 0x04 >;    /* SPI type IRQ, IRQ 2, level-high */
                   reg = < 0x00 0x9010000 0x00 0x1000 >;
                   compatible = "arm,pl031\0arm,primecell";
           };

           apb-pclk {
                   phandle = < 0x8000 >;
                   clock-output-names = "clk24mhz";
                   clock-frequency = < 0x16e3600 >;
                   #clock-cells = < 0x00 >;
                   compatible = "fixed-clock";
           };
   };

Now build the PL031-enabled device tree like this:

::

   [somedir] $ dtc -O dtb -o conf/virt-arm_virt-64-pl031.dtb -I dts conf/pl031.dts -i l4/pkg/uvmm/configs/dts/

This usually generates some warnings, but you can safely ignore those.

To differentiate this new binary device tree from the one produced by
the *uvmm* build process, name the resulting binary
*virt-arm_virt-64-pl031.dtb*. Use this new name in the modules list and
also in the ned script instead of *virt-arm_virt-64.dtb*, which was used
in the previous tutorials.

Figuring out which nodes to put into the device tree
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

The two nodes you compiled into *virt-arm_virt-64-pl031.dtb* above come
verbatim from the QEMU aarch64 virt machine’s device tree. That device
tree is dynamically constructed by QEMU, but fortunately you can ask
QEMU to dump the device tree binary blob into a file and then decompile
it into its source form:

::

   [somedir] $ qemu-system-aarch64 -nographic -machine virt,virtualization=true,dumpdtb=conf/arm_virt-64-full.dtb
   [somedir] $ dtc -I dtb -O dts conf/arm_virt-64-full.dtb

For other machines, you can use the respective device tree from the
Linux sources.

In any case, you need to transplant the node for your device and all
nodes it references.

Ned script
~~~~~~~~~~

Store the following ned script into *somedir/conf/uvmm-io.ned*:

.. code:: lua

   package.path = "rom/?.lua";

   local L4 = require "L4";
   local vmm = require "vmm";

   vmm.loader.log_fab = L4.default_loader:new_channel();

   local function vm(id, vbus)
     vmm.start_vm({
       id = id,
       mem = 128,
       rd = "rom/ramdisk-armv8-64.cpio.gz",
       fdt = "rom/virt-arm_virt-64-pl031.dtb",
       kernel = "rom/Image.gz",
       vbus = vbus,
       bootargs = "console=ttyAMA0 earlyprintk=1 rdinit=/init",
       ext_args = { "-i" }
     });
   end

   L4.default_loader:start(
     {
       log = L4.Env.log,
       caps = { cons = vmm.loader.log_fab:svr() }
     }, "rom/cons -a");

   local io_busses = {
     vm_hw = 1,
   }

   vmm.start_io(io_busses, "rom/io.cfg -vvvvvv");

   vm(1, io_busses.vm_hw);

As usual, the script comes with a wrapper function *vm* for starting up
guests. Besides a guest ID, it also expects a vbus capability which
names a virtual bus on which there are all the peripherals the guest is
allowed to access. Prior to launching a single guest with ID 1, the ned
script also starts the console multiplexer *cons*, and the *io* service
using the *vmm.start_io* function.

The vbus capability is stored in the *io_busses* table by
*vmm.start_io*. Naming is especially important in this context. Each key
of the *io_busses* table is also interpreted as a base name of a Lua
configuration file which defines the vbus. Here we use *vm_hw* as a key,
so *vmm.start_io* will look for a boot module called *rom/vm_hw.vbus*.
Your job will be to provide one.

Vbus configuration file
~~~~~~~~~~~~~~~~~~~~~~~

Put the following into *somedir/conf/vm_hw.vbus*:

.. code:: lua

   Io.add_vbusses
   {
     vm_hw = Io.Vi.System_bus(function()
       PL031 = wrap(Io.system_bus().rtc);
     end);
   }

This vbus configuration file tells *io* to place the *rtc* device from
the system bus on the vbus which goes by name *vm_hw*. The device on the
vbus will be called *PL031*. Here we have another example of a situation
in which the used names must match names defined elsewhere. In
particular, *vm_hw* must match the *io_busses* table key above and *rtc*
must match the name of the device added in *io.cfg*.

Modules list
~~~~~~~~~~~~

With all the new components, device trees and configuration files in
place, store the following modules list in
*somedir/l4/conf/modules.list*:

::

   entry uvmm-io
   kernel fiasco -serial_esc
   roottask moe rom/uvmm-io.ned
   module uvmm
   module l4re
   module ned
   module virt-arm_virt-64-pl031.dtb
   module ramdisk-armv8-64.cpio.gz
   module[shell] echo $SRC_BASE_ABS/pkg/uvmm/configs/vmm.lua
   module uvmm-io.ned
   module[uncompress] Image.gz
   module cons
   module io
   module io.cfg
   module vm_hw.vbus

Testing it
----------

You should now be able to run the scenario:

::

   [somedir/build-aarch64] $ make E=uvmm-io qemu

In the console output, you should see the following lines printed in red
by *io*:

::

   io      | Io service
   io      | Verboseness level: 7
   io      | unused physical memory space:
   io      |   [00000000000000-0000003fffffff]
   io      |   [00000080000000-ffffffffffffffff]
   io      | no 'iommu' capability found, using CPU-phys for DMA
   io      | Loading: config 'rom/io.cfg'
   io      | Loading: config 'rom/vm_hw.vbus'
   io      | Add IRQ resources to vbus: IRQ     [00000000000022-00000000000022 1] level high (32bit) (align=0 flags=300001)
   io      | vm_hw: [N12_GLOBAL__N_112Virtual_sbusE]
   io      |   Resources: ==== start ====
   io      |   Resources: ===== end =====
   io      |   L4ICU: [N2Vi6Sw_icuE]
   io      |     Resources: ==== start ====
   io      |     Resources: ===== end =====
   io      |   PL031: [N2Vi9Proxy_devE]
   io      |     Resources: ==== start ====
   io      |     IRQ     [00000000000022-00000000000022 1] level high (32bit) (align=0 flags=300001)
   io      |     IOMEM   [00000009010000-00000009010fff 1000] non-pref (32bit) (align=fff flags=2)
   io      |     Resources: ===== end =====
   io      | Real Hardware -----------------------------------
   io      | System Bus: hid=
   io      |   Resources: ==== start ====
   io      |   DMADOM  [00000000000000-00000000000000 1] non-pref (32bit) (align=0 flags=6)
   io      |   Resources: ===== end =====
   io      |   rtc: hid=
   io      |     compatible= { "arm,pl031" }
   io      |     Clients: ===== start ====
   io      |       PL031: [N2Vi9Proxy_devE]
   io      |     Clients: ===== end ====
   io      |     Resources: ==== start ====
   io      |     IRQ     [00000000000022-00000000000022 1] level high (32bit) (align=0 flags=300001)
   io      |     IOMEM   [00000009010000-00000009010fff 1000] non-pref (32bit) (align=fff flags=2)
   io      |     Resources: ===== end =====
   io      | warning: could not register control interface at cap 'platform_ctl'
   io      | Ready. Waiting for request.

In the top half you can see information about the vbus as configured by
*vm_hw.vbus*. The other half informs about the real hardware acquired
based on *io.cfg*.

After the guest boots to a command prompt, make a simple test to see if
the *date* command works any better:

::

   / # date
   Mon Oct  7 10:05:16 UTC 2019

And indeed, you should see the current time instead of a date in 1970.
In the *dmesg* output, there should be no warnings about the real time
clock device. Instead, you should see something like:

::

   / # dmesg | grep rtc
   [    4.640615] rtc-pl031 9010000.pl031: rtc core: registered pl031 as rtc0
   [    5.328392] rtc-pl031 9010000.pl031: setting system clock to 2019-10-07 10:05:09 UTC (1570442709)

Conclusion
----------

In this tutorial you learned to configure direct I/O pass-through for a
simple device. Real-world scenarios are typically way more complex, but
the experience gained here should give you a good starting point.
