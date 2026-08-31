.. _macosx:

Building L4Re on MacOS
**********************

L4Re can also be built on MacOS. The tools the L4Re build system relies on
are available via `Homebrew <https://brew.sh>`__, an open source software distribution and package
manager for MacOS.

So first, you need to install Homebrew on your Mac. Ensure that Homebrew is
hooked up into your PATH as suggested by Homebrew.

Then proceed to install the following packages needed to build L4Re:

.. sourcecode:: shell

   brew install make bash gawk aarch64-elf-binutils aarch64-elf-gcc dialog findutils coreutils u-boot-tools gnu-sed qemu dtc wget

Note that not all packages are mandatory, however, the list presents a
useful set of packages.

Ham
---

Ham is a tool that manages multiple Git repositories from a common manifest
file. Ham is used by the L4Re infrastructure. It is optional. Git
repositories can also be downloaded with Git alone given they are arranged
as required.

Ham is available from its `Git repository <https://github.com/L4Re/ham>`__.

See below for instructions how Ham can be used from its source repository on
MacOS.

Proceeding with Building L4Re
-----------------------------

Now your MacOS system should be ready to build L4Re for Aarch64/arm64
targets.
However, for doing so, use ``gmake`` instead of ``make``, and use
``CROSS_COMPILE=aarch64-elf-``.

Other targets (such as x86) are not supported because that would require a
gcc cross-compiler to be available in Homebrew. As LLVM/clang can also be
used to compile L4Re, the LLVM package from Homebrew should also work with
all the targets it has built in. This guide shall be extended with this
possibility.

You can proceed now with the normal L4Re build process, obeying the two
rules just mentioned. Please follow :ref:`build_with_make`.


For convenience, here's a quick guide for an Aarch64 build:

Building L4Re from source for Aarch64
-------------------------------------

Go to a directory of your choice, such as ``~/src/l4re``, and do:

.. sourcecode:: shell

   ham init -u https://github.com/L4Re/manifest.git
   ham sync

Set up some configuration. Can be any, given it is built for Aarch64.

.. sourcecode:: shell

   cat << _EOF > l4/defconfig
   CONFIG_BUILD_ARCH_arm64=y
   _EOF

   cat << _EOF > fiasco/defconfig
   CONFIG_ARM=y
   CONFIG_ARM_CORTEX_A57=y
   CONFIG_MP_MAX_CPUS=8
   CONFIG_ARM_SMC_USER=y
   CONFIG_ARM_PSCI=y
   CONFIG_PERFORMANCE=y
   CONFIG_PERF_CNT_USER=y
   CONFIG_EXPERT=y
   _EOF


Now build, by creating a build directory for both the L4Re user-level and
the microkernel, and building each:

.. sourcecode:: shell

   gmake -j $(nproc) -C l4 B=$PWD/l4-build CROSS_COMPILE=aarch64-elf- DEFCONFIG=defconfig
   gmake -j $(nproc) -C l4-build CROSS_COMPILE=aarch64-elf-

   cp l4/conf/Makeconf.boot.example l4/conf/Makeconf.boot

   gmake -j$(nproc) -C fiasco B=$PWD/fiasco-build-arm64 DEFCONFIG=defconfig CROSS_COMPILE=aarch64-elf-
   gmake -j$(nproc) -C fiasco-build-arm64 CROSS_COMPILE=aarch64-elf-


If that's done, you could use QEMU to run it:

.. sourcecode:: shell

   gmake -C l4-build CROSS_COMPILE=aarch64-elf- elfimage E=hello PT=arm_virt \
          MODULE_SEARCH_PATH=$PWD/fiasco-build-arm64

   l4/tool/bin/l4image -i l4-build/images/bootstrap.elf launch





Optional: Using Ham from its source repository
----------------------------------------------

In case you want to use Ham from its source repository on MacOS, some
prerequisites have to be fulfilled.

Ham is written in Perl and uses some further Perl modules, which need to be
installed: ``Git::Repository`` and ``XML::Parser``.

.. sourcecode:: shell

   cpan install Git::Repository XML::Parser

This shall work with both the Perl that comes with MacOS as well as the
(more recent) Perl from Homebrew.

Then, get the Ham tool:

.. sourcecode:: shell

   git clone https://github.com/L4Re/ham.git

Make sure to include the ``ham`` directory in your PATH or link the ``ham``
binary to some location in your PATH.

Calling ``ham`` without arguments shall present a help text.
