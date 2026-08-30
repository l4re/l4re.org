Hardware access control
***********************

.. admonition:: Under Construction
   :class: note

   This part of the website is being worked on. Please refer to `the doxygen
   documentation <https://l4re.org/doc/io.html>`_ for information
   about this topic.

.. todo::

   - Stretch goal: Write content

The Io server is the central component in L4Re to implement hardware access
control. The Io server handles all platform devices and resources such as I/O
memory, ports (on x86) and interrupts, and grants access to those to clients.

Upon startup Io discovers all platform devices using available means on the
system, e.g. on x86 the PCI bus is scanned and the :term:`ACPI` subsystem
initialized. Available I/O resources can also be configured via configuration
scripts.


