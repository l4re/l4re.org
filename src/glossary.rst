Glossary
********

.. glossary::

  ACPI
    Advanced Configuration and Power Interface. An open standard that operating
    systems can use to discover and configure computer hardware components, to
    perform power management (e.g. putting unused hardware components to
    sleep), auto configuration (e.g. Plug and Play and hot swapping), and
    status monitoring.

  Capability
    ...

  IPC
    Inter Process Communication. The foundational principle of the L4Re system
    to connect entities in the system.

  Object space
    The object space is the part of a :term:`Task` that holds references to
    kernel objects. Among others, these are for example :term:`IPC gates<IPC gate>`.

  Task
    A task comprises a memory address space (represented by the task's page
    table), an :term:`Object space` (holding the kernel protected
    capabilities), and on x86 an IO-port address space.

  Thread
    A thread is bound to a task and executes code. Multiple threads can coexist
    in one task and are scheduled by the microkernel's scheduler.

  Factory
    A factory is used by applications to create new kernel objects. Access to a
    factory is required to create any new kernel object. Factories can control
    and restrict object creation.

  IPC gate
    An IPC gate is used to create a secure communication channel between
    different :term:`Tasks<Task>`. It embeds a label (kernel protected payload) that
    securely identifies the gate through which a message is received. The gate
    label is not visible to and cannot be altered by the sender.

  IRQ
    IRQ objects provide access to hardware interrupts. Additionally, programs
    can create new virtual interrupt objects and trigger them. This allows
    implementing a signaling mechanism. The receiver cannot decide whether the
    interrupt is a physical or virtual one.

  Vcon
    Provides access to the in-kernel debugging console (input and output).
    There is only one such object in the kernel and it is only available, if
    the kernel is built with debugging enabled. This object is typically
    interposed through a user-level service or without debugging in the kernel
    can be completely based on user-level services.

  Scheduler
    Implements scheduling policy and assignment of threads to CPUs, including
    CPU statistics.

  VMM
    Virtual Machine Monitor. The service that implements the virtual machine
    model (read: the virtual hardware) and controls the execution of the
    virtual machine guest.

  Virtio
    ...
