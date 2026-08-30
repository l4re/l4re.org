.. _use-case-net:

Networking with curl
********************

There are several options for providing network functionality on L4Re.

Basically two variants exist with respect to where a driver for a network
device can be placed.

One way is using an existing system, such as Linux, running it in a VM and
using Virtio-net to expose networking to outside of the VM. Using an
existing system, for example, Linux, gives further plenty of networking
features, such as firewalls and routing capabilities, and also plenty of
drivers for many, if not all, devices. A downside is that a
whole operating system and VM is required for this option, even if it can
be specifically customized for purpose of handling networking only.

The other way is a driver running in an L4Re application. This driver can
either be ported from some other environment or operating system, or
written from scratch. Eventually such a driver needs to interact with the
software components that use it. Usage could be in-process, i.e. an
application has a specific network driver built-in and thus directly
talks to the network device. Or the driver offers its services to other components in the
system through a shared memory interface. For network, Virtio-net is a
common and established interface.

In L4Re, there's a virtual network switch that also has support to integrate
device drivers. Thus the virtual network switch can be seen as a network
device driver with multiple Virtio-net interfaces, or a virtual network
switch where one port is not Virtio but a physical network device.


Running the network switch with the ixl drivers
-----------------------------------------------

The virtual network switch has support for the ``ixl`` network drivers.
Please refer to `the ixl drivers <https://github.com/l4re/ixl>`_ for
details, such as supported network devices.

The application using the network is the famous ``curl``. To work with the
driver via virtio-net, it needs a networking stack. We use ``lwIP``, which
has also been brought to L4Re with appropriate connectors for virtio-net.

Building ixl and virtio-net-switch
----------------------------------

The switch has a compile-time configuration that needs to be enabled such
that the functionality for network device drivers is included. Please have
the ``ixl`` package cloned to ``l4/pkg/ixl`` and the ``CONFIG_VNS_IXL``
enabled option in the L4Re configuration.


Building curl
-------------

Please have
`curl <https://github.com/l4re/curl>`_,
`zstd <https://github.com/l4re/zstd>`_,
and `LwIP <https://github.com/l4re/lwip>`_
cloned to ``l4/pkg/curl``, ``l4/pkg/zstd`` and ``l4/pkg/lwip`` respectively,
next to the standard L4Re packages.

Compile everything.


Setting up the scenario
-----------------------

The following ned script starts the network switch together with curl,
downloading a web page.

.. literalinclude:: ../../../_static/use-cases/net-swt-curl/virtio-net-switch-drv-example.ned
   :language: lua
   :linenos:
   :caption: virtio-net-switch-drv-example.ned

Please find a possible ixl.vbus `here <https://github.com/L4Re/ixl/blob/main/assets/ixl.vbus>`_.

A ``resolv.conf`` file also needs to be supplied with the following content:

.. literalinclude:: ../../../_static/use-cases/net-swt-curl/resolv.conf
   :caption: resolv.conf

A module.list entry looks like this:

.. literalinclude:: ../../../_static/use-cases/net-swt-curl/modules.list
   :caption: modules.list

Put all the files in a directory picked up by L4Re's image generation.

Run it with QEMU
----------------

The use-case can be run like this in one command. Of course, variables can
also be put into your ``Makeconf.boot`` file, shortening the below command
to just ``make qemu E=virtio-net-switch-drv-example``.

.. sourcecode:: shell

   make qemu E=virtio-net-switch-drv-example \
        MODULES_LIST=$PWD/modules.list \
        MODULE_SEARCH_PATH=$PWD/fiasco/build \
        QEMU_OPTIONS="-serial stdio -vnc none -m 1g -netdev user,id=net1 -device e1000,netdev=net1"

Build'n'Run Script
------------------

The following `shell script <https://l4re.org/_static/use-cases/net-swt-curl/build_and_run.sh>`_
summarizes the above steps. Of course you can build this setup from your
existing source tree, given all the needed repositories, as described above,
are available. The files downloaded
are exactly the ones from this page (given you are looking at a version
generated out of the referenced files).

.. literalinclude:: ../../../_static/use-cases/net-swt-curl/build_and_run.sh
   :language: shell
   :linenos:
   :caption: build_and_run.sh


