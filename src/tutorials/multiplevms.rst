Running multiple Linux guest VMs
================================

In this tutorial you are going to learn to run two Linux VMs on top of
the L4Re hypervisor. You will start using a console multiplexer for
managing input and output for the individual guests. At the same time
you will find out how to interconnect the two guests using a virtual
network link.

You should be already familiar with the steps necessary to run a single
Linux VM guest on top of L4Re as described in the :doc:`linuxvm`.
You are also going to need the binaries built in that tutorial. This
tutorial is using some new L4Re components, so you need to sync up your L4Re
sources using *ham* and rebuild.

Adding the extra VM
-------------------

Let’s start by creating a ned script for two VMs. It will look much like
the one from the single VM tutorial, but this time we will spawn two VMs
instead of one. Save the following snippet into
*somedir/conf/uvmm-2vm-nocons.ned*:

.. code:: lua

   package.path = "rom/?.lua";

   local L4 = require "L4";
   local vmm = require "vmm";

   local function vm(id)
     vmm.start_vm({
       id = id,
       mem = 128,
       rd = "rom/ramdisk-armv8-64.cpio.gz",
       fdt = "rom/virt-arm_virt-64.dtb",
       kernel = "rom/Image.gz",
       bootargs = "console=ttyAMA0 earlyprintk=1 rdinit=/init",
       log = L4.Env.log,
       ext_args = { "-i" }
     });
   end

   vm(1);
   vm(2);

To make life easier, we create a little wrapper function called *vm*. It
allows you to replace the repetitive invocations of *vmm.start_vm* with
much shorter calls to *vm*. For now, *vm* takes only the VM
identification number so that you can later tell the VMs apart.

The modules list looks familiar (copy the following entry to
*somedir/l4/conf/modules.list*):

::

   entry uvmm-2vm-nocons
   kernel fiasco -serial_esc
   roottask moe rom/uvmm-2vm-nocons.ned
   module uvmm
   module l4re
   module ned
   module virt-arm_virt-64.dtb
   module ramdisk-armv8-64.cpio.gz
   module[shell] echo $SRC_BASE_ABS/pkg/uvmm/configs/vmm.lua
   module uvmm-2vm-nocons.ned
   module[uncompress] Image.gz

After starting this scenario, you’ll notice that indeed now there are
two VMs running, but it is difficult to distinguish one from the other:

::

   [somedir] $ cd build-aarch64
   [somedir/build-aarch64] $ make E=uvmm-2vm-nocons qemu
   ...
   Ned: loading file: 'rom/uvmm-2vm-nocons.ned'
   VMM[vmbus]: 'vbus' capability not found. Hardware access not possible for VM.
   VMM[vmbus]: 'vbus' capability not found. Hardware access not possible for VM.
   VMM[main]: Hello out there.
   VMM[main]: Hello out there.
   VMM[]: Cleaning caches for device tree [91ff000-91ff819] ([527ff000])
   VMM[]: Cleaning caches for device tree [91ff000-91ff819] ([4a7ff000])
   VMM[]: Starting Cpu0 @ 0x42880000 in 64Bit mode (handler @ 10352b0, stack: 8000f9d0, task: 41d000, mpidr: 80000000 (orig: 80000000)
   VMM[]: Starting Cpu0 @ 0x4a880000 in 64Bit mode (handler @ 10352b0, stack: 8000f9d0, task: 41d000, mpidr: 80000000 (orig: 80000000)
   ...

You’ll also quickly discover that it is possible to interact with only
one of them. The reason is that both VMs now compete for the single log
service.

There are two solutions to this problem. Either give each VM a distinct
log capability or use a so called console multiplexer which allows each
VM to create its own console. In this tutorial, we will explore the
latter.

Using console multiplexer to give each VM its own console
---------------------------------------------------------

The console multiplexer is implemented by an L4Re component called
*cons*. You need to add it to the modules list:

::

   entry uvmm-2vm
   kernel fiasco -serial_esc
   roottask moe rom/uvmm-2vm.ned
   module uvmm
   module l4re
   module ned
   module virt-arm_virt-64.dtb
   module ramdisk-armv8-64.cpio.gz
   module[shell] echo $SRC_BASE_ABS/pkg/uvmm/configs/vmm.lua
   module uvmm-2vm.ned
   module[uncompress] Image.gz
   module cons

The ned script needs to be modified in the following way (save the
snippet to *somedir/conf/uvmm-2vm.ned*):

.. code:: lua

   package.path = "rom/?.lua";

   local L4 = require "L4";
   local vmm = require "vmm";

   vmm.loader.log_fab = L4.default_loader:new_channel();

   local function vm(id)
     vmm.start_vm({
       id = id,
       mem = 128,
       rd = "rom/ramdisk-armv8-64.cpio.gz",
       fdt = "rom/virt-arm_virt-64.dtb",
       kernel = "rom/Image.gz",
       bootargs = "console=ttyAMA0 earlyprintk=1 rdinit=/init",
       ext_args = { "-i" }
     });
   end

   L4.default_loader:start(
     {
       log = L4.Env.log,
       caps = { cons = vmm.loader.log_fab:svr() }
     }, "rom/cons -a");

   vm(1);
   vm(2);

Note that we no longer pass *L4.Env.log* to *vmm.start_vm*.

Instead, the script now creates a new IPC channel and passes its server
end to *cons* in a capability of the same name. *cons* uses it for a
factory server object which manufactures new client connections. The
client end of the channel is passed to the VMM package so that
*vmm.vm_start* can create new console connections for the VMs.

The ned script starts *cons* followed by starting the VMs.

Using *cons*
------------

When you now start this scenario, note how the log output from the VMs
is tagged by the VM name:

::

   [somedir/build-aarch64] $ make E=uvmm-2vm qemu
   ...
   vm1     | VMM[vmbus]: 'vbus' capability not found. Hardware access not possible for VM.
   vm2     | VMM[vmbus]: 'vbus' capability not found. Hardware access not possible for VM.
   vm2     | VMM[main]: Hello out there.
   vm1     | VMM[main]: Hello out there.
   vm1     | VMM[]: Cleaning caches for device tree [91ff000-91ff819] ([4a7ff000])
   vm2     | VMM[]: Cleaning caches for device tree [91ff000-91ff819] ([527ff000])
   vm2     | VMM[]: Starting Cpu0 @ 0x4a880000 in 64Bit mode (handler @ 10352b0, stack: 8000f9d0, task: 41d000, mpidr: 80000000 (orig: 80000000)
   vm1     | VMM[]: Starting Cpu0 @ 0x42880000 in 64Bit mode (handler @ 10352b0, stack: 8000f9d0, task: 41d000, mpidr: 80000000 (orig: 80000000)
   ...

You’ll also find your input and output redirected to the *cons*\ ’ own
control interface. This is good. It means you can interact with the
multiplexer and switch between the attached consoles and the control
interface. Just hit Enter and type ‘help’:

::

   cons> help
               cat - Dump buffer of channel
             clear - Clear screen
           connect - Connect to channel
              drop - Drop kept client
              grep - Search for text
              help - Help screen
              hide - Hide channel output
           hideall - Hide all channels output
              info - Info screen
              keep - Keep client from garbage collection
               key - Set key shortcut for channel
              list - List channels
              show - Show channel output
           showall - Show all channels output
              tail - Show last lines of output
         timestamp - Prefix log with timestamp

   Key shortcuts when connected:
      Ctrl-E .     - Disconnect
      Ctrl-E e     - Inject Ctrl-E
      Ctrl-E c     - Inject Ctrl-C
      Ctrl-E z     - Inject Ctrl-Z
      Ctrl-E q     - Inject ESC
      Ctrl-E l     - Inject Break sequence

   Global key shortcuts:
      Ctrl-E h     - Hide all output (except current)
      Ctrl-E s     - Show all output

   User defined key shortcuts:
      Ctrl-E 2     - Connect to console 'vm2'
      Ctrl-E 1     - Connect to console 'vm1'

The *Ctrl-E 1* and *Ctrl-E 2* shortcuts for switching between the guest
consoles are particularly useful. By switching we mean that your input
and output will become redirected directly to the guest and the
multiplexer interface will become inactive. Pressing *Ctrl-E .* will
reactivate it again.

Internetworking the guests
--------------------------

The next step after having two isolated VMs configured is
interconnecting them in a network. For this purpose, we will use a
component called *virtio-net* with its binary *l4vio_net_p2p*. You can
picture this component as a virtual network switch with two ports or
rather a virtual network cable. As usual, you need to define a new entry
in your *somedir/l4/conf/modules.list*:

::

   entry uvmm-2vm-net
   kernel fiasco -serial_esc
   roottask moe rom/uvmm-2vm-net.ned
   module uvmm
   module l4re
   module ned
   module virt-arm_virt-64.dtb
   module ramdisk-armv8-64.cpio.gz
   module[shell] echo $SRC_BASE_ABS/pkg/uvmm/configs/vmm.lua
   module uvmm-2vm-net.ned
   module[uncompress] Image.gz
   module cons
   module l4vio_net_p2p

The next part is the ned script. We need to make a few modifications to
it and save them to *somedir/conf/uvmm-2vm-net.ned*:

.. code:: lua

   package.path = "rom/?.lua";

   local L4 = require "L4";
   local vmm = require "vmm";

   vmm.loader.log_fab = L4.default_loader:new_channel();

   local function vm(id, net, args)
     vmm.start_vm({
       id = id,
       mem = 128,
       rd = "rom/ramdisk-armv8-64.cpio.gz",
       fdt = "rom/virt-arm_virt-64.dtb",
       kernel = "rom/Image.gz",
       net = net,
       bootargs = "console=ttyAMA0 earlyprintk=1 rdinit=/init " .. (args or ""),
       ext_args = { "-i" }
     });
   end

   L4.default_loader:start(
     {
       log = L4.Env.log,
       caps = { cons = vmm.loader.log_fab:svr() }
     }, "rom/cons -a");

   local net_ports = {
     net0 = 1,
     net1 = 1,
   }

   vmm.start_virtio_switch(net_ports);

   vm(1, net_ports.net0, "ip=192.168.1.1:::255.255.255.0:server:eth0");
   vm(2, net_ports.net1, "ip=192.168.1.2:::255.255.255.0:server:eth0");

We added two extra arguments to our wrapper function: *net* and *args*.

*net* is a client virtio-net capability created in
*vmm.start_virtio_switch*. Based on this capability and information
found in the device tree, *uvmm* presents a virtio-net device to the
guest. Its server end is connected to *l4vio-net-p2p*.

*args* is appended to the VM’s boot command line and we use it here to
set the guests’ IP addresses. Mind the extra trailing space in the
string literal before the concatenation.

We also added a call to *vmm.start_virtio_switch*. This function starts
*l4vio_net_p2p* and creates all the virtio-net capabilities according to
a Lua table passed to it.

Finally, the ned script starts both guests by calling *vm*, this time
with the augmented arguments.

The device tree used by *uvmm* comes pre-configured with a device tree
node for one virtio-net device, so no changes are necessary in this
regard. Check out *somedir/l4/pkg/uvmm/configs/dts/vmm-devices-arm.dtsi*
for details.

Testing the setup
-----------------

Now that everything is in place, you should be able to see a couple of
things. First, the console multiplexer shall recognize three attached
clients:

::

   [somedir/build-aarch64] $ make E=uvmm-2vm-net qemu
   cons> list
              vm2 (2) [    cons] out:   54/  3234 in:    0/    0
              vm1 (1) [    cons] out:   54/  3234 in:    0/    0
           switch     [    cons] out:   25/  1859 in:    0/    0

When you switch to vm1’s console by pressing *Ctrl-E 1*, you can list
its configured network interfaces and ping vm2:

::

   / # ifconfig eth0
   eth0      Link encap:Ethernet  HWaddr A2:E1:77:F2:26:A8
             inet addr:192.168.1.1  Bcast:192.168.1.255  Mask:255.255.255.0
             UP BROADCAST RUNNING MULTICAST  MTU:1500  Metric:1
             RX packets:0 errors:0 dropped:0 overruns:0 frame:0
             TX packets:0 errors:0 dropped:0 overruns:0 carrier:0
             collisions:0 txqueuelen:1000
             RX bytes:0 (0.0 B)  TX bytes:0 (0.0 B)

   / # ping 192.168.1.2
   PING 192.168.1.2 (192.168.1.2): 56 data bytes
   64 bytes from 192.168.1.2: seq=0 ttl=64 time=77.753 ms
   64 bytes from 192.168.1.2: seq=1 ttl=64 time=8.846 ms
   ^C

Situation in vm2’s console is analogous. Press *Ctrl-E 2* to switch to
it:

::

   / # ifconfig eth0
   eth0      Link encap:Ethernet  HWaddr E2:FA:D3:5E:FB:4B
             inet addr:192.168.1.2  Bcast:192.168.1.255  Mask:255.255.255.0
             UP BROADCAST RUNNING MULTICAST  MTU:1500  Metric:1
             RX packets:13 errors:0 dropped:0 overruns:0 frame:0
             TX packets:12 errors:0 dropped:0 overruns:0 carrier:0
             collisions:0 txqueuelen:1000
             RX bytes:1050 (1.0 KiB)  TX bytes:1008 (1008.0 B)

   / # ping 192.168.1.1
   PING 192.168.1.1 (192.168.1.1): 56 data bytes
   64 bytes from 192.168.1.1: seq=0 ttl=64 time=5.245 ms
   64 bytes from 192.168.1.1: seq=1 ttl=64 time=9.687 ms
   ^C

Conclusion
----------

This tutorial taught you to configure *uvmm* for networked scenarios
involving 2 Linux VMs. The guests were presented with a virtual console
and network device. We didn’t attempt to pass any physical devices yet.
