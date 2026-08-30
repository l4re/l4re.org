Using the NVMe server with a Linux guest VM
===========================================

This tutorial will show you how the L4Re NVMe driver can be used to make
an NVMe namespace or a GPT partition on an NVMe namespace accessible in
the form of a VIRTIO block device to a Linux VM. We will use our
knowledge from the previous tutorials, namely the 
:doc:`linuxvm` tutorial and to a degree the :doc:`hwpassthrough`
tutorial. You are kindly reminded to get familiar with the concepts and
procedures presented in them before moving on with this one.

As the NVMe technology is bound to systems with PCIe, we will be using
the AMD64 platform (also known as x86_64), where PCIe is most common.
This means that certain steps from the above tutorials do not apply
verbatim, but need to be modified for the AMD64/x86_64 use case. In most
situations we will leave this as an exercise to the reader, but will
bring your attention to important differences in configuration.

The Big Picture
---------------

In the following we will run a simple Linux VM in *uvmm*. The Linux VM
will be provided with a VIRTIO block device by the L4Re NVMe server. The
VIRTIO device will be backed by an NVMe namespace. The VM will be able
to mount the VIRTIO block device and use it just as any other block
device. The whole scenario will run in KVM for the sake of a unified
user experience and reusability of this tutorial.

Building everything
-------------------

You first need to checkout and build the sources for the following
components as described in the :doc:`linuxvm` tutorial:

-  Fiasco
-  L4Re
-  Linux
-  Busybox

Without going into details described in the previous tutorials, the
building is done like this:

::

   [somedir] $ cd fiasco
   [somedir/fiasco] $ make B=../build-fiasco-x86_64
   [somedir/fiasco] $ cd ../build-fiasco-x86_64
   [somedir/build-fiasco-x86_64] $ make config  # save defaults for x86_64
   [somedir/build-fiasco-x86_64] $ make -j 6
   [somedir/build-fiasco-x86_64] $ cd ../l4
   [somedir/l4] $ make B=../build-x86_64
   [somedir/l4] $ cd ../build-x86_64
   [somedir/build-x86_64] $ make config  # save default for x86_64
   [somedir/build-x86_64] $ make -j 6
   [somedir/build-x86_64] $ cd ../linux
   [somedir/linux] $ mkdir ../build-linux-x86_64
   [somedir/linux] $ make O=../build-linux-x86_64 defconfig
   [somedir/linux] $ make O=../build-linux-x86_64 -j 6
   [somedir/linux] $ cd ../busybox
   [somedir/busybox] $ mkdir ../build-busybox-x86_64
   [somedir/busybox] $ make O=../build-busybox-x86_64 defconfig
   [somedir/busybox] $ make O=../build-busybox-x86_64 menuconfig  # select Build static binary (no shared libs)
   [somedir/busybox] $ cd ../build-busybox-x86_64
   [somedir/build-busybox-x86_64] $ make install -j 6

In this case we are assuming the host and target architecture is x86_64.

Preparing the root file system
------------------------------

In this step you will make changes to the installed Busybox file system
that will later allow you to see mounted file systems in the running
Linux VM and list the discovered VIRTIO block devices.

::

   [somedir/build-busybox-x86_64] $ mkdir _install/proc
   [somedir/build-busybox-x86_64] $ mkdir _install/etc
   [somedir/build-busybox-x86_64] $ cat >_install/etc/fstab <<EOF
   none /proc proc defaults 0 0
   devtmpfs   /dev   devtmpfs   mode=0755,nosuid   0   0
   EOF
   [somedir/build-busybox-x86_64] $ mkdir ../ramdisk
   [somedir/build-busybox-x86_64] $ cd _install
   [somedir/build-busybox-x86_64/_install] $ find . | cpio -H newc -o | gzip > ../../ramdisk/ramdisk-x86_64.cpio.gz
   [somedir/build-busybox-x86_64/_install] $ cd ../..

Creating an empty VIRTIO block image
------------------------------------

Create an empty 10MB file to hold an NVMe namespace image for QEMU:

::

   [somedir] $ mkdir images
   [somedir] $ dd if=/dev/zero of=images/disk.img bs=1M count=10

You can tweak the count argument to change the size of the image in MB
according to your liking.

Configuring L4Re
----------------

Now is time to create the configuration files for your scenario. First
of all, create a directory that will contain all configuration:

::

   [somedir] $ mkdir conf

We will now proceed to create two configuration files in this directory:

-  Vbus configuration file for passing the NVMe hardware to the NVMe
   server
-  ned script to start the scenario

Vbus configuration file
~~~~~~~~~~~~~~~~~~~~~~~

Create *somedir/conf/nvme.vbus* like this:

.. code:: lua

   Io.add_vbusses
   {
     nvme = Io.Vi.System_bus(function ()
       Property.num_msis = 2;
       PCI0 = Io.Vi.PCI_bus(function ()
         pci_hd = wrap(Io.system_bus():match("PCI/storage"));
       end);
     end);
   };

When processed by *io*, this configuration will create a vbus capability
called *nvme* and, for the sake of simplification, via this capability
make accessible all PCI storage devices found on the host system. Note
that this assignment is a little bit too generous (it would match all
non-NVMe storage devices too), but for your scenario it will do with a
remark that it is possible to match the real hardware exactly.

In addition, this configuration specifies that the *nvme* vbus will
support up to 2 MSI interrupts. One is for the NVMe admin queues and one
is for the I/O queue pair of each active NVMe namespace. In general you
want to have this limit large enough to accommodate all your NVMe
namespaces with connected clients and the admin queues. If MSI
interrupts are not configured or are not available, the NVMe server will
fall back to using legacy interrupts.

Writing the ned script
~~~~~~~~~~~~~~~~~~~~~~

Create *somedir/conf/uvmm-nvme.ned* as follows:

.. code:: lua

   package.path = "rom/?.lua";

   local L4 = require "L4";
   local vmm = require "vmm";
   local l = L4.default_loader;
   local nvmecl = l:new_channel();

   local io_busses = {
     nvme = 1,
   }

   vmm.start_io(io_busses, "rom/nvme.vbus -v");

   l:start(
     {
       caps =
         {
           vbus = io_busses.nvme,
           cl1 = nvmecl:svr()
         },
       log      = { "nvme", "g" },
     },
     "rom/nvme-drv"
     .. " -v"
     .. " --client cl1"
     .. " --device MYNVMECTLSN:n1"
     .. " --ds-max 5"
   );

   vmm.start_vm({
     id = 1,
     mem = 128,
     mon = false,
     rd = "rom/ramdisk-x86_64.cpio.gz",
     fdt = "rom/virt-pc.dtb",
     bootargs = "console=ttyS0 earlyprintk=1 rdinit=/bin/sh",
     kernel = "rom/bzImage",
     log = L4.Env.log,
     ext_caps =
       {
         qdrv = nvmecl,
       },

   });

The above ned script first starts *io* via the *vmm* convenience wrapper
and passes it the vbus configuration file *nvme.vbus*. This instructs
*io* to create a vbus called *nvme* according to the configuration file.

It then starts the NVMe server, which goes by name *nvme-drv*. Its
*vbus* capability is the client capability for the *nvme* vbus as
created by *io*. *cl1* is a server capability for the NVMe server’s
client that will be eventually handed over to *uvmm* for use by the
Linux VM. The client is assigned a VIRTIO block device identified by the
controller’s serial number (in our case this is *MYNVMECTLSN*) and the
number of the NVMe namespace, in this case namespace 1. If you run this
tutorial on bare metal, make sure to change the serial number to match
your hardware. Note that the *device* command line argument can instead
identify a GPT partition by its GUID or label. In that case the client
will be able to access only that particular partition.

Finally, *uvmm* is started using the *vmm* convenience wrapper. In
contrast to the previous tutorials (which were for the aarch64
architecture), the arguments are tailored for running on x86_64. This
shows in the used device tree (*virt-pc.dtb*) and the Linux image name
(*bzImage*). Also note that the *-i* command line argument is not used
here.

The *virt-pc.dtb* device tree contains a node that allows a VIRTIO block
device to be assigned to the VM when a capability named *qdrv* is
defined. We define it using the *nvmecl* capability, which is the client
capability for the NVMe server client.

Specifying boot modules
~~~~~~~~~~~~~~~~~~~~~~~

Add an entry to *somedir/l4/conf/modules.list* with the following
content in order to inform the build system and the boot loader of all
the files that form your scenario.

::

   entry uvmm-nvme
   kernel fiasco -serial_esc
   roottask moe rom/uvmm-nvme.ned
   module uvmm
   module io
   module nvme-drv
   module nvme.vbus
   module l4re
   module ned
   module virt-pc.dtb
   module ramdisk-x86_64.cpio.gz
   module[shell] echo $SRC_BASE_ABS/pkg/uvmm/configs/vmm.lua
   module uvmm-nvme.ned
   module[uncompress] bzImage

Mind the device tree and Linux boot image names specific to x86_64.

Creating Makeconf.boot
~~~~~~~~~~~~~~~~~~~~~~

You’ll now need to configure the build system.

Go to *somedir/l4/conf* and copy *Makeconf.boot.example* to
*Makeconf.boot* (assuming it does not exist yet). Then edit
*Makeconf.boot* and make sure that:

-  somedir/build-fiasco-x86_64
-  somedir/ramdisk
-  somedir/conf
-  somedir/build-linux-x86_64/arch/x86/boot/

are all included in the definition of *MODULE_SEARCH_PATH*. The
individual paths need to be absolute and separated by colons. An example
definition of *MODULE_SEARCH_PATH* might look as follows. Just make sure
to change *SOMEDIR* according to your environment:

::

   SOMEDIR = /absolute/path/to/your/somedir
   MODULE_SEARCH_PATH = $(SOMEDIR)/build-fiasco-x86_64:$\
                        $(SOMEDIR)/ramdisk:$(SOMEDIR)/conf:$(SOMEDIR)/build-linux-x86_64/arch/x86/boot

At the same time, make sure that *QEMU_OPTIONS* for amd64 are defined in
the following fashion:

::

   QEMU_OPTIONS-amd64 = -cpu host -enable-kvm -m 512 -display none
   QEMU_OPTIONS-amd64 += -drive if=none,file=$(SOMEDIR)/images/disk.img,format=raw,id=D1 \
                         -device nvme,drive=D1,serial=MYNVMECTLSN

Running the scenario
~~~~~~~~~~~~~~~~~~~~

If the above steps were made correctly, you should be able to start the
scenario like this:

::

   [somedir] $ cd build-x86_64
   [somedir/build-x86_64] $ make E=uvmm-nvme qemu

After a short while the Linux VM will have booted into its interactive
shell.

Let us first explore the output produced by the NVMe server though. It
will be interleaved with output from other components, but when
collected it should look like this:

::

   nvme    | NVMe[]: NVMe driver says hello.
   nvme    | NVMe[]: Starting device discovery.
   nvme    | NVMe[]: ICU info: features=80000000 #Irqs=24, #MSIs=2
   nvme    | NVMe[]: MSI info: vector=0x80000000 addr=fee00000, data=4022
   nvme    | NVMe[]: Device: interrupt : 80000000 trigger: 1, polarity: 0
   nvme    | NVMe[]: All devices scanned.
   nvme    | Serial Number: MYNVMECTLSN
   nvme    | Model Number: QEMU NVMe Ctrl
   nvme    | Firmware Revision: 1.0
   nvme    | Controller ID: 0
   nvme    | SGL Support: yes
   nvme    | Number of Namespaces: 256
   nvme    | NVMe[]: MSI info: vector=0x80000001 addr=fee00000, data=4023
   nvme    | Making NSID 1 visible to clients
   nvme    | libblock[]: No GUID partition header found.
   nvme    | NVMe[]: Capability 'svr' not found. No dynamic clients accepted.
   nvme    | Registering dataspace from 0x0 with 131072 KiB, offset 0x0
   nvme    | PORT[0x23090]: DMA guest [0-7ffffff]  local [1200000-91fffff]  offset 0
   nvme    | register client: host IRQ: 42a
   nvme    | Resetting device
   nvme    | shm=[0-7ffffff] local=[1200000-91fffff] desc=[1f20000-1f21000] (0x3120000-0x3121000)
   nvme    | shm=[0-7ffffff] local=[1200000-91fffff] avail=[1f21000-1f21206] (0x3121000-0x3121206)
   nvme    | shm=[0-7ffffff] local=[1200000-91fffff] used=[1f21240-1f21a46] (0x3121240-0x3121a46)
   nvme    | VQ[0x230f0]: num=256 d:0x3120000 a:0x3121000 u:0x3121240

This suggests the NVMe server discovered the NVMe controller emulated by
QEMU. Note the serial number matches the one passed to QEMU via its
command line argument. Also note that the server is using MSI
interrupts. The controller reports 256 NVMe namespaces, but only
namespace 1 is used. It is the one which contains the disk image passed
to QEMU. The disk image we prepared has no GPT partitions which is in
line with what the NVMe server reports. We see that a client registered
with the server and shared VIRTIO queue and buffer memory with it.

When we now look at the Linux VM, it will have detected the VIRTIO block
device which corresponds to namespace 1 on the NVMe controller.

::

   ~ # dmesg | grep virtio_blk
   [    0.606814] virtio_blk virtio1: 1/0/0 default/read/poll queues
   [    0.776591] virtio_blk virtio1: [vda] 20480 512-byte logical blocks (10.5 MB/10.0 MiB)

Linux will designate this VIRTIO block device as */dev/vda*:

::

   ~ # mount -a
   ~ # mount
   rootfs on / type rootfs (rw,size=45176k,nr_inodes=11294)
   none on /proc type proc (rw,relatime)
   devtmpfs on /dev type devtmpfs (rw,nosuid,relatime,size=45200k,nr_inodes=11300,mode=755)
   ~ # ls /dev/vda
   /dev/vda

You can now create a file system on this device:

::

   ~ # mkfs.ext2 /dev/vda
   Filesystem label=
   OS type: Linux
   Block size=1024 (log=0)
   Fragment size=1024 (log=0)
   2560 inodes, 10240 blocks
   512 blocks (5%) reserved for the super user
   First data block=1
   Maximum filesystem blocks=262144
   2 block groups
   8192 blocks per group, 8192 fragments per group
   1280 inodes per group
   Superblock backups stored on blocks:
       8193

And mount it:

::

   ~ # mkdir /mnt
   ~ # mount /dev/vda /mnt
   ~ # mount
   rootfs on / type rootfs (rw,size=45176k,nr_inodes=11294)
   none on /proc type proc (rw,relatime)
   devtmpfs on /dev type devtmpfs (rw,nosuid,relatime,size=45200k,nr_inodes=11300,mode=755)
   /dev/vda on /mnt type ext2 (rw,relatime)

Conclusion
----------

This tutorial has taught you to configure an L4Re scenario which allows
you to export an NVMe namespace (or partition) as a VIRTIO block device
to a Linux VM. The Linux VM sees this device as */dev/vda* and can use
it as any other block device.
