.. _build_with_make:

Building With GNU Make
**********************

Building an L4Re system from scratch involves several Git repositories and
multiple steps, that have to be taken for setting up the build environment.
L4Re uses a GNU Make based build system to build L4Re itself and any further
applications plugged into the build system.

Once configured, you can develop directly inside the L4Re source tree and use
GNU Make to compile your changes.

Note that this guide is for Linux host systems. The L4Re build system also
works on MacOS, please refer to the :ref:`macosx` page.

Prerequisities
==============

Depending on your host system, you might need to install some prerequisities.

.. tab:: Debian 12 (Bookworm)

   Make sure you have the required packages installed together with their
   dependencies by running the following command with sufficient privileges:

   .. sourcecode:: shell

      apt-get install git make binutils liburi-perl libgit-repository-perl libxml-parser-perl gcc g++ libc6-dev-i386 libncurses-dev qemu-system xorriso mtools flex bison pkg-config gawk device-tree-compiler dialog wget doxygen graphviz qemu-system


.. tab:: Fedora

   You will need the following packages and their dependencies:

   .. sourcecode:: shell

      dnf install git make perl-CPAN perl-Git-Repository-Plugin-AUTOLOAD perl-libxml-perl flex bison gcc-x86_64-linux-gnu gcc-c++-x86_64-linux-gnu  diffutils dtc which ncurses-devel qemu dialog perl-Template-Toolkit doxygen
      cpan XML::Mini

.. tab:: Arch Linux

   The following packages need to be installed:

   .. sourcecode:: shell

      pacman -S --needed base-devel dtc lib32-gcc-libs qemu qemu-ar dialog doxygen perl-template-toolkit

   Additionally, these packages need to be installed from the AUR by a method
   of your choice:

   .. sourcecode::

      yay -S perl-git-repository perl-xml-mini perl-uri


Getting and Installing Ham
==========================

L4Re is composed of several loosely coupled Git repositories. While it is
theoretically possible to manage them individually using Git alone, it is
recommended to use `Ham <https://github.com/L4Re/ham>`_ for managing the
whole set at once.

.. sourcecode:: shell

   git clone https://github.com/L4Re/ham.git

Make sure to include the ``ham`` directory in your PATH or link the ``ham``
binary to some location in your PATH.

Getting the Sources
===================

Before initializing any projects, let's  talk about a suitable directory
structure. L4Re is independent of the L4Re Microkernel location wise, as are
the build directories for both. When starting with cross compilation, you will
find that there can be multiple build directories for the same source directory
(for both, L4Re, and the L4Re Microkernel). It is possible to place all build
directories as subdirectories into the source, but in general the location can
be chose arbitrarily.

The directory structure described in this guide is as follows:

.. sourcecode:: shell

   $HOME/l4re_projects
   ├─ .ham
   ├─ l4
   ├─ fiasco
   ├─ l4re_builds
   │  ╰─ x86_64
   ╰─ fiasco_builds
      ╰─ x86_64

.. note::

   Even though the source directories are named ``l4/`` and ``fiasco/`` for
   historic reasons we will refer to the them as "L4Re" and
   "the L4Re Microkernel" respectively for the remainder of this guide.

Firstly, we create environment variables for the mentioned directories to
simplify further steps in the instructions. They are purely a help for the
further steps in the guide and not mandated by the build system. The build
locations are also just examples. Feel free to chose your own.

.. sourcecode:: shell

   export L4RE_SRCDIR="$HOME/l4re_projects/l4"
   export L4RE_OBJDIR="$HOME/l4re_projects/l4re_builds/x86_64"

   export KERNEL_SRCDIR="$HOME/l4re_projects/fiasco"
   export KERNEL_OBJDIR="$HOME/l4re_projects/fiasco_builds/x86_64"

We are using Ham to get the L4Re project manifest and all its constituent
repositories:

.. sourcecode:: shell

   mkdir $HOME/l4re_projects
   cd $HOME/l4re_projects
   ham init -u https://github.com/L4Re/manifest.git

This initialises a Ham project without checking out any sources. The
``manifest`` repository holds all information Ham needs to set up our L4Re
source tree. For now, there is only a ``.ham/`` directory.

The next step is to check out the actual sources.

.. sourcecode:: shell

   ham sync

This fetches all repositories listed in the manifest and checks out their latest
version. This may take a while. If invoked again later this command will also
update the local checkouts in case of remote changes.

As a result two new directories, ``l4/`` and ``fiasco/`` are created. ``l4/``
holds the source tree of the L4Re Operating System Framework, while the code of
the L4Re Microkernel is stored in ``fiasco/``.

If ham sync is terminated early or fails to sync, please refer to the
:doc:`/detailed_introduction/buildsystem/troubleshooting` information.

Building L4Re
=============

We initialise the build directory by calling Make with the ``B`` variable set
to the build directory path:

.. sourcecode:: shell

   cd $L4RE_SRCDIR
   make B=$L4RE_OBJDIR

.. admonition::  If this step fails
   :class: dropdown note

   On some Linux distributions this step may fail outputting an error like

   .. sourcecode:: shell

      bash: line 1: x86_64-linux-gnu-gcc: command not found
      bash: line 1: x86_64-linux-gnu-gcc: command not found
      Program(s) "x86_64-linux-gnu-g++ x86_64-linux-gnu-gcc x86_64-linux-gnu-ld" not found, please install!

   This can be fixed by appending ``CROSS_COMPILE=<prefix>`` to the make
   invocation where the ``<prefix>`` is the prefix of the x86_64 compiler. You
   can, for example, find it by entering ``x86_64-`` in a shell and pressing
   the ``<tab>`` key twice. For example, on Gentoo this value is
   ``x86_64-pc-linux-gnu-``. You will have to specify this for all ``make``
   invocations for the remainder of this guide.

   You can add this setting also to ``$L4RE_OBJDIR/Makeconf.local`` (needs to
   be created by you) once the builddir has been created to avoid having to add
   it to all make invocations.


From now on we might call ``make`` either directly from the build directory or
from the source directory by additionally providing ``O=$L4RE_OBJDIR``.


The initialisation step has already configured our build with certain defaults.
These are what we will be using in this guide. The default architecture we will
build L4Re for is ``amd64`` / ``x86_64``.

.. note::

   If you wish to change the configuration, you can do so using

   .. sourcecode:: shell

      cd $L4RE_OBJDIR
      make config

The build directory is now ready for us to build the actual L4Re binaries using

.. sourcecode:: shell

   cd $L4RE_SRCDIR
   make O=$L4RE_OBJDIR -j9

or

.. sourcecode:: shell

   cd $L4RE_OBJDIR
   make -j9


Replace the ``9`` in ``-j9`` with the number of parallel jobs you want to run
during the build process.

The release L4Re binaries reside in the ``bin/`` subdirectory of the build
directory. For the amd64 configuration, this is
``$L4RE_OBJDIR/bin/amd64_gen/l4f/``:

.. sourcecode:: shell
   :emphasize-lines: 2

   $ ls $L4RE_OBJDIR/bin/amd64_gen/l4f/hello
   $L4RE_OBJDIR/bin/amd64_gen/l4f/hello

.. _frequently-used-build-vars:

Frequently Used Build Variables
-------------------------------

We can provide a ``Makeconf.local`` file in both, our source and build
directory. This file is included and evaluated during build process.  Use Make
syntax to fill it.

At this point, it would be a reasonable choice to add ``$L4RE_OBJDIR`` as
default build directory to the ``Makeconf.local`` file in the source directory,
as we are only using this single build directory for now.

.. sourcecode:: make

   O = $(HOME)/l4re_projects/l4re_builds/x86_64

.. hint::

   There will be configuration options that can't be configured by executing
   ``make config`` but need to be provided as environment variables. Those
   should go to the ``Makeconf.local`` in the build directory.


Building the L4Re Microkernel
=============================

Building The L4Re Microkernel works like building L4Re. A major difference is
that we cannot build it from the source directory. Calling make in the source
directory is only done once for initialising the build directory.

.. sourcecode:: shell

   cd $KERNEL_SRCDIR
   make B=$KERNEL_OBJDIR

   cd $KERNEL_OBJDIR
   make -j9

The resulting microkernel binary is called ``fiasco``.

.. note::

   Again, building for ``x86_64`` is the default configuration which is
   configured during build directory initialisation. The target architecture
   and other options can be changed by calling ``make config``.


Running the Hello World! Program
================================

Now that we have sucessfully built Fiasco and L4Re, it is time to verify that
they were built correctly by running a simple demo scenario ``hello-cfg`` that
uses the sample program called ``hello``:

.. sourcecode:: shell

   cd $L4RE_OBJDIR
   make E=hello-cfg qemu MODULE_SEARCH_PATH=$KERNEL_OBJDIR:$L4RE_SRCDIR/conf/examples

This will run the scenario in QEMU without creating any bootable images. After
a short while, we should see the message "Hello World!" printed in 1-second
intervals on the virtual QEMU screen.


Frequently Used Run Variables
------------------------------

There is a similar mechanism like the ``Makeconf.local`` file for environment
variables we want to provide: ``Makeconf.boot``. This, though, has to be placed
in the ``conf`` subdirectory.

You might want to store the ``MODULE_SEARCH_PATH`` variable in there. This is
also the place to tune various QEMU and platform-specific options.

.. hint::

   There is an example file you can use:
   ``$L4RE_SRCDIR/conf/Makeconf.boot.example``
   Rename it to ``$L4RE_SRCDIR/conf/Makeconf.boot`` and edit it to suit your
   needs.


Next Steps
==========

* Go to :doc:`multiple_hello` to learn how to adjust l4re scenarios to your
  liking.
* The GNU Make based L4Re build system can be used to highly customise your
  builds. You can get an overview of the most common usecases at :doc:`the
  detailed introduction into the build system
  </detailed_introduction/buildsystem/index>`.
* Learn how to compile and run your application with the :doc:`L4Re toolchain
  </tutorials/compiling>`.
* Discover the different :doc:`services
  </detailed_introduction/services/index>` that are offered in the L4Re
  operating system
  framework
* Have a look at the `API documentation <https://l4re.org/doc/>`_.


.. toctree::
   :hidden:

   macosx
