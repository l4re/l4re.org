.. _use-case-uboot-vm:

U-Boot as a VM boot loader
**************************

Usually uvmm loads the guest kernel, its ramdisk and device tree directly from
boot modules. This is simple, but it means the guest's software is part of
the L4Re boot image, and updating the guest kernel means rebuilding that
image.

Alternatively, uvmm can start a boot loader, which then loads the guest
operating system from the VM's own storage, or from the network. The guest
can then update its kernel by itself, like on a physical machine, and the
L4Re image only needs to contain the boot loader. This page shows how to use
`U-Boot <https://u-boot.org>`_ in this role on arm64.

The setup, run in QEMU, looks as follows:

* QEMU emulates an SD card on an SDHCI controller. L4Re's ``emmc-drv``
  drives it, see :ref:`use-case-emmc-qemu`, and exports two of its GPT
  partitions as separate Virtio-block devices.
* The first partition, ``vm1-disk``, is the VM's disk. U-Boot finds its boot
  configuration there, as does the Linux started by it.
* The second partition, ``uboot-env``, holds U-Boot's environment. uvmm
  presents it to the VM as a CFI flash device.
* QEMU also emulates an e1000 network card, which the virtual network switch
  drives with its built-in ``ixl`` driver, see :ref:`use-case-net`. The VM
  is connected to the switch through Virtio-net. This way U-Boot can also
  boot from the network.
* The setup runs on arm64.

::

   QEMU SD card ── io ── emmc-drv ─┬─ uboot-env ── CFI flash ──┐
                                   └─ vm1-disk ─── virtio-blk ─┤
                                                               ├── uvmm: U-Boot, then Linux
   QEMU e1000 ──── io ── l4vio_switch ──────────── virtio-net ─┘


Building U-Boot
---------------

U-Boot's ``virt-arm`` target is made for running in a VM. It has no built-in
knowledge of the platform: it takes all information about memory and devices
from the device tree that uvmm passes to it, and it discovers Virtio devices
with the Virtio-MMIO and Virtio-PCI transports. It is currently available in a
`branch <https://github.com/admlck/u-boot/tree/virt-arm>`_:

.. sourcecode:: shell

   git clone -b virt-arm https://github.com/admlck/u-boot.git
   cd u-boot
   make O=../build-u-boot CROSS_COMPILE=aarch64-linux-gnu- virt-arm_arm64_defconfig
   make O=../build-u-boot CROSS_COMPILE=aarch64-linux-gnu- -j$(nproc)

The result is ``build-u-boot/u-boot.bin`` which uvmm loads it like a raw kernel
image.

The u-boot can store its environment on a virtual CFI flash provided by
uvmm, or in th FAT and ext2/4 file systems. See `Storing the environment`_.

Building L4Re
-------------

You need a standard arm64 build of L4Re and of the microkernel, as described
in :doc:`Running a Linux guest VM <../../tutorials/linuxvm>`. Additionally,
the setup uses:

* ``emmc-drv``, from the `eMMC driver <https://github.com/L4Re/emmc-driver>`_
  package,
* ``l4vio_switch`` with the ``ixl`` network drivers. Clone
  `ixl <https://github.com/L4Re/ixl>`_ to ``l4/pkg/ixl`` and enable
  ``CONFIG_VNS_IXL`` in the L4Re configuration.


The VM's device tree
--------------------

The VM uses uvmm's ``virt-arm_virt-64.dtb`` with an overlay adding the two
storage devices:

.. literalinclude:: ../../../_static/use-cases/uboot-vm/uboot-vm.dtso
   :language: dts
   :caption: uboot-vm.dtso

``virtio_blk@5000`` is a Virtio-MMIO device, which uvmm connects to the
Virtio-block device given in capability ``disk``, just like the ``net``
device of the base device tree.

``flash@1000000`` is a CFI flash of 1 MiB, emulated by uvmm. With
``l4vmm,virtiocap`` instead of ``l4vmm,dscap``, uvmm keeps the flash's
contents on a Virtio-block device, here the one in capability ``env``, and
writes changes back to it. So U-Boot's ``saveenv`` ends up on the SD card.
The flash is configured as two 16-bit chips on a 32-bit bus, because this is
what U-Boot's CFI driver detects it as.

Compile the overlay with:

.. sourcecode:: shell

   dtc -I dts -O dtb -o uboot-vm.dtbo uboot-vm.dtso


Setting up the scenario
-----------------------

The ned script starts all components and connects them:

.. literalinclude:: ../../../_static/use-cases/uboot-vm/uboot-vm.ned
   :language: lua
   :linenos:
   :caption: uboot-vm.ned

``emmc-drv`` is giving Each partition given provided by ``emmc-drv`` is a
Virtio-block device of its own, so the VM only has access to the partitions
it was given, and not to the rest of the SD card.

The config file for io creates one vBus for each driver:

.. literalinclude:: ../../../_static/use-cases/uboot-vm/vbus.io
   :language: lua
   :caption: vbus.io

A modules.list entry looks like this:

.. literalinclude:: ../../../_static/use-cases/uboot-vm/modules.list
   :caption: modules.list

Put all the files, ``u-boot.bin`` and ``uboot-vm.dtbo`` in a directory
picked up by L4Re's image generation.


Creating the disk image
-----------------------

The VM needs a Linux kernel and a ramdisk. The ready-to-use ones from
l4re.org, which the VM examples in ``l4/conf/examples`` also use, work fine:

.. sourcecode:: shell

   curl -O https://l4re.org/download/Linux-kernel/arm64/Image-6.19.8
   curl -O https://l4re.org/download/ramdisks/ramdisk-armv8-64.cpio.gz

The kernel image is gzip-compressed. U-Boot decompresses it before starting
it, using the ``kernel_comp_addr_r`` and ``kernel_comp_size`` variables the
``virt-arm`` target sets up. Compressed kernels as shipped by distributions,
such as Debian's ``vmlinuz``, work the same way. Alternatively, build your
own kernel as described in :doc:`Running a Linux guest VM
<../../tutorials/linuxvm>`.

The following script creates the SD card image:

.. literalinclude:: ../../../_static/use-cases/uboot-vm/mkdisk.sh
   :language: shell
   :linenos:
   :caption: mkdisk.sh

The file system is ext4 by default, created without metadata checksums,
because U-Boot can only read, but not write, ext4 file systems with
checksums. This matters if U-Boot stores its environment in a file, see
below. ``FS=vfat`` creates a FAT file system instead.

Note that the ``vm1-disk`` partition contains a partition table itself. As
``emmc-drv`` exports a partition as a whole device, the VM sees
``vm1-disk`` as its complete disk, and it expects a partition table there,
like on any other disk. U-Boot's standard boot does not search disks without
a partition table, and Linux finds its file systems as ``/dev/vda1`` and so
on.

The file system holds the kernel, the ramdisk and an ``extlinux.conf``,
which is the boot configuration U-Boot looks for. Distributions typically
provide the same layout.

.. sourcecode:: shell

   ./mkdisk.sh

This results in ``emmc.img``. Use ``KERNEL=`` and ``RAMDISK=`` to pass other
files.


Run it with QEMU
----------------

.. sourcecode:: shell

   mkdir -p tftp
   make qemu E=uboot-vm \
        MODULES_LIST=$PWD/modules.list \
        MODULE_SEARCH_PATH=$PWD:$PWD/fiasco/build \
        QEMU_OPTIONS="-M virt,virtualization=true,gic-version=3 -cpu max -m 1g \
                      -serial stdio -display none -monitor none \
                      -drive id=sd_disk,file=emmc.img,if=none,format=raw \
                      -device sdhci-pci -device sd-card,drive=sd_disk,spec_version=3 \
                      -netdev user,id=net0,tftp=$PWD/tftp -device e1000,netdev=net0"

The console is connected to the VM right away. U-Boot comes up, loads its
environment from the flash and boots Linux from the VM's disk:

.. sourcecode:: text

   U-Boot 2026.10-rc4

   DRAM:  256 MiB
   Core:  18 devices, 10 uclasses, devicetree: board
   Flash: 1 MiB
   Loading Environment from MTD...*** Warning - bad CRC, using default environment

   In:    serial,usbkbd
   Out:   serial,vidconsole
   Err:   serial,vidconsole
   Net:   eth0: virtio-net#1
   ...
   Scanning bootdev 'virtio-blk#0.bootdev':
     1  extlinux     ready   virtio       1  virtio-blk#0.bootdev.part /boot/extlinux/extlinux.conf
   ** Booting bootflow 'virtio-blk#0.bootdev.part_1' with extlinux
   1:	linux
   Retrieving file: /boot/Image
   Retrieving file: /boot/ramdisk.cpio.gz
   append: console=ttyAMA0
      Uncompressing Kernel Image
   ...
   Starting kernel ...

   [    0.000000] Booting Linux on physical CPU 0x0000000000 [0x000f0510]
   [    0.000000] Machine model: L4 VM

The *bad CRC* warning is expected on the first boot, as the flash is still
empty.


Storing the environment
-----------------------

Press a key during U-Boot's countdown to get to its prompt. Changes to the
environment are stored with ``saveenv``:

.. sourcecode:: text

   => setenv bootdelay 5
   => saveenv
   Saving Environment to MTD... Erasing MTD...Writing to MTD...done
   OK

On the next boot, U-Boot reports ``Loading Environment from MTD... OK`` and
counts down from 5.

U-Boot stores its environment in one of two places, depending on whether
the VM has a flash device.

In the flash
~~~~~~~~~~~~

This is the setup shown so far: the environment is stored on the
``uboot-env`` partition of the SD card, i.e., it survives restarts of the VM
and of the whole system. It is independent of the VM's disk, and the VM does
not even need a writable disk.

Linux sees the flash as an MTD device as well, if the kernel has
``CONFIG_MTD_PHYSMAP_OF`` and ``CONFIG_MTD_CFI_INTELEXT`` enabled, as the
kernel from l4re.org does.
``fw_printenv`` and ``fw_setenv`` from U-Boot's tools can then access the
environment from within the VM, with this ``/etc/fw_env.config``:

.. sourcecode:: text

   # device    offset  size     sector size
   /dev/mtd0   0x0     0x10000  0x10000

In a file
~~~~~~~~~

Without a flash device, U-Boot stores the environment in a file on the first
partition of the VM's disk. This needs no separate partition, and the file is
easy to get at from Linux. U-Boot checks which file system the partition has:

* On FAT, the file is ``/uboot.env``. This fits, for example, an EFI system
  partition.
* On ext4, the file is ``/boot/uboot.env``.

To set it up,

* remove ``fragment@1``, the flash, from ``uboot-vm.dtso``,
* remove the ``env`` client from ``ext_caps`` in ``uboot-vm.ned``, and
* optionally, leave out the ``uboot-env`` partition in ``mkdisk.sh``.

With ``FS=vfat ./mkdisk.sh``, U-Boot then reports:

.. sourcecode:: text

   Loading Environment from FAT...Unable to read "uboot.env" from virtio0:1...
   ...
   => saveenv
   Saving Environment to FAT... OK

and with ext4:

.. sourcecode:: text

   Loading Environment from EXT4...** File not found /boot/uboot.env **
   ...
   => saveenv
   Saving Environment to EXT4... update journal finished

An ext4 file system must not use metadata checksums, as U-Boot cannot write to
it otherwise. It refuses with ``Unsupported features found 00002000, not
writing.`` or ``Unsupported RO compat features found 00000400``. Create the
file system with ``mkfs.ext4 -O ^metadata_csum,^metadata_csum_seed``, as
``mkdisk.sh`` does, or convert an existing, unmounted one with ``tune2fs -O
^metadata_csum``.

Within the VM, ``fw_printenv`` and ``fw_setenv`` use the file with an
``/etc/fw_env.config`` like this one, for the ext4 case with the partition
mounted at ``/``:

.. sourcecode:: text

   # file             offset  size
   /boot/uboot.env    0x0     0x10000


Booting from the network
------------------------

QEMU's user networking includes a DHCP and a TFTP server. The command line
above serves the ``tftp`` directory. Put the kernel, the ramdisk and a boot
configuration there:

.. sourcecode:: shell

   mkdir -p tftp/pxelinux.cfg
   cp Image-6.19.8 tftp/Image
   cp ramdisk-armv8-64.cpio.gz tftp/ramdisk.cpio.gz
   cat > tftp/pxelinux.cfg/default <<EOF
   default linux
   label linux
     kernel Image
     initrd ramdisk.cpio.gz
     append console=ttyAMA0
   EOF

Then boot from the network at U-Boot's prompt:

.. sourcecode:: text

   => bootflow scan -lb ethernet
   ...
   Retrieving file: pxelinux.cfg/default
   ...
     0  pxe          ready   ethernet     0  virtio-net#1.bootdev.0    extlinux/extlinux.conf
   ** Booting bootflow 'virtio-net#1.bootdev.0' with pxe
   1:	linux
   Retrieving file: Image
   ...

To try the network by default, after the VM's disk, change ``boot_targets``
and save the environment:

.. sourcecode:: text

   => setenv boot_targets "virtio ethernet"
   => saveenv

Note that ``ethernet`` is needed here: the ``dhcp`` target only covers boot
methods that get all their information from DHCP, which excludes PXE.

The packets take the path from U-Boot's Virtio-net driver through the
virtual network switch and its ``ixl`` port to QEMU's e1000. Once Linux runs,
it uses the same path, for example with ``udhcpc -i eth0``.
