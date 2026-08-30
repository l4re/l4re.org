Armv8-R AArch64 mixed criticality system
****************************************

This example demonstrates how the L4Re Micro Hypervisor can be used to
create mixed-criticality systems on Armv8-R AArch64 systems. The example
demonstrates the capabilities of the `Cortex-R82AE
<https://www.arm.com/products/silicon-ip-cpu/cortex-r/cortex-r82ae>`_ to
run a safety, real time guest next to a general-purpose Linux VM.

.. uml::

   package "uvmm Zephyr" as vm1 {
     [zephyr VM]
   }

   package "uvmm Linux" as vm2 {
     [Linux VM]
   }

   [rtc] ..> [io] : map PL031 device
   vm2 ..> [io] : map LAN91C111 device

   package "Hardware Interfaces" {
   interface UART
   interface PL031
   interface LAN91C111
   }

   [cons] --> UART : MMIO
   [io] --> [cons] : stdout

   [rtc] --> [cons] : stdout
   [rtc] --> PL031 : MMIO

   vm1 --> [cons] : console

   vm2 --> [cons] : console
   [Linux VM] --> [rtc] : read
   [Linux VM] --> LAN91C111 : MMIO

Build
=====

Follow the :ref:`initial build instructions <getting_started-bob>`. Build
the particular example via:

.. sourcecode:: shell

    bob dev --dev-sandbox examples-arm64-fvp_base_r/examples::linux+zephyr-vm -j
    [...]
    Build result is in dev/dist/examples/linux+zephyr-vm/1/workspace

Run
===

The example runs in the `Arm Fixed Virtual Platform
<https://developer.arm.com/Tools%20and%20Software/Fixed%20Virtual%20Platforms>`_
emulator. To run it, download the FVP_Base_AEMv8R model of the
`Arm Architecture FVPs <https://developer.arm.com/Tools%20and%20Software/Fixed%20Virtual%20Platforms/Arm%20Architecture%20FVPs>`_
for your host platform. These models are available free of charge:

.. sourcecode:: shell

    wget https://developer.arm.com/-/cdn-downloads/permalink/FVPs-Architecture/FM-11.28/FVP_Base_AEMv8R_11.28_23_Linux64.tgz
    tar xf FVP_Base_AEMv8R_11.28_23_Linux64.tgz
    export PATH="$PWD/AEMv8R_base_pkg/models/Linux64_GCC-9.3:$PATH"

The example has been tested with the 11.28 release but it should also work
with older models. Starting the example assumes that the FVP is available
in ``$PATH``:

.. sourcecode:: shell

    dev/dist/examples/linux+zephyr-vm/1/workspace/bootstrap.elf.launch

The above command will start the example and should produce output
comparable to the example below::

    L4 Bootstrapper
      Build: #14 Fri Feb 21 19:17:17 UTC 2025, 13.2.0
      RAM: 0000000000000000 - 000000007fffffff: 2097152kB
      Total RAM: 2048MB
      Scanning fiasco -serial_esc
      Scanning sigma0
      Scanning moe --brk=c000000 rom/ned.lua
    [...]
    linux   | VMM[main]: Hello out there.
    zephyr  | VMM: Hello clock source for vCPU 0
    linux   | VMM[ram]: No memory nodes found, setting up default region
    zephyr  | VMM: Starting Cpu0 @ 0x2000ff4 in 64Bit mode (handler @ daf83cc, stack: da49b40, task: 41e000, mpidr: 80000000 (orig: 80000000)
    zephyr  | *** Booting Zephyr OS build 3.7.1 ***
    zephyr  | thread_a: Hello World from cpu 0 on fvp_baser_aemv8r!
    zephyr  | thread_b: Hello World from cpu 0 on fvp_baser_aemv8r!
    zephyr  | thread_a: Hello World from cpu 0 on fvp_baser_aemv8r!
    zephyr  | thread_b: Hello World from cpu 0 on fvp_baser_aemv8r!
    linux   | VMM: virtio_net@10000.l4vmm,virtiocap: capability net is invalid.
    linux   | VMM[vm]: Device creation for virtual device virtio_net@10000 failed. Disabling device.
    linux   | VMM[ram]: Cleaning caches for device tree [1ffff000-1ffff8cf] ([1ffff000])
    zephyr  | thread_a: Hello World from cpu 0 on fvp_baser_aemv8r!
    io      | new iomem region: p=0000009a000000 v=0000009a000000 s=1000000 (bmb=0xd9c9b60)
    linux   | VMM: Hello clock source for vCPU 0
    linux   | VMM: Hello clock source for vCPU 1
    linux   | VMM: Starting Cpu0 @ 0x10000000 in 64Bit mode (handler @ dccf3cc, stack: dc20b30, task: 420000, mpidr: 80000000 (orig: 80000000)
    linux   | VMM: Starting Cpu1 @ 0x1074433c in 64Bit mode (handler @ dccf3cc, stack: e417f30, task: 420000, mpidr: 80000001 (orig: 80000000)
    linux   | [    0.000000] Booting Linux on physical CPU 0x0000000000 [0x410fd0f0]
    linux   | [    0.000000] Linux version 6.6.17 (nobody@bob) (aarch64-linux-gnu-gcc (GCC) 13.2.0, GNU ld (GNU Binutils) 2.42) #1 SMP Mon Dec 28 22:49:40 CET 2015
    linux   | [    0.000000] Machine model: L4 VM
    [...]
    linux   | [    3.025262] Freeing initrd memory: 5300K
    linux   | [    3.031142] Freeing unused kernel memory: 1280K
    linux   | [    3.091357] Checked W+X mappings: passed, no W+X pages found
    linux   | [    3.095526] Run /init as init process
    zephyr  | thread_a: Hello World from cpu 0 on fvp_baser_aemv8r!
    linux   | Welcome to Linux!
    linux   | 
    linux   | Please press Enter to activate this console. 
    zephyr  | thread_b: Hello World from cpu 0 on fvp_baser_aemv8r!
    zephyr  | thread_a: Hello World from cpu 0 on fvp_baser_aemv8r!
    zephyr  | thread_b: Hello World from cpu 0 on fvp_baser_aemv8r!
    zephyr  | thread_a: Hello World from cpu 0 on fvp_baser_aemv8r!


You can stop the example by pressing ``Ctrl+C``.

Detailed description
====================


