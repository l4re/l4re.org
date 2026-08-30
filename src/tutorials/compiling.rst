Compiling Applications for L4Re
*******************************

.. admonition:: Under Construction
   :class: note

   This part of the website is being worked on. Parts in this section might be
   missing or incomplete at this moment.

There are several options to compile applications and code for L4Re.

Integration in L4Re Buildsystem
===============================

L4Re has its own, based on GNU make, build system. The build system can be
used for any applications, be it developed from scratch or being an
application ported over to L4Re.


.. todo::

   - Add more information


Cross-Toolchain
===============

The cross-toolchain is a gcc-based toolchain that compiles L4Re binaries on
a Linux host. It works as a normal cross compiler and thus allows using any
build system, such as autotools, cmake, or meson.

At time of writing, this toolchain is work in progress.

.. todo::

   - Add more information

