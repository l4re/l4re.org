.. _use-case-emmc-qemu:

Using eMMC/SDHCI
****************

``emmc-drv`` is an L4Re block driver for eMMC and SDHC devices. It also
works in QEMU, which we show here how to set up.

The function of the driver is to provide access to an eMMC/SDHC device per
granularity of GPT partitions. In other words, the driver provides one
Virtio-Block device per GPT partition on the storage device.


Setup
-----

The following ned script shows the necessary steps to launch the driver and
provide a Virtio-block device to potential clients, such as a virtual machine
or an L4Re application.

.. literalinclude:: ../../../_static/use-cases/emmc-qemu/emmc-qemu.ned
   :language: lua
   :linenos:
   :caption: emmc-qemu.ned

The config file for IO looks like this. As QEMU provides the controller as a
PCIe device, no further setup is required.

.. literalinclude:: ../../../_static/use-cases/emmc-qemu/vbus.io
   :caption: vbus.io

A module.list entry looks like this:

.. literalinclude:: ../../../_static/use-cases/emmc-qemu/modules.list
   :caption: modules.list

Put all the files in a directory picked up by L4Re's image generation.

Run it with QEMU
----------------

First, we need to create a disk image to be presented to QEMU and used as a
storage for the eMMC/SDHCI:

.. sourcecode:: shell

   dd if=/dev/zero of=/tmp/emmc.img bs=1M count=16

Then we need to create GPT partitions in the file. For simplicity we just
create a single partition. We also query the partition GUID as we need it to
put in the ned script.

.. literalinclude:: ../../../_static/use-cases/emmc-qemu/gdisk.txt

The use-case can be run like this in one command for arm64. Of course,
variables can also be put into your ``Makeconf.boot`` file, shortening the
below command to just ``make qemu E=emmc-qemu``. It also works on x86-64
accordingly.

.. sourcecode:: shell

   make qemu E=emmc-qemu \
        MODULES_LIST=$PWD/modules.list \
        MODULE_SEARCH_PATH=$PWD/fiasco/build \
        QEMU_OPTIONS="-M virt -cpu cortex-a57 -serial stdio -vnc none -m 1g -drive id=sd_disk,file=/tmp/emmc.img,if=none,format=raw -device sdhci-pci,id=sdhci -device sd-card,drive=sd_disk,spec_version=3"
