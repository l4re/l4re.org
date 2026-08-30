Modifying the Example Scenario
******************************

Now that we built and executed the example scenario that continuously writes
"Hello World!" to the console, we are going to adjust that scenario. The build
method you used for your first build is independent of this and the following
guide. When asked to recompile and run the scenario, just use the commands
suited for the respective build tool:

.. tab:: Bob Build Tool

   .. sourcecode:: shell

      cd $BOB_DIR
      bob dev --dev-sandbox examples-amd64/examples::hello -bj
      dev/dist/examples/hello/1/workspace/bootx64.efi.launch

   .. note::
      The ``-b`` option (``--build-only``) will skip the update of the L4Re git
      repositories. This speeds up the build.


.. tab:: GNU Make

   .. sourcecode:: shell

      cd $L4RE_OBJDIR
      make -j9
      make E=hello-cfg qemu MODULE_SEARCH_PATH=$KERNEL_OBJDIR:$L4RE_SRCDIR/conf/examples


What Runs Below Hello
=====================

When executing the example scenario ``hello-cfg``, what actually happens is the
following:

- **The L4Re Microkernel** is started and launches the two initial
  applications: one that manages memory and one that is responsible for
  providing an environment to launch the rest of the system.
- **Sigma0** manages memory. Sigma0 is started and gets the necessary memory
  information from the kernel. With this information, the application
  responsible for starting applications can be started.
- **Moe** starts user applications and provides an environment with convenient
  abstractions to them. Moe is started and provides abstractions for managing
  memory, logging and constraining scheduling parameters. It can start another
  arbitrary application that can now rely on these abstractions.
- **Ned** is comparable to the init system of a POSIX system. It can
  conveniently be configured by users through a Lua scripting interface and
  brings up the rest of the applications.

  .. tab:: Bob Build Tool

     The Lua script specifying the scenario configuration to be launched by Ned
     is stored in ``$BOB_DIR/recipes/example/hello/hello.cfg``, which initially just
     starts the ``hello`` application.

  .. tab:: GNU Make

     The Lua script specifying the scenario configuration to be launched by Ned
     is stored in ``$L4RE_SRCDIR/conf/example/hello.cfg``, which initially just
     starts the ``hello`` application.

Inspecting The Scenario
=======================

The `hello.cfg` file is a Lua script with the following content:

.. sourcecode:: lua
   :linenos:

   -- vim:ft=lua
   -- this is a configuration to start 'hello'

   local L4 = require("L4");

   L4.default_loader:start({}, "rom/hello");

The Lua functionality for configuring a scenario and interfacing with the L4
system functionality is in the ``L4`` Module, which is included in line 4.
This module holds a default application loader, that is instructed to start the
application known under the name ``rom/hello``.

.. tab:: Bob Build Tool

   There is another file that is important for this scenario to work as expected:
   ``$BOB_DIR/recipes/examples/hello/modules.list``:

   .. sourcecode:: shell
      :linenos:

      entry hello-cfg
      kernel fiasco -serial_esc
      roottask moe rom/hello.cfg
      module l4re
      module ned
      module hello.cfg
      module hello

.. tab:: GNU Make

   There is another file that is important for this scenario to work as expected:
   ``$L4RE_SRCDIR/conf/modules.list``:

   .. sourcecode:: shell
      :linenos:
      :lineno-start: 66

      entry hello-cfg
      kernel fiasco -serial_esc
      roottask moe rom/hello.cfg
      module l4re
      module ned
      module hello.cfg
      module hello

It describes the composition of a system to be booted. Every module line
specifies a binary that is to be made available inside the system in the ``rom``
namespace (comparable to a directory) which is accessible inside Ned.

The third line tells Moe which scenario to hand over to Ned to be interpreted.
Moe defaults to running the binary named ``ned`` unless otherwise instructed.


A second Hello
==============

Back to the scenario file, we can now start a second instance of the ``hello``
example application by duplicating the line that starts the first one:

.. sourcecode:: lua
   :linenos:

   -- vim:ft=lua
   -- this is a configuration to start 'hello'

   local L4 = require("L4");

   L4.default_loader:start({}, "rom/hello");
   L4.default_loader:start({}, "rom/hello");

.. hint::

   Building with GNU Make, there is no recompilation needed to run this altered
   scenario, since it is interpreted at run time.

Running this altered scenario will output double the amount of "Hello World!"
lines to the console. Though, needing to count the number of lines per second
can be a tedious task just to confirm the scenario does exactly as we want. So
let's use the empty pair of braces, we blissfully ignored until now:

.. sourcecode:: lua
   :linenos:

   -- vim:ft=lua
   -- this is a configuration to start 'hello'

   local L4 = require("L4");

   L4.default_loader:start({ log = { "hello-1", "red" } }, "rom/hello");
   L4.default_loader:start({ log = { "hello-2", "cyan" } }, "rom/hello");

With this change, we configured the console logger to use different colors for
the output of both hello applications. We also configured different prefixes.

.. note::

   The different colors and prefixes are not processed in the ``hello``
   application. Instead, the output of those applications is colored by the
   logger.


Next steps
==========
:doc:`Change hello itself <different_hello>` to take cmd line arguments
