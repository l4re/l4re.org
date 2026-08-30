Raspberry Pi
************

Steps to get the Raspberry Pi running with L4Re.

Which variants of the Raspberry Pi are suitable?
================================================

* RPi 5: Great, works including virtualization, 64bit
* RPi 4: Great, works including virtualization, 64bit and 32bit
* RPi 3: Good, no virtualization support, can run L4Linux, 64bit and 32bit
* RPi 2: Good, no virtualization support, can run L4Linux, 32bit only
* RPi 1: Reasonable, no virtualization support, can run L4Linux, 32bit only

Serial
======

For up to RPi4: For interaction at low level with the RPi (aka UART), you
need a USB-TTL adapter to connect the serial port of the RPi with your
laptop/workstation. If you do not have one you can buy one (everywhere) on
the internet, search for "usb serial raspberry cable" or similar. The cable
has at least three connectors to plug into the RPi (Ground/GND, TX, RX) and
a USB connector on the other side.

For RPi5: You can use the `Raspberry Pi Debug Probe
<https://www.raspberrypi.com/products/debug-probe/>`_.

Booting
=======

For up to RPi4: For flexibility and common network-booting capabilities, we
typically use u-boot as a boot loader on the RPi. U-boot can be built from
upstream u-boot.git without any issue. Pre-built u-boot binaries for both
32bit and 64bit can be found `here <https://l4re.org/download/u-boot/>`_.
They shall work on all RPi variants up to and including RPi4.

RPi5: For flexibility and common network-booting capabilities, use the
built-in network booting capabilities. Details: to come.

Preparing an RPi for use
========================

* Copy `Raspian <https://www.raspberrypi.org/downloads/>`_ to the RPi's SD card
  as usual.
* Decide whether you want to run L4Re in 64bit (arm64) or 32bit (arm) mode. If
  the RPi supports it we recommend the 64bit variant. Otherwise the 32bit
  variant will also work fine.
* Copy the respective ``u-boot.bin`` binary to the boot partition of RPi's SD
  card. Either on the RPi directly or by putting the SD card into your
  laptop/workstation and mounting it.
* Edit 'config.txt' from the boot partition of the RPi. For running the ARM64
  version of L4Re add::

      enable_uart=1
      arm_64bit=1
      kernel=u-boot.bin

  For running the ARM32 version of L4Re add::

      enable_uart=1
      arm_64bit=0
      kernel=u-boot.bin

* Connect the serial adapter to your RPi. There are lots of information out
  there, `for example this one <https://elinux.org/RPi_Serial_Connection>`_.
* Prepare a terminal program on your laptop/workstation. We recommend minicom.
  For details refer to the URL in the previous step.
* Now restarting the RPi with the SD card inserted should put you into an
  u-boot prompt visible in the terminal program on your laptop/workstation::

      U-Boot 2020.07-rc3-00089-g9452b7496f (Jun 01 2020 - 23:05:50 +0200)
      
      DRAM: 948 MiB
      RPI 4 Model B (0xa03111)
      MMC: emmc2@7e340000: 0, mmcnr@7e300000: 1
      Loading Environment from FAT... OK
      In: serial
      Out: serial
      Err: serial
      Net:
      eth0: genet@7d580000
      U-Boot> _


Building L4Re for the RPi4
==========================

This gives step-by-step instructions on how to build L4Re for the RPi.

* Prepare a Linux system on a laptop or workstation. It is recommended to
  use a rather powerful laptop/workstation to build (and possibly)
  edit/program the system instead of doing this directly on the RPi.
  However, this is possible, just not recommended for continuous use. As a
  Linux system we recommend a recent version of Ubuntu or Debian. 
* Install at least the following additional packages::

      apt install build-essential u-boot-tools

* Install a suitable cross-compiler. Packages are typically named
  ``gcc-aarch64-linux-gnu`` (64bit) and ``gcc-arm-linux-gnueabihf`` (32bit).

* `Download <https://l4re.org/download/snapshots/>`_ a recent snapshot and
  unpack it in a location of your choice.

* Configure by calling::

      make setup

  and select ARM64 or ARM, and then the RPi4. Then leave the dialog. 

* Build it by calling::

      make

  Please use ``make -j8`` or similar to speed up building.

* Build the images::

      make build_images

* If all went well multiple so-called images have been built for the
  RPi4 platform. An image contains everything to run for a particular setup.
  Images are located in ``obj/l4/arm64/images/l4re_*_rpi*.elf``.

 
Using ready-to-use images
=========================

Pre-built images for the RPi3, RPi4 and RPi5 are available for download:
`64bit <https://l4re.org/download/snapshots/pre-built-images/arm64/>`_ and
`32bit <https://l4re.org/download/snapshots/pre-built-images/arm-v7/>`_.


Running an image stored on the SD-card of the RPi with u-boot
=============================================================

* Copy one or multiple of the Images to the boot partition of the RPi.

* Restart the RPi with the SD card inserted.

* For up to RPi4: At the u-boot prompt load the image into memory::

        U-Boot> fatload mmc 0 0x0c000000 bootstrap.elf
        1462552 bytes read in 116 ms (12 MiB/s)
        U-Boot>

  and start it::

        U-Boot> bootelf 0x0c000000 

* RPi5: At the u-boot prompt load the image into memory as well as the
  device tree into memory, then start it with ``booti``::

        U-Boot> fatload mmc 0 ${fdt_addr_r} bcm2712-rpi-5-b.dtb
        U-Boot> fatload mmc 0 0x1000000 bootstrap.raw
        U-Boot> booti 0x1000000 - ${fdt_addr_r}


Running an image stored on the SD-card of the RPi directly
==========================================================

* Copy a ``bootstrap.raw`` to the boot partition of the RPi.
* Edit config.txt and replace the ``kernel=`` line with ``kernel=bootstrap.raw``
* Reboot the RPi

Additional Information
======================

Instead of ELF files you can also use uimage files.

Booting over network
====================

Booting via network means that you generate your bootstrap image on some other system, e.g. your development system, and load it via network onto the RPi and start it. This avoids juggling SD-cards between the RPi and your development system, and is the generally preferred way of development.

Besides connecting your RPi to your network via the integrated Ethernet port, you need a TFTP-Server in your network that serves the bootstrap image to the RPi. tftp-hpa and dnsmasq are good and established choices. Please refer to their documentation or generally to the Internet to set one of those up. If in doubt, use dnsmasq.

Network booting is different between RPi versions.

Network booting up to RPi 4
---------------------------

With the RPi up to version 4, we use u-boot for network booting.

Generally it is only needed to have TFTP working, DHCP is optional, as IP addresses can be set within u-boot, but it is recommended to have it. dnsmasq offers both TFTP and DHCP services.

If you do not have an ethernet-based network (you only use WIFI or are not allowed to connect unauthorized devices to the network you're using) you can also directly connect the RPi to your notebook / workstation using an Ethernet cable. Use an USB-Ethernet dongle if you need to.

With using DHCP, the RPi should get an IP address::

        U-Boot> dhcp

Setting or adapting IP addresses works like this::

        U-Boot> setenv ipaddr 192.168.1.2
        U-Boot> setenv serverip 192.168.1.3
        U-Boot> setenv netmask 255.255.255.0

where ``ipaddr`` is the IP address of the RPi and ``serverip`` is the IP
address of the system where the TFTP server is running.

Loading the image works similarly to loading it from the SD-card::

         U-Boot> tftpboot 0x0c000000 /path/on/the/tftp/server/bootstrap.elf; bootelf

Network booting with RPi 5
--------------------------

With the RPi5 the peripheral structure of the hardware changed, such that
network functionality in u-boot is not available. However, the Raspberry
firmware can boot via TFTP itself.

Steps to set up network booting are:

* Setup a DHCP and TFTP server as described above.
* Use the Ethernet port.
* Put the contents of the firmware directory from the SD-Card (typically in ``/boot`` or ``/boot/firmware``) on the TFTP server. ``config.txt`` needs to contain the ``kernel=`` line pointing to the file to be booted from the same TFTP server directory.
* Boot the RPi5 without an SD-Card (which then should boot via TFTP if no other boot option was found).
* Watch the output on the serial with the detailed output of the firmware.

More details:

* Change the TFTP path to be used with ``rpi-eeprom-config --edit`` from
  within the Linux system running on the RPi.
* Modify the boot order if needed via ``raspi-config`` or
  ``rpi-eeprom-config`` (more fine granular).
