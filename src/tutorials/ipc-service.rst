Client/Server Communication
***************************

This section is mainly about the IPC framework that is available within the
core of L4Re. The task of the IPC framework is to provide convenient
functionality to write and use RPC-based communication, i.e. between a
client and a server.

In this terminology, a client is using a service provided by a server. Using
a service means to exchange a message with the server, i.e., a client
sending a message to the server and receiving an answer message from the
server.

The L4Re IPC framework employs C++ techniques to provide all the code for
both client-side and server-side usage. Based on interface definitions it
provides code from marshalling and unmarshalling the data to be transferred
as well as client side function stubs and server side dispatching
functionality.

The interfaces provided by a server are specified in C++ and added
annotation provided by the L4Re IPC framework.

For the purpose of describing the mechanisms we use a simple example where a
``calc`` server provides two calculation functions for clients.


The interface definition looks like this:

.. sourcecode:: c++

   struct Calc : L4::Kobject_t<Calc, L4::Kobject, 0x44>
   {
     L4_INLINE_RPC(int, sub, (l4_uint32_t a, l4_uint32_t b, l4_uint32_t *res));
     L4_INLINE_RPC(int, neg, (l4_uint32_t a, l4_uint32_t *res));
     typedef L4::Typeid::Rpcs<sub_t, neg_t> Rpcs;
   };

Here we see that the ``Calc`` interface has two functions: ``sub`` and
``neg`` that take parameters. Values are returned via ``res``. The ``int``
return values of the individual functions are used for return codes.


A client can use those interfaces like this, in a bare minimum variant:

.. sourcecode:: c++

  uint32_t result;
  server->sub(8, 5, &result);


While overall it looks natural, calling a function with some parameters, a
question remains: Where does 'server' come from?

``server`` is a capability that points to the server. The client program needs
to get this capability from the environment, i.e., it needs to be made
available through the client program startup.

In L4Re capabilities from the environment are named, and thus we can get the
capability like this:

.. sourcecode:: c++

   L4::Cap<Calc> server = L4Re::Env::env()->get_cap<Calc>("calc_server");


Here we ask the client's environment to put the capability named
``calc_server`` into the variable ``server``.

Putting this together, and adding error checking, a whole block of code
could look like this:

.. sourcecode:: c++

   L4::Cap<Calc> server = L4Re::Env::env()->get_cap<Calc>("calc_server");
   if (!server.is_valid())
     {
       printf("Could not get server capability!\n");
       return 1;
     }

   uint32_t result;
   if (server->sub(8, 5, &result))
     {
       printf("Error talking to server\n");
       return 1;
     }
   printf("Result of subtract call: %d\n", result);


Now to the server side. Let us first look at the implementation of the
function's functionality. The ``sub`` and ``neg`` calls need functions on the
server side that are called upon the client's request, that get the
parameters, and return a result. This looks like this:

.. sourcecode:: c++

   class Calculation_server : public L4::Epiface_t<Calculation_server, Calc>
   {
   public:
     int op_sub(Calc::Rights, l4_uint32_t a, l4_uint32_t b, l4_uint32_t &res)
     {
       res = a - b;
       return 0;
     }

     int op_neg(Calc::Rights, l4_uint32_t a, l4_uint32_t &res)
     {
       res = -a;
       return 0;
     }
   };

The functions are implemented in the scope of a ``Calculation_server`` class and
are prefixed with ``op_``. The class is derived from ``Calc``, which defines the
interfaces.

Next, we need to hook up the ``Calculation_server`` class into a server loop.
A server loop is the core way of working for a server. It waits for client
requests, serves them by dispatching to the class's ``op_``-functions, and
waits again. This is a server loop.

A server loop is defined and instantiated like this:

.. sourcecode:: c++

   L4Re::Util::Registry_server<> server;
   Calculation_server calc;

   // Register calculation server
   if (!server.registry()->register_obj(&calc, "calc_server").is_valid())
     {
       printf("Could not register my service, is there a 'calc_server' in the caps table?\n");
       return 1;
     }

   server.loop();

This code block instantiates a ``Calculation_server`` object and a server
object, registers the ``calc`` object with the framework and connects it to
the IPC channel named ``calc_server``.

It finally enters the server loop. Now, a client sending a request will be
dispatched to the ``Calculation_server`` object, one of the ``op_``-function will
be called and the result will be returned.
