.. _porting-guide:

BSP Porting Guide
*****************

Generally porting L4Re to a specific BSP shall not be necessary anymore as
the "Generic Platform" uses platform and firmware information provided by
the platform, for example, the device tree.

However, if the code needed by boot-up and in the microkernel Fiasco shall
be minimal, L4Re can be adapted specificcally to a SoC/board.
This guide shall give guidelines for porting L4Re to such a configuration
on an already supported architecture, e.g., adapting L4Re to an Arm or
RISC-V platform.

Further, providing bootstrap with a device tree is still recommended for the
reason of providing relevant information for setting up the system,
especially potentially reserved memory regions of the platform. However,
with specific adaption to the platform, using a device tree for bootstrap
can be avoided as well.

Affected Components
-------------------

Four components of L4Re need to be extended or adapted for supporting a SoC:

* The L4Re Microkernel Fiasco
* bootstrap
* mk (Build system)
* drivers-frst

Build system: ``mk``
^^^^^^^^^^^^^^^^^^^^

The ‘mk’ component needs to be made aware of the new BSP by placing a file
with the BSP name under ``l4/mk/platforms``. Mandatory options are

* ``PLATFORM_NAME``: Short string describing the BSP
* ``PLATFORM_ARCH``: Architectures supported by the BSP
* ``PLATFORM_RAM_BASE``: Memory address where DRAM is starting for L4Re.

Optional options (definitely only needed when NOT using a device-tree):


* ``PLATFORM_RAM_SIZE_MB``: Size of DRAM in MB. Only if required in Bootstrap component.
* ``PLATFORM_UART_NR``: UART to use as done in bootstrap. Only needed if bootstrap uses it.

Please check other files in this directory for examples on what the content
should look like. The name of the configuration file is used as platform
name in the build system.


Initial loader: ``bootstrap``
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

Bootstrap is the initial loading component of L4Re. It is the first
component to run and it typically runs without virtual memory (or identity
mapped). It prepares the environment for the L4Re microkernel and initial
user-level components.

Bootstrap needs to know where memory is available in the system for L4Re. It
also sets up information for the UART to use.

Please check any of the available BSP C++ files under
``l4/pkg/bootstrap/server/src/platform/*.cc`` for examples how this is done.
All of the files in this directory follow a similar pattern. Finally the new
BSP C++ file(s) need to be added to
``l4/pkg/bootstrap/server/src/Makefile.platform`` to be built for the
respective platform.

UART Driver: ``drivers-frst``
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

The ``drivers-frst`` component contains the UART driver. Chances are high that a
UART driver already exists. If not, implement a new one for your platform,
see other UART drivers for examples on how this is done. They all follow a
similar pattern.


L4Re Microkernel
^^^^^^^^^^^^^^^^

BSPs for the L4Re Microkernel are located under ``src/kern/$ARCH/bsp/$BSP``
and all directories therein follow a similar structure. Please check any of
the available BSP directories for examples how a BSP is structured.

* ``Kconfig``: Configuration snippet. For a simple BSP only the ‘PF*’
  statements in the beginning are relevant. For more options for a BSP
  please check other Kconfig files.

* ``Modules``: Describes which files to build and include for a specific build
  of Fiasco. It selects the UART to use and so-called PREPROCESSOR tags and
  INTERFACEs to use. Main topics to fill out are:

  * ``config``: Has a name for the BSP
  * ``mem_layout``: Defines memory locations. On Arm, it contains the GIC addresses and possibly other device addresses that might be required.
  * ``timer``: BSP parts of the platform timer.
  * ``pic``: Instantiates the interrupt controller.
  * ``reset``: Reset of the platform.
  * ``clock``: Clock of the platform.
  * ``platform_control``: CPU boot-up.

* C++ files: correspond to the categories as seen in the Modules file.

As BSPs are reasonably similar it is advised to copy an existing BSP and
adapt it to the new platform.

If you had to implement a new UART driver, copy the ``.h`` and ``.cc`` over
from ``drivers-frst`` to ``src/lib/uart`` as is. The UART drivers are the
same, they just exist in the kernel and user-level components separately for
reasons of separating the build. Use the name of the ``.o`` file of the
driver in the ``OBJECTS_LIBUART`` variable in the ``Modules`` file of your
BSP to use the driver for your platform.

Recommended Order of Work
=========================

We recommend to first write the UART driver, if required, and then add the
platform support to bootstrap. This ensures that output from bootstrap can
be used to debug the further porting process. Afterwards the kernel can be
adapted.
