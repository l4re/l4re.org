L4Re services
*************

The L4Re operating system framework provides a number of services. The
following pages describe how they can be deployed and configured.

.. admonition:: Under Construction
   :class: note

   This part of the website is being worked on. Please refer to `the doxygen
   documentation <https://l4re.org/doc/l4re_servers.html>`_ for information
   about this topic.

System initialization
=====================

Depending on the target system architecture, there are two standard init
processes to start services and applications.

.. TODO - image: bootstrap -> kernel -> sigma0/moe -> ned -> ...
                                     -> tinit -> ...

ned - Versatile, Lua scripted init process
------------------------------------------

:doc:`ned` is the standard init process of L4Re. It is started by default
unless configured differently. Ned's job is to bootstrap the system running on
L4Re. The main thing to do here is to coordinate the startup of services and
applications as well as to provide the communication channels for them. The
central facility in Ned is the `Lua <https://www.lua.org/>`_ script interpreter
with the L4Re and ELF-loader bindings.

The boot process is based on the execution of one or more Lua scripts that
create communication channels (:term:`IPC gate`), instantiate other L4Re
objects, organize capabilities to these objects in sets, and start application
processes with access to those objects (or based on those objects).

tinit - Safety and resource focused
-----------------------------------

:doc:`tinit` is the init process of L4Re that brings up the system on
safety-focused and resource constrained platforms. Tinit parses and executes a
small DSL to load services and applications.


Services
========

.. toctree::
   :maxdepth: 1

   sigma0
   moe
   ned
   tinit
   cons
   io

.. toctree::
   :maxdepth: 2

   virtio-block/index

.. toctree::
   :maxdepth: 1

   virtio-net-switch
   uvmm
