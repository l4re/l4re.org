.. _getting_started-bob:

Building With the Bob Build Tool
********************************

This guide places the sources in the directory ``$HOME/projects/l4re``. You can choose this location as you like. That's why we start defining an environment variable for this location:

.. sourcecode:: shell

   export BOB_DIR=$HOME/projects/l4re

Prerequisites
=============

To build the pre-composed L4Re system configurations, `Bob Build Tool`_ is used
as a meta build system. So first, we :external+bob:ref:`install Bob
<installation-install>`, preferably into a dedicated Python virtualenv e.g.:

.. sourcecode:: shell

   cd $BOB_DIR
   virtualenv bob-venv
   . bob-venv/bin/activate
   pip install BobBuildTool

.. hint::

   Depending on your distribution, you may have to install
   ``python3-virtualenv`` or a similar package.

If we leave the shell, we only have to source ``bob-venv/bin/activate`` next
time:

.. sourcecode:: shell

   . bob-venv/bin/activate

.. attention::

   It is highly recommended to apply the :external+bob:ref:`standard
   configuration <installation-recommended-config>` before proceeding. It will
   save network bandwidth and reduce build times.

Next, we clone the `L4Re tutorial recipes`_:

.. todo::

   - create repo for tutorial recipes

.. sourcecode:: shell

   git clone https://github.com/l4re/l4re-tutorials.git

Lastly, we have to fetch the dependent layers:

.. sourcecode:: shell

   cd l4re-tutorials
   bob layers update

.. hint::

  Layers usually only need to be fetched initially. Bob will update them
  automatically unless the ``--build-only`` / ``-b`` option is used. In this
  case it is recommended to update them explicitly after the tutorials
  repository has been pulled.

Build and run the "Hello World" example
=======================================

Now we can build L4Re with a single application: Hello World. The image is
built for the Qemu x86 platform:

.. sourcecode:: shell

   bob dev --dev-sandbox examples-amd64/examples::hello -j

This might take a while. Especially the task that builds ``core::l4re``. But when
finished, the output should end with the words ``Build result is in
dev/dist/examples/hello/1/workspace``.

.. note::
   The ``--dev-sandbox`` option runs the build in a containerized environment
   for better reproducibility. If your system configuration prohibits the use
   of unprivileged containers, you can leave out the switch.

   With ``-j`` all available CPU cores are used.

   See the :external+bob:ref:`manpage-dev` manpage for more details.

To run the example, ``qemu-system-x86_64`` must be installed. If in doubt,
install the ``qemu-system`` package on your system (Debian/Ubuntu. Other
distributions may have a similar package).

Finally, we can execute the runner script in the output folder:

.. sourcecode:: shell

   dev/dist/examples/hello/1/workspace/bootx64.efi.launch

Continuing The Introduction Guide
=================================

The steps to build the example also checked out the L4Re source code. Knowing
the code location is essential for the next steps in this introductory guide.
It might be handy to define the following additional environment variable:

.. sourcecode:: shell

   export L4RE_SRCDIR=$(pwd)/dev/src/core/l4re/1/workspace

Now you can go to :doc:`multiple_hello` to learn how to adjust l4re scenarios
to your liking.

.. _Bob Build Tool: https://bobbuildtool.dev
.. _L4Re tutorial recipes: https://github.com/l4re/l4re-tutorials
