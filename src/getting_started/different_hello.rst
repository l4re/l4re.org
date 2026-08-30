Modifying the Hello Application
*******************************

After modifying the ``hello`` scenario, which starts the ``hello`` application,
we will now modify this application.

The Hello Package
=================

``hello`` is an L4Re Package. That means, it is part of the L4Re source tree
and gets built by the L4Re build system. It is located at
``$L4RE_SRCDIR/pkg/hello``.

The actual source code for the application is in ``server/src/main.c``:

.. sourcecode:: c
   :caption: pkg/hello/server/src/main.c
   :linenos:
   :lineno-start: 9

   #include <stdio.h>
   #include <unistd.h>

   int
   main(void)
   {
     for (;;)
       {
         puts("Hello World!");
         sleep(1);
       }
   }

This is trivial C code that is also not specific to L4Re, it should work on
any somehow POSIX-compliant environment. The instructions for the build
system can be found in ``server/src/Makefile``:

.. sourcecode:: Makefile
   :caption: pkg/hello/server/src/Makefile
   :linenos:

   PKGDIR           ?= ../..
   L4DIR            ?= $(PKGDIR)/../..

   TARGET           = hello
   SRC_C            = main.c

   include $(L4DIR)/mk/prog.mk

This tells the build system to build a target binary named ``hello`` from the
source file ``main.c``. The include makes sure that the output is a standalone
L4Re application.

Hello User
==========

L4Re applications can be arbitrarily expanded like any other application. In
this guide we will add a new header file, a new source file and will make use
of command line arguments. This will show you how to add new sources and header
files to be built and that command line arguments just work how you would
expect.

Let's not greet the whole world, but only a specific creature. Let's also
encapsulate this greeting functionality. Let's add a C source file named
``server/src/greeting.c`` as well as a header file
``server/include/greeting.h``:

.. sourcecode:: c
   :caption: pkg/hello/server/include/greeting.h
   :linenos:

   #pragma once

   void greet(char* name);


.. sourcecode:: c
   :caption: pkg/hello/server/src/greeting.c
   :linenos:

   #include <stdio.h>

   #include "greeting.h"

   void greet(char* name)
   {
     printf("Hello %s!\n", name);
   }

For this functionality to be used, we have to adjust the ``main.c`` file:

.. sourcecode:: c
   :caption: pkg/hello/server/src/main.c
   :linenos:
   :lineno-start: 9

   #include <unistd.h>

   #include "greeting.h"

   int
   main(int argc, char* argv[])
   {
     char* name = "";
     if (argc < 2)
       {
         name = "World";
       }
     else
       {
         name = argv[1];
       }
     for (;;)
       {
         greet(name);
         sleep(1);
       }
   }

For it to be properly built, we have to adjust the ``Makefile``. We need to add
the source file to the list of source files to compile and we have to give a
hint on where to get the included header file from:

.. sourcecode:: Makefile
   :caption: pkg/hello/server/src/Makefile
   :linenos:

   PKGDIR           ?= ../..
   L4DIR            ?= $(PKGDIR)/../..

   PRIVATE_INCDIR   += $(SRC_DIR)/../include

   TARGET           = hello
   SRC_C            = main.c greeting.c

   include $(L4DIR)/mk/prog.mk

Lastly, we have to actually use the new feature in our scenario:

.. sourcecode:: lua
   :caption: conf/example/hello.cfg
   :linenos:

   -- vim:ft=lua
   -- this is a configuration to start 'hello'

   local L4 = require("L4");

   L4.default_loader:start({ log = { "hello-1", "red" } }, "rom/hello user1");
   L4.default_loader:start({ log = { "hello-2", "cyan" } }, "rom/hello user2");

Now we can rebuild and run the scenario to see two different users be greeted
once a second.

Next Steps
==========
- Follow different :doc:`L4Re Tutorials </tutorials/index>`
- Read the :doc:`more detailed user guide </detailed_introduction/index>`
