Architecture Concepts
*********************

.. todo::

   - Stretch goal: get content from swad

After getting an abstract overview about the Architecture of the L4Re Operating
System Framework in :doc:`/overview/architecture`, you will learn more
about the architectural concepts in detail in this section.

The L4Re Microkernel
====================

The L4Re Microkernel is the lowest-level component of software running in an
L4Re-based system. The microkernel is the only component that runs in
privileged processor mode. It does not include complex services such as program
loading, device drivers, or file systems; those are implemented in user-level
programs on top of it (a basic set of these services and abstractions is
provided by the L4 Runtime Environment).

Microkernel services are implemented in kernel objects. **Tasks** hold
references to kernel objects in their respective **Object space**, which is a
kernel-protected table. These references are called **capabilities**. System
calls to the microkernel are function invocations on kernel objects through the
corresponding capabilities. These can be thought of as function invocations on
object references in an object-oriented programming environment. Furthermore,
if a task owns a capability, it may grant other tasks the same (or fewer)
rights on this object by passing the capability from its own to the other
task's object space.

From a design perspective, capabilities are a concept that enables flexibility
in the system structure. A thread that invokes an object through a capability
does not need to care about where this object is implemented. In fact, it is
possible to implement all objects either in the kernel or in a user-level
server and replace one implementation with the other transparently for clients.

Communication
-------------

The basic communication mechanism in L4-based systems is called :doc:`Inter
Process Communication (IPC) <IPC>`.  It is always synchronous, i.e. both
communication partners need to actively rendezvous for IPC. In addition to
transmitting arbitrary data between threads, IPC is also used to resolve
hardware exceptions, faults and for virtual memory management.

L4Re Runtime Environment
========================

The L4Re Runtime Environment provides a basic set of services and abstractions,
which are useful to implement and run user-level applications on top of the
L4Re Microkernel. They form the L4Re Operating System Framework.

The L4Re Operating System Framework consists of a set of libraries and servers.
L4Re follows an object-oriented design. Server interfaces are object-oriented,
and the implementation is also object-oriented.

A minimal L4Re-based application needs 3 components to be booted beforehand:
the L4Re Microkernel, the root pager (Sigma0), and the root task (Moe). The
Sigma0 root pager initially owns all system resources, but is usually used only
to resolve page faults for the Moe root task. Moe provides the essential
services to normal user applications such as an initial program loader, a
region-map service for virtual memory management, and a memory (data space)
allocator.


Further reading
===============
The following pages describe the L4Re architecture concepts in detail.

.. admonition:: Under Construction
   :class: note

   This part of the website is being worked on. Parts in this section might be
   missing or incomplete at this moment.

.. toctree::
   :maxdepth: 1

   capabilities
   IPC
   scheduling
   memory
   initial_environment
