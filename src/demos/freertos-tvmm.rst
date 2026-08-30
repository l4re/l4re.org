Armv8-R AArch32 FreeRTOS VMs on tvmm
************************************

This example demonstrates the L4Re Micro Hypervisor running on Armv8-R AArch32
platforms. It hosts two instances of FreeRTOS, sharing a single CPU core.

.. uml::

   package "tvmm" {
     [FreeRTOS 1]
     [FreeRTOS 2]
   }

   [tinit] --> tvmm : start

Build
=====

Follow the :ref:`initial build introductions <getting_started-bob>`. Build
the particular example via:

.. sourcecode:: shell

    bob dev --dev-sandbox examples-arm-fvp_base_r/examples::freertos-tvmm -j
    [...]
    Build result is in dev/dist/examples/freertos-tvmm/1/workspace

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

    dev/dist/examples/freertos-tvmm/1/workspace/bootstrap.elf.launch

The above command will start the example and should produce output
comparable to the example below::

    L4 Bootstrapper
      Build: #5 Fri Feb 21 18:33:40 UTC 2025, 13.2.0
      RAM: 0000000000000000 - 000000007fffffff: 2097152kB
      Total RAM: 2048MB
      Scanning fiasco -serial_esc
      Scanning tinit
      Moving up to 6 modules behind f000000
      Using 'modaddr 0' in modules.list might prevent moving modules.
      moving module 05 { 60000-6cabb } -> { f088000-f094abb } [51900]
      moving module 04 { 53000-5fabb } -> { f07b000-f087abb } [51900]
      moving module 03 { 52000-520a5 } -> { f07a000-f07a0a5 } [166]
      moving module 02 { 49000-51aef } -> { f071000-f079aef } [35568]
      moving module 01 { 41000-4877b } -> { f069000-f07077b } [30588]
      moving module 00 { e000-402db } -> { f036000-f0682db } [205532]
      Loading fiasco
      found node 0 kernel info page (via ELF) at 0xf002000
      Loading tinit
      WARNING: No roottask module for node 0 -- setup might not boot!
      found node 0 kernel options (via ELF) at 0xf003000
      Sigma0 config    node: 0   ip:00140924
      Roottask config  node: 0   ip:00000000
    Regions of list 'regions'
        [       9c,        cb] {       30} Root   cpu_boot
        [   140000,    148b07] {     8b08} Sigma0 tinit
        [  f000000,   f000fff] {     1000} Root   mbi_rt
        [  f001000,   f035fff] {    35000} Kern   fiasco
        [  f071000,   f094abb] {    23abc} Root   Module
      Starting kernel fiasco at 0f001038
    Hello from Startup::stage2
    Reserved 60 MiB as kernel memory.
    GIC: Number of IRQs available at this GIC: 256
    FPU: Initialize
    FPU0: Subarch: 3, Part: 30, Rev: 1, Var: 9, Impl: 41
    ARM generic timer: freq=100000000 interval=100000 cnt=6365014
    SERIAL ESC: allocated IRQ 37 for serial uart
    Not using serial hack in slow timer handler.
    Welcome to the L4Re Microkernel!
    L4Re Microkernel on arm-32
    Rev: 355909f5-dirty compiled with gcc 13.2.0 for ARM FVP Base-R platform    []
    Build: #2 Fri Feb 21 18:31:33 UTC 2025
    
    Cache config: ON
    Calibrating timer loop...
    Timer calibration done.
    MDB: use page size: 21
    MDB: use page size: 12
    tinit: Starting...
    tinit: KIP @0xf002000
    tinit: found 2035312 KByte free memory
    tinit: Node: 0
    tinit: start: fork 'tvmm', prio:254, utcb:2, reloc:0x0
    tinit: Loading 'tvmm', offset -0xfff000
    tinit: Copy in ELF binary section @0x1000/0x8000 from 0x0/0x7f1c
    tinit: Copy in ELF binary section @0x9000/0x6000 from 0x8000/0x580
    tinit:   defvm 'vm1', prio:16
    tinit:     ram 0x1000000/0x200000, load offset 0x0
    tinit: Copy in ELF binary section @0x1000080 from 0x80/0x1fc2
    tinit: Copy in ELF binary section @0x1003000 from 0x3000/0x8
    tinit: Loaded 'guest1.elf' into VM 'vm1': entry @ 0x1000080
    tinit:     load 'guest1.elf' entry:0x1000080
    tinit:   defvm 'vm2', prio:16
    tinit:     ram 0x2000000/0x100000, load offset 0x0
    tinit: Copy in ELF binary section @0x2000080 from 0x80/0x1fc2
    tinit: Copy in ELF binary section @0x2003000 from 0x3000/0x8
    tinit: Loaded 'guest2.elf' into VM 'vm2': entry @ 0x2000080
    tinit:     load 'guest2.elf' entry:0x2000080
    tinit: Remaining free memory:
    tinit:   [    f000 -   13ffff]
    tinit:   [  149000 -   ffffff]
    tinit:   [ 1200000 -  1ffffff]
    tinit:   [ 2100000 -  effffff]
    tinit:   [ f036000 -  f070fff]
    tinit:   [ f095000 - 7c3fffff]
    tinit: Heap: 752/1024 bytes free.
    tinit: System RAM usage: 61896 KiB
    tinit:   Bootstrap:      152 KiB
    tinit:   Kernel:       61652 KiB
    tinit:   Userspace:       92 KiB
    tinit:     tinit:         36 KiB
    tinit:     Apps:          56 KiB
    tinit: Task 'tvmm' is ready
    tinit: Kernel memory stats:
    Buddy_alloc [1024,10]
      [1024] 0x7c409c00(0) -> 00000000(0) == 1K (1024)
      [2048] 00000000(0) == 0K (0)
      [4096] 00000000(0) == 0K (0)
      [8192] 0x7c462000(3) -> 00000000(0) == 8K (8192)
      [16384] 0x7c464000(4) -> 00000000(0) == 16K (16384)
      [32768] 0x7c468000(5) -> 00000000(0) == 32K (32768)
      [65536] 0x7c470000(6) -> 00000000(0) == 64K (65536)
      [131072] 00000000(0) == 0K (0)
      [262144] 00000000(0) == 0K (0)
      [524288] 0x7ff80000(9) -> 0x7ff00000(9) -> 0x7fe80000(9) -> 0x7fe00000(9) -> 0x7fd80000(9) -> 0x7fd00000(9) ... == 60928K (62390272)
    sum of available memory: 61049K (62514176)
    Used 0%, 384KiB out of 61433KiB of Kmem
    Hello from FreeRTOS!
    task1
    task2
    Hello from FreeRTOS!
    task1
    task2

The two FreeRTOS VMs will print from their two tasks in a regular interval.
You can stop the example by pressing ``Ctrl+C``.

Detailed description
====================

The example is built by the ``recipes/examples/freertos-tvmm.yaml`` recipe. The
:ref:`tinit` configuration is stored in
``recipes/examples/freertos-tvmm/freertos.inittab``::

    start tvmm utcb:2                                                               
      defvm vm1 0x10                                                                
        ram  0x01000000 0x200000                                                    
        load guest1.elf                                                             
      end                                                                           
                                                                                    
      defvm vm2 0x10                                                                
        ram 0x02000000 0x100000                                                     
        load guest2.elf                                                             
      end                                                                           
    end                                                                             

This starts a single tvmm instance, hosting two VMs (``vm1`` and ``vm2``). Each
VM uses a different guest ELF image that was built by the
``recipes/examples/guests/freertos-tvmm.yaml`` recipe. Please refer to the
tinit detailed description for all the configuration file details.
