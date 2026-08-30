Modify an existing image
########################

Files in the existing images can be replaced, by using the ``l4image`` tool.

We will show how this works by updating one of the pre-built images
running Linux with a new Linux kernel.

We will do this tutorial for Arm64 with QEMU. So we download the following
image along with the ``l4image`` tool:

.. sourcecode:: shell

   $ wget https://l4re.org/download/snapshots/pre-built-images/arm64/l4re_vm-basic_arm_virt.elf
   $ wget https://l4re.org/download/snapshots/pre-built-images/l4image
   $ chmod +x l4image


If you like to run it, just do it.
It will spin up a Linux VM, and you can type something in the Linux shell.

.. sourcecode:: shell

   $ ./l4image -i l4re_vm-basic_arm_virt.elf launch
   ...

   [    4.121751] ALSA device list:
   [    4.129502]   No soundcards found.
   [    4.144839] uart-pl011 12000.pl011_uart: no DMA platform data
   [    4.238744] Freeing unused kernel memory: 9152K
   [    4.250614] Run /init as init process

   Please press Enter to activate this console.
   ~ # 
   ~ # uname 
   Linux
   ~ # 


Updating the Linux kernel in the Image
--------------------------------------

First, we need to get and compile a new Linux kernel. You can take any new
Linux kernel, for example, go to `<https://www.kernel.org/>`_ and pick the
latest stable one.

And then build it:

.. sourcecode:: shell

   $ wget https://cdn.kernel.org/pub/linux/kernel/v6.x/linux-6.17.7.tar.xz
   $ tar xf linux-6.17.7.tar.xz
   $ cd linux-6.17.7
   $ make -j$(nproc) ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- defconfig
   $ make -j$(nproc) ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu-

Depending on your machine, compiling the Linux kernel can take a while.

When done, the built kernel should be in ``arch/arm64/boot``:

.. sourcecode:: shell

   $ ls -la arch/arm64/boot/Image
   arch/arm64/boot/Image
   $ cd ..


Now, let's put the new kernel into the image we previously downloaded.
First, let us check what is in the image, by using the ``list`` command:

.. sourcecode:: shell

   $ ./l4image -i l4re_vm-basic_arm_virt.elf  list -v
   T Num     Size Filename
   B              bootstrap -modaddr=0x01100000
   K   0   547736 fiasco fiasco -serial_esc
   S   1    27448 sigma0 sigma0
   R   2   241712 moe moe rom/vm-basic.cfg
   M   3      795 vm-basic.cfg vm-basic.cfg
   M   4   161664 l4re l4re
   M   5   593824 ned ned
   M   6  1271944 uvmm uvmm
   M   7     2288 virt.dtb virt.dtb
   M   8 13618690 linux linux
   M   9  1195372 ramdisk.cpio.gz ramdisk.cpio.gz
   M  10   346744 backtracer backtracer


``linux`` is the Linux kernel binary that we want to replace.

.. sourcecode:: shell

   $ ./l4image -i l4re_vm-basic_arm_virt.elf replace --with-name linux --name linux --file linux-6.17.7/arch/arm64/boot/Image


Now launch the image again, as we already did above:

.. sourcecode:: shell

   $ ./l4image -i l4re_vm-basic_arm_virt.elf launch
   ...
   [    1.650165] clk: Disabling unused clocks
   [    1.652439] PM: genpd: Disabling unused power domains
   [    1.873815] Freeing unused kernel memory: 3200K
   [    1.877680] Run /init as init process
      
   ~ # uname -a
   Linux (none) 6.17.7 #1 SMP PREEMPT Sun Nov  9 22:48:05 CET 2025 aarch64 GNU/Linux
   ~ # 

As we see, we updated the image with the new Linux kernel.

Not only the Linux kernel can be updated, but any file that is within the
image. ``l4image`` also has an ``edit`` command to edit text files, like
configurations, directly.

