Running a Linux guest VM
========================

This tutorial will teach you to run a VM with an unmodified version of
Linux as a guest on L4Re. L4Re can act in the hypervisor capacity on
several platforms. In this tutorial we will use the Arch64 architecture with
QEMU.

Terminology
-----------

In some parts of this text we are using the term *aarch64* to refer to
the 64-bit ARM architecture, while in some other parts we use *arm64* or
even *ARMv8* to refer to the same. This may seem somewhat arbitrary and
confusing at the same time, but is to a large degree dictated by the
conventions of the components at hand. QEMU and toolchain-related uses
typically require *aarch64* while L4Re typically refers to *arm64*. The
bottom line is that these terms are largely interchangeable and should
not confuse you.

Prerequisites
--------------

You will need several ingredients:

-  aarch64 toolchain
-  L4Re sources
-  Linux kernel sources
-  Linux aarch64 ramdisk
-  QEMU for aarch64 targets

aarch64 toolchain
~~~~~~~~~~~~~~~~~

As you will be building for aarch64, you are going to need the aarch64
build tools for both gcc and g++. The easiest option is to install the
tool-chain from your Linux distribution. On Debian/Ubuntu-based
distributions they are called

g++-aarch64-linux-gnu

On the shell, output should be like this:

::

   [somedir] $ aarch64-linux-gnu-gcc --version 
   aarch64-linux-gnu-gcc (Debian 13.2.0-12) 13.2.0
   Copyright (C) 2023 Free Software Foundation, Inc.
   This is free software; see the source for copying conditions.  There is NO
   warranty; not even for MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

If your output looks very different (i.e. you get an error instead),
then there is likely something wrong with your setup.

Preparing L4Re sources
~~~~~~~~~~~~~~~~~~~~~~

The following assumes you are familiar with the procedures of building L4Re
and that you have successfully used *ham* to check out L4Re sources into a
top-level directory consistently called *somedir* throughout this text (but
you can use a different name).

Start by making sure you have the latest sources:

::

   [somedir] $ ham sync

You should end up with a source tree that contains at least the
following components:

::

   fiasco
   l4/pkg
   ├── bootstrap
   ├── drivers-frst
   ├── l4re-core
   ├── l4virtio
   ├── libfdt
   ├── libvcpu
   └── uvmm

Continue by configuring the L4Re Microkernel (aka Fiasco):

::

   [somedir] $ cd fiasco
   [somedir/fiasco] $ make B=../build-fiasco-aarch64
   [somedir/fiasco] $ cd ../build-fiasco-aarch64
   [somedir/build-fiasco-aarch64] $ make config

In *Target configuration*, make sure to select:

-  Architecture: ARM processor family
-  Platform: QEMU ARM Virtual Platform
-  CPU: ARM Cortex-A57 CPU
-  Virtualization: enable

Save the configuration and build the microkernel:

::

   [somedir/build-fiasco-aarch64] $ make -j 6

Once the microkernel is built, move on to configuring L4Re:

::

   [somedir/build-fiasco-aarch64] $ cd ../l4
   [somedir/l4] $ make B=../build-aarch64
   [somedir/l4] $ cd ../build-aarch64
   [somedir/build-aarch64] $ make config

Make sure to select:

-  Target Architecture: ARM64 Architecture (AArch64)
-  CPU Variant: ARMv8-A Type CPU
-  Platform Selection: QEMU ARM Virtual Platform

Once configured, build L4Re like this:

::

   [somedir/build-aarch64] $ make -j 6
   [somedir/build-aarch64] $ cd ..

Finishing this step will give you the microkernel binary, the L4Re
binaries and the device tree binary. You will need all of those later.

Preparing Linux sources
~~~~~~~~~~~~~~~~~~~~~~~

In the following we use Linux 6.10, but any reasonably new version of
Linux will do.

Create a build directory for an out-of-tree Linux build:

::

   [somedir] $ mkdir build-linux-aarch64

Alternatively, download Linux 6.10 tarball and work with that instead:

::

   [somedir] $ curl https://cdn.kernel.org/pub/linux/kernel/v6.x/linux-6.10.tar.xz | tar xvfJ -
   [somedir] $ ln -s linux-6.10 linux
   [somedir] $ cd linux

Now it’s time to configure and build Linux. Default configuration should
be fine:

::

   [somedir/linux] $ make O=../build-linux-aarch64 ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- defconfig
   [somedir/linux] $ make O=../build-linux-aarch64 ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- -j 6
   [somedir/linux] $ cd ..

This should produce a compressed kernel image in
*somedir/build-linux-aarch64/arch/arm64/boot/Image.gz*. You will need
that later.

Getting a Linux ramdisk
~~~~~~~~~~~~~~~~~~~~~~~

Besides the Linux kernel itself, you are also going to need an initial
ramdisk with some programs on it. You have basically two options: either
build your own ramdisk from scratch or use a ramdisk that someone else
made for you. l4re.org has some ready-to-use ramdisks for you. If you’re
looking for some more options or different ones, please follow one
of the tutorials found on the Internet. The example below uses the one
from l4re.org.

Putting it all together
-----------------------

Unlike the simple *hello* example that is used as the most simple example,
running a VM with a Linux guest is a little bit more involved and requires a
little bit of configuration.

Now that all the prerequisites were installed, built or downloaded, you
are ready to put everything together. First of all, you need to create a
directory for configuration files:

::

   [somedir] $ mkdir conf
   [somedir] $ cd conf

A ned script
~~~~~~~~~~~~

In L4Re, components of the resulting system are described and connected
together in a so-called ned script. The name is derived from *ned*,
which is an init process component that spawns other components and
interconnects them via IPC channels (i.e. IPC gate capabilities)
according to a Lua configuration file passed to it as an argument.

For our little scenario there is already a demo ned script, called
`VM-Basic <https://github.com/L4Re/mk/blob/master/conf/examples/vm-basic.cfg>`__.

This ned script is as basic as it gets. It only supports a single VM and
does not pass any host I/O devices to the VM, but already contains
everything necessary for doing just that without additional bells and
whistles. More complex scenarios (e.g. involving multiple VMs) will
require a more complex ned script and possibly also additional L4Re
components (see
`VM-Multi <https://github.com/L4Re/mk/blob/master/conf/examples/vm-multi.cfg>`__,
`VM-Multi-P2P <https://github.com/L4Re/mk/blob/master/conf/examples/vm-multi-p2p.cfg>`__,
`VM-Basic-PCI <https://github.com/L4Re/mk/blob/master/conf/examples/vm-basic-pci.cfg>`__).

There is also a convenience wrapper for launching VMs. You shall see in
a later example how to use it.

Specifying boot modules
~~~~~~~~~~~~~~~~~~~~~~~

For the above configuration, there must also be an entry in
*somedir/l4/conf/modules.list* so that *make E=vm-basic qemu* below
knows what binaries and config files to load.

You can see the file
`here <https://github.com/L4Re/mk/blob/master/conf/modules.list#L120>`__
(The exact line number in the URL might change while the file is being
modified. Check for ``entry[...] VM-basic``.

Creating Makeconf.boot
~~~~~~~~~~~~~~~~~~~~~~

In order to save yourself from typing (or copy-and-pasting) ridiculously
long command lines full of variable definitions, you need to do one last
thing before starting the VM. Go to *somedir/l4/conf* and copy
*Makeconf.boot.example* to *Makeconf.boot* (assuming it does not exist
yet). Then edit *Makeconf.boot* and make sure that:

-  somedir/build-fiasco-aarch64
-  somedir/conf

is included in the definition of *MODULE_SEARCH_PATH*.

Optionally, if you built your own ramdisk add the path from that, or
Linux kernel as above, add
``somedir/build-linux-aarch64/arch/arm64/boot/``.

The individual paths need to be absolute and separated by colons. An
example definition of *MODULE_SEARCH_PATH* might look as follows. Just
make sure to change *SOMEDIR* according to your environment:

::

   SOMEDIR = /absolute/path/to/your/somedir
   MODULE_SEARCH_PATH = $(SOMEDIR)/build-fiasco-aarch64:$(SOMEDIR)/conf:$(SOMEDIR)/build-linux-aarch64/arch/arm64/boot/

For running in QEMU, the *Makeconf.boot* derived from
*Makeconf.boot.example* already contains the proper configuration
options for QEMU. You can check the *QEMU_OPTIONS* to see yourself.

Spawning the Linux VM
~~~~~~~~~~~~~~~~~~~~~

At this point you are ready to start the basic VM scenario:

::

   [somedir/l4/conf] $ cd ../../build-aarch64
   [somedir/build-aarch64] $ make E=vm-basic qemu

This will spawn QEMU and run L4Re inside of it, including the *uvmm*
virtual machine monitor which eventually starts the Linux guest. Linux
should boot in a couple of seconds and you should be able to interact
with it over its serial console afterwards.

Supplementary: Using the vmm convenience wrapper
------------------------------------------------

Invoking *io* and *uvmm* manually like we do in the vm-basic scenario
above can quickly become tedious and impractical when more flexibility
and functionality is desired. L4Re therefore provides a convenience
wrapper to abstract away the repetitive parts. This wrapper is located
in *somedir/l4/pkg/uvmm/configs/vmm.lua*.

At the expense of hiding some interesting details under the cover, our
uvmm-basic scenario can be rewritten as follows. In *somedir/conf*
create a new ned script called *uvmm.ned*:

.. code:: lua

   package.path = "rom/?.lua";

   local L4 = require "L4";
   local vmm = require "vmm";

   vmm.start_vm({
     id = 1,
     mem = 128,
     mon = false,
     rd = "rom/ramdisk-armv8-64.cpio.gz",
     fdt = "rom/virt-arm_virt-64.dtb",
     bootargs = "console=ttyAMA0 earlyprintk=1 rdinit=/bin/sh",
     kernel = "rom/Image.gz",
     log = L4.Env.log,
     ext_args = { "-i" }
   });

You will also need to accompany it with a corresponding new entry in
*somedir/l4/conf/modules.list*:

::

   entry uvmm
   kernel fiasco -serial_esc
   roottask moe rom/uvmm.ned
   module uvmm
   module l4re
   module ned
   module virt-arm_virt-64.dtb
   module ramdisk-armv8-64.cpio.gz
   module[shell] echo $SRC_BASE_ABS/pkg/uvmm/configs/vmm.lua
   module uvmm.ned
   module[uncompress] Image.gz

You can now run this scenario:

::

   [somedir/l4/conf] $ cd ../../build-aarch64
   [somedir/build-aarch64] $ make E=uvmm qemu

As with the basic scenario, you should be able to interact with the
guest after it boots.

Conclusion
----------

In this tutorial you have learned to build, configure and run a basic
Linux VM scenario in the L4Re virtual machine monitor *uvmm*. Parts not
covered here include running multiple VMs, using a console multiplexer
and a virtual network switch. Likewise, we didn’t show how to pass a
host I/O device to the guest.
