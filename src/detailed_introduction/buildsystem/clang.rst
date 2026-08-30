Using Clang
***********

L4Re and the L4Re Microkernel both support building with Clang.

Building L4Re with Clang
========================

Building L4Re with Clang is as easy as providing ``CLANG=1`` to the
configuration and building step:

.. sourcecode:: shell

   cd $L4RE_OBJDIR
   echo "CLANG = 1" >> Makeconf.local
   make oldconfig
   make -j9

.. note::

   ``make oldconfig`` reconfigures the build only asking for new configuration
   options that are available. That step is always required when switching or
   upgrading the used compiler.

.. hint::

   It is possible to use ``CLANG = -<version>`` for an installed Clang version
   number ``<version>``.

Ensure that the ``clang`` and ``clang++`` binaries are available in your
``$PATH``. If you install your distribution provided packages this should be
the case. If you download a binary toolchain in an archive be sure that the
directory with the compiler binaries is included in your system search path.

.. sourcecode:: shell

   export PATH=/path/to/clang/toolchain:$PATH


Cross-Compiling L4Re With Clang
-------------------------------

Clang is capable of cross compiling without installing a specific version for
the target architecture. This is why the architecture selection does not work
via a prefix but by a command line argument. The L4Re build system deduces this
command line argument from the provided ``CROSS_COMPILE`` variable. So again,
all we have to additionally provide is the extra variable ``CLANG=1``.


.. sourcecode:: shell

   cd $L4RE_OBJDIR_ARM64
   echo "CROSS_COMPILE = aarch64-linux-gnu-" >> Makeconf.local
   echo "CLANG = 1" >> Makeconf.local
   make oldconfig
   make -j9

.. note::

   Configuring L4Re for building with Clang will still use ``ld`` for linking.
   That's why you still need a gcc cross compiler installed. To link using
   ld.lld set ``LD=ld.lld`` in ``Makeconf.local`` in your build directory or
   add it to all make invocations.


Building The L4Re Microkernel With Clang
========================================

The L4Re Microkernel's build system gets the information which compiler to use
from the kconfig configuration.

.. sourcecode:: shell

   cd $KERNEL_OBJDIR
   make config
   # In "Compiling":
   #   Set "C compiler" to "clang"
   #   Set "C++ compiler" to "clang++"

   make -j9

Cross-Compiling
---------------

The ``CROSS_COMPILE`` variable still has to be provided on the command line or
in ``Makeconf.local``:

.. sourcecode:: shell

   cd $KERNEL_OBJDIR_ARM64
   echo "CROSS_COMPILE = aarch64-linux-gnu-" >> Makeconf.local

   make config
   # In "Compiling":
   #   Set "C compiler" to "clang"
   #   Set "C++ compiler" to "clang++"

   make -j9

Dedicated Toolchains
--------------------

In contrast to building L4Re, when building The L4Re Microkernel, we can just
switch out the configured values for our toolchains. The build system deduces
the cross-compilation command line parameter for Clang from the
``CROSS_COMPILE`` variable even if it is a toolchain path:

.. sourcecode:: shell

   cd $KERNEL_OBJDIR_ARM64
   echo "CROSS_COMPILE = /path/to/gcc/arm64/toolchain/bin/aarch64-linux-gnu-" >> Makeconf.local

   make config
   # In "Compiling":
   #   Set "C compiler" to "path/to/clang/toolchain/bin/clang"
   #   Set "C++ compiler" to "path/to/clang/toolchain/bin/clang++"

   make -j9
