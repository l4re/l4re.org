cons - Console multiplexer
**************************

``cons`` is the interactive console multiplexer for the L4Re operating system.
It allows multiplexing console output and input from and to different
clients such as VMs and L4Re components and programs.

``cons`` is an interactive command line tool that works with commands and
key shortcuts::

    cons>
    cons> help
                cat - Dump buffer of channel
              clear - Clear screen
            connect - Connect to channel
               drop - Drop kept client
               grep - Search for text
               help - Help screen
               hide - Hide channel output
            hideall - Hide all channels output
               info - Info screen
               keep - Keep client from garbage collection
                key - Set key shortcut for channel
               list - List channels
               show - Show channel output
            showall - Show all channels output
               tail - Show last lines of output
          timestamp - Prefix log with timestamp

    Key shortcuts when connected:
       Ctrl-E .      - Disconnect
       Ctrl-E e      - Inject Ctrl-E
       Ctrl-E c      - Inject Ctrl-C
       Ctrl-E z      - Inject Ctrl-Z
       Ctrl-E q      - Inject ESC
       Ctrl-E l      - Inject Break sequence

    Global key shortcuts:
       Ctrl-E h      - Hide all output (except current)
       Ctrl-E s      - Show all output

    User defined key shortcuts:
       Ctrl-E 1     - Connect to console 'vm1'
    cons>

Probably the most important command is the ``connect`` command with which
you can connect to a client such as a VM::

    cons> connect vm1
    ~ #
    ~ #
    ~ # uname
    Linux
    ~ #

Leave a console with ``Ctrl-E .``.

The list command understands globbing, like this::

    cons> list vm*
               vm1 (1) [        ] out:  360/ 18828 in:    0/   21
    cons>

Shortcuts
---------

There can only be key shortcuts for accessing specific consoles. In our
example console ``vm1`` has the key shortcut ``1`` such that the console of
VM1 can be accessed quickly by typing ``Ctrl-E 1``.

The ``connect`` command has the short command ``c``.

The ``list`` command has the short command ``ls``.


Multiplexers and Frontends
==========================

``cons`` is able to connect multiple clients with multiple in/output servers.

Clients are handled by a *multiplexer*. Each multiplexer publishes a server
capability that allows creating new client connections. The default
multiplexer is normally known under the ``cons`` capability.

Actual in/output is handled by separate frontends. From the point-of-view of
cons, a frontend consists of an IPC channel to a server that speaks an
appropriate server protocol. By default the ``L4.Env.log`` capability is used.

For clients, ``cons`` implements the :l4re:`L4::Vcon` and the Virtio console interface.
The supported frontends are limited to :l4re:`L4::Vcon` only.


Command-line Options
--------------------

Please refer to `the doxygen documentation <https://l4re.org/doc/l4re_servers_cons.html>`_.
