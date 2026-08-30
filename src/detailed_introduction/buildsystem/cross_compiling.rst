Cross-Compiling
***************

In this guide, we will cross-compile L4Re and the L4Re Microkernel for
``arm64``. We assume a suitable arm64 cross compiler is installed.

.. hint::

   Your distribution most likely provides some cross-compiler packages for
   selected platforms. Debian cross-compilers (packaged in
   ``g++-arm-linux-gnueabihf``, ``g++-aarch64-linux-gnu`` and
   ``g++-riscv64-linux-gnu``) have been known to work with L4Re.

   If your distribution does not have the right tools or you don't have the
   rights to install them, it is possible to use a toolchain located at an
   arbitrary location. Just interchange all occurrences of the installed tools
   with the path to the binaries in your toolchain.

The cross-compilation of L4Re and the L4Re Microkernel is possible with the
same sources we used to get a local build. We just need different build directories:

.. sourcecode:: shell

    export L4RE_OBJDIR_ARM64=$HOME/l4re_projects/l4re_builds/arm64
    export KERNEL_OBJDIR_ARM64=$HOME/l4re_projects/fiasco_builds/arm64

Cross-Compiling L4Re
====================

We start with initialising a build directory:

.. sourcecode:: shell

    cd $L4RE_SRCDIR
    make B=$L4RE_OBJDIR_ARM64

.. note::

   Since we now added the second build directory to our sources, we either have
   to change the ``O`` variable in the ``Makeconf.local`` file that is located
   in the source tree, or we just call ``make`` in the build tree.

Configuring The Cross-Compiler
------------------------------

The L4Re build system uses the ``CROSS_COMPILE`` make variable for
cross-compilation. This variable is expected to contain the prefix of the
cross-tools we are using. We want to use tools like ``aarch64-linux-gnu-gcc``,
``aarch64-linux-gnu-g++`` and ``aarch64-linux-gnu-ld``, so the
``CROSS_COMPILE`` variable has to hold the value ``aarch64-linux-gnu-``.

.. sourcecode:: shell

    cd $L4RE_OBJDIR_ARM64
    echo "CROSS_COMPILE = aarch64-linux-gnu-" > Makeconf.local

.. note::

   We are putting the variable directly into the ``Makeconf.local`` file, so
   that we don't have to provide it via the command line. Since this value is
   specific for this particular build, we are using the ``Makeconf.local`` file
   in our build directory.

.. hint::

   If you are using a specific toolchain for cross-compilation, your
   ``Makeconf.local`` should look something like:

   .. sourcecode:: Makefile

      CROSS_COMPILE = /path/to/gcc/aarch64/toolchain/bin/aarch64-linux-gnu-

Configuring the Build
---------------------

Instead of using different sources, we have to configure the build.

.. sourcecode:: shell

    cd $L4RE_OBJDIR_ARM64
    make config    # Select ARM architecture, Cortex-A57 and QEMU virt platform

We select the Target Architecture "ARM64 Architecture (AArch64)". This
automatically chooses the CPU variant "ARMv8-A type CPU" and the Platform
Selection "QEMU ARM Virtual Platform".

Building
--------

Building L4Re is now possible by calling ``make`` inside the build directory:

.. sourcecode:: shell

    cd $L4RE_OBJDIR_ARM64
    make -j9

Cross-Compiling The L4Re Microkernel
====================================

Cross-compiling the L4Re Microkernel is analogous to cross-compiling L4Re:

.. sourcecode:: shell

    cd $KERNEL_SRCDIR
    make B=$KERNEL_OBJDIR_ARM64

    cd $KERNEL_OBJDIR_ARM64
    echo "CROSS_COMPILE = aarch64-linux-gnu-" > Makeconf.local

    make config
    # In "Target configuration":
    #   Select "ARM processor family" as Architecture
    #          "QEMU ARM Virtual Platform" as Platform
    #          "ARM Cortex-A57" CPU as CPU

    make -j9

Running Hello
=============

Now that all is cross-built, we run the ``hello-cfg`` scenario again in QEMU.
For that to work, we need to have ``qemu-system-aarch64`` installed on the
system.

To have suitable default options for running QEMU use

.. sourcecode:: shell

   cp $L4RE_SRCDIR/conf/Makeconf.boot.example $L4RE_SRCDIR/conf/Makeconf.boot

and then launch the example using

.. sourcecode:: shell

    cd $L4RE_OBJDIR_ARM64
    make E=hello-cfg qemu MODULE_SEARCH_PATH=$KERNEL_OBJDIR_ARM64:$L4RE_SRCDIR/conf/examples PLATFORM_TYPE=arm_virt

.. hint::

   ``MODULE_SEARCH_PATH`` and ``PLATFORM_TYPE`` can conveniently be specified
   in ``$L4RE_OBJDIR_ARM64/conf/Makeconf.boot``.

   You might also want to use the ``QEMU_OPTIONS`` variable to tune your QEMU
   experience. It might make sense to configure these for all build directories
   through the ``$L4RE_SRCDIR/conf/Makeconf.boot`` copied above.
