Using the Build System
======================

L4Re uses `make <https://www.gnu.org/software/make>`_ for building all artifacts
of the system.

While it is always safe and valid to just issue ``make`` from the root directory
of your build tree, this takes longer than needed when everything does not
need to be built. For example, this is the case if you are working on a
specific package.

There are a couple of options to only build what is of interest.

Build specific packages only
^^^^^^^^^^^^^^^^^^^^^^^^^^^^

You can build a specific package only, including its dependencies, like
this from the root of your build tree::

    build-root-dir$ make pkg/l4re-core/moe

This builds moe including all of moe's dependencies only.

If you just want to build a package, not considering its dependencies, just do::

    build-root-dir$ make -C pkg/l4re-core/moe

In fact that works with any directory.

This is useful if you are working on a specific package and just want to
recompile this specific code.

The build system also has a shortcut for building multiple directories at
once like with make's ``-C``. For example, if you are working on a library and
need to build the library as well as the program using it, you can do::

    build-root-dir$ make S=pkg/mylib/lib/src:pkg/myprog

This will just build those two directories.

Building from the source tree
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

If you build from the source tree, you need to specify the root of the
object tree, do this with ``O=``::

   source-tree$ make O=/path/to/obj-tree

Build Anywhere
^^^^^^^^^^^^^^

The L4Re build system has Makefiles everywhere, so you can also start the build
process from everywhere. This includes both the source tree as well as the
object tree. The build system will descend to sub-directories.


Parallel Building
^^^^^^^^^^^^^^^^^

``make`` uses the ``-j`` parameter with a number indicating the parallelism it
should use. So using ``make -j8`` is a good choice if you happen to have an 8
core machine.

To avoid mixing output of different packages but still benefit from parallel
builds of individual object files of a package, parallel building can be
enabled with the ``PL=`` option. Call ``make`` without ``-j`` like this::

    $ make PL=8

Building Intermediate Files
^^^^^^^^^^^^^^^^^^^^^^^^^^^

Within the ``OBJ-*`` directories in the build tree, intermediate ``.i``
pre-processed files and ``.S`` assembly files can be generated, like this::

   pkg/l4re-core/moe/server/src/OBJ-arm64_armv8a-std-l4f$ make main.i
   pkg/l4re-core/moe/server/src/OBJ-arm64_armv8a-std-l4f$ make main.S

Inspecting Disassembly
^^^^^^^^^^^^^^^^^^^^^^

Sometimes it is useful to look at the disassembly of a program. There is a
shortcut for this::

   pkg/l4re-core/moe/server/src/OBJ-arm64_armv8a-std-l4f$ make disasm

For directories with multiple targets this will automatically disassemble the
first. Specify ``DABIN`` to choose another one in these instances. For example
to disassemble ``liblua.so`` instead of ``liblua.a`` use::

   pkg/l4re-core/lua/lib/build/OBJ-arm64_armv8a-std-l4f$ make disasm DABIN=liblua.so
