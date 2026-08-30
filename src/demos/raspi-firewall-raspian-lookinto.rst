Looking into the Disk Image
***************************

To see and understand what is inside the Raspberry Pi demo, let us work
through the steps to look into the disk image, find the L4Re image, and look
into this one.

The steps shown here shall also be a guide for other disk images, as all
follow a similar pattern. They require a Linux system to be carried out.


First, download the image, and as it is compressed, decompress it. This
requires about 3GB of storage.


.. sourcecode:: shell

   $ cd /tmp
   $ curl https://l4re.org/download/demo/rpi4_l4re_demo-202506.img.gz | zcat > rpi4_l4re_demo-202506.img

This is a disk image, so it has partitions. Those we can show:

.. sourcecode:: shell
 
   $ fdisk -l rpi4_l4re_demo-202506.img 
   Disk rpi4_l4re_demo-202506.img: 2.74 GiB, 2943799296 bytes, 5749608 sectors
   Units: sectors of 1 * 512 = 512 bytes
   Sector size (logical/physical): 512 bytes / 512 bytes
   I/O size (minimum/optimal): 512 bytes / 512 bytes
   Disklabel type: gpt
   Disk identifier: 2CED6DAF-456E-4407-8657-CFCF68A50A2C

   Device                      Start     End Sectors   Size Type
   rpi4_l4re_demo-202506.img1     34  333165  333132 162.7M Microsoft basic data
   rpi4_l4re_demo-202506.img2 333166  375621   42456  20.7M Linux filesystem
   rpi4_l4re_demo-202506.img3 375622 5749574 5373953   2.6G Linux filesystem


So there are three partitions.

Now we want to look into those partitions and see what's there. The
partitions can be mounted on your Linux host. Thus
run as root the ``losetup`` utility to arrange the loop devices and then mount
them.

.. sourcecode:: shell

   $ losetup -fr --show -P rpi4_l4re_demo-202506.img
   /dev/loop0
   $ mkdir /tmp/p{1,2,3}
   $ mount -r /dev/loop0p1 /tmp/p1
   $ mount -r /dev/loop0p2 /tmp/p2
   $ mount -r /dev/loop0p3 /tmp/p3
   mount: /tmp/p3: wrong fs type, bad option, bad superblock on /dev/loop0p3, missing codepage or helper program, or other error.
       dmesg(1) may have more information after failed mount system call.


So as we are executing those commands we see that we can successfully mount the
first two partitions but not the third. There seems to be something else
there.

Let us first examine the partitions we could mount:

.. sourcecode:: shell

   $ ls /tmp/p1
   COPYING.linux     bcm2711-rpi-4-b.dtb  config.txt    start4cd.elf
   LICENCE.broadcom  bootstrap.raw        fixup4cd.dat  u-boot.bin
   $ ls /tmp/p2
   bin  etc  lib64       mnt      proc  root  sys  usr  www
   dev  lib  lost+found  overlay  rom   sbin  tmp  var

So the first partition looks like the partition used for booting, as it
has a device tree (``bcm2711-rpi-4-b.dtb``), the file ``config.txt`` which
is the typical file configuring booting on the Raspberry Pi, and u-boot,
which is a boot loader. It also has ``bootstrap.raw`` which we are very
interested in.

The second partition very much looks like a Linux system, which is probably
run in a VM in the demo.

So we are interested in this ``bootstrap.raw`` file. Could it be the one
that is booted by the Raspberry Pi? Let's check!

If the ``bootstrap.raw`` file is an L4Re image file, the ``l4image`` tool
will recognize it.

The ``l4image`` tool is part of L4Re, and can also be downloaded `here
<https://l4re.org/download/snapshots/pre-built-images/l4image>`_. This is
for Linux/x86-64, run ``chmod +x l4image`` to make it executable.

Run this as a normal user, not as root. It is not
required to run this as root.


.. sourcecode:: shell

   $ l4image -i /tmp/p1/bootstrap.raw list
   B     bootstrap -modaddr=0x1000000
   K   0 fiasco
   S   1 sigma0
   R   2 moe
   M   3 l4re
   M   4 cons
   M   5 io
   M   6 ned
   M   7 l4vio_switch
   M   8 bcm2835-mbox
   M   9 emmc-drv
   M  10 uvmm
   M  11 ex_gpio_led
   M  12 mbox.cfg
   M  13 hw_devices-rpi4.io
   M  14 gpio_devices.io
   M  15 rpi.vbus
   M  16 openwrt-kernel.bin
   M  17 Image.gz
   M  18 vm.dtb
   M  19 start.ned


Looks good! What do we see here?

This image contains 20 modules, binaries of programs, configuration files, a
Linux kernel, a device tree blob. To look at the files, let's extract the
image. Like this:

.. sourcecode:: shell

   $ l4image -i /tmp/p1/bootstrap.raw --outputdir /tmp/image extract

Now we have all the files of the image in ``/tmp/image``.

There is one ``ned`` file, which is ``start.ned``. This is the configuration
file that describes what is started and how all the programs and VMs are
connected.



At the end, do not forget to clean up your host. Run this as root again.

.. sourcecode:: shell

   $ umount /tmp/p1
   $ umount /tmp/p2
   $ losetup -D
