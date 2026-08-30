Buildsystem
***********

.. todo::

   - Stretch goal: Page about sandboxing
   - stretch goal: Page about network boot

You already learned how to compile L4Re and the L4Re Microkernel for your local
architecture in :doc:`/getting_started/make`. Now you might want to
:doc:`cross compile L4Re <cross_compiling>`. There are a number of supported
architectures.

L4Re by default gets built with ``gcc``. You can also :doc:`configure the build
system to use Clang <clang>` instead.

Learn how to :doc:`keep L4Re up to date <updating>` using ``ham``.

If you are having problems using the build system you can :doc:`troubleshoot
the issues <troubleshooting>` you encountered until now.

.. toctree::
   :maxdepth: 1
   :hidden:

   configuration
   cross_compiling
   clang
   updating
   using
   troubleshooting
