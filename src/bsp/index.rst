.. _bsp:

BSP and hardware support
************************

.. todo::

   - Write more content
   - The list is not really long. Are there more we could add?

L4Re supports many SoCs and boards. The following list is a collection of
informations for specific boards and setups. Usually, if the SoC is
supported, any other board based on the same SoC will be usable too.


Device Tree, ACPI, UEFI, and standalone Targets
-----------------------------------------------

L4Re BSPs use hardware information as provided by the platform.

Arm
^^^

Arm uses a "Generic Platform" setup that shall cover all Arm platforms
uniformely with a device tree.

The Arm SBSA BSP uses ACPI and works on all SBSA-compliant platforms.

Coming from a long history of Arm device support, as of today, some L4Re Arm
targets are standalone and encode platform information themselves, and do
not use a device tree. We aim to convert standalone BSPs to device-tree
ones as we come across them.

New platforms will be covered by the "Generic Platform" exclusively.

As of today we provide a SoC-specific configuration snippet to specify the
load address, for example, for uimages. Those shall be the only mention of
specific SoCs.

The option of providing a board specific BSP for L4Re will be retained for
use-cases that require the minimization of code, for example for specific
certification requirements, where inclusion of, for example handling device
trees in the boot path, is prohibitive.


RISC-V
^^^^^^

RISC-V uses SBI and device-tree.

x86
^^^

x86 targets use ACPI. There is only one single platform configuration that
shall run on all x86-based systems.


Porting Guide
-------------

There is also a BSP porting guide to enable a platforms for L4Re without a device tree: :doc:`porting-guide`


BSPs
----

.. toctree::
   :maxdepth: 1

   porting-guide.rst
   rpi.rst
   s32g.rst
   s32e.rst
   s32n79.rst
   zynqmp.rst
