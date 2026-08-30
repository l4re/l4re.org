Virtual network switch
**********************

.. admonition:: Under Construction
   :class: note

   This part of the website is being worked on. Parts in this section might be
   missing or incomplete at this moment.

.. todo::

   - Stretch goal: Write content

The virtual network switch connects multiple clients with a virtual network
connection. It uses :term:`Virtio` as the transport mechanism. Each virtual switch port
implements the host-side of a :term:`Virtio` network device (virtio-net).

The virtual network switch can be set up to feature exactly one monitor port.
All traffic passing through the switch is mirrored to the monitor port. The
monitor port is read-only, and has no TX capability.
An optional packet filter can be configured and implemented to filter data
sent to the monitor port.
