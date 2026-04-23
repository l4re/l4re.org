Performance Overview
********************

IPC, Context-Switch and Syscall Performance
===========================================

With L4Re being a microkernel-based system and hypervisor, some of you are
interested in the IPC and syscall performance of L4Re as well as the
performance of context switches. IPC is a base-level communication
mechanisms that allows to exchange a limited amount of payload data between
two threads. Context switching is switching from one executing thread to
another, which sending a message is exactly doing.
The fastest IPC is between two threads running in the same
address space (task) on the same CPU core (`Intra`). `Inter` is IPC between
two address spaces. A syscall is also an IPC but only communicates with the
kernel.

The following table provides IPC performance numbers for a single IPC on
various popular platforms (average over multiple ten thousand calls). To
perform the measurement, the L4Re microkernel has been configured in its
performance configuration ``CONFIG_PERFORMANCE=y``, i.e., without
assertions.

The source code of the benchmark program can be found `here
<https://github.com/l4re/ipcbench/>`_. The images used to measure those are
linked in the table below.

Numbers are measured with the performance counters. On Arm, the cycle counter
is used. On x86, the fixed-function counters are used.

+-----------------+----------------+----+------------------------------------------+--------------------+---------------------------------------------------------------------------------------------+
| Platform        | Processor      | Cfg| .. centered:: IPC (in CPU cycles)        | Syscall            | Image                                                                                       |
|                 |                |    +--------------------+---------------------+                    |                                                                                             |
|                 |                |    | Intra              | Inter               |                    |                                                                                             |
+=================+================+====+====================+=====================+====================+=============================================================================================+
| Raspberry Pi 5  | Arm Cortex-A76 | EL1| 247                | 384                 | 138                | `▶️ <https://l4re.org/download/ipcbench/arm64/l4re_ipcbench_rpi5-el1.uimage>`__             |
| 64bit           |                |    |                    |                     |                    |                                                                                             |
|                 |                +----+--------------------+---------------------+--------------------+---------------------------------------------------------------------------------------------+
|                 |                | EL2| 300                | 401                 | 202                | `▶️ <https://l4re.org/download/ipcbench/arm64/l4re_ipcbench_rpi5-el2.uimage>`__             |
|                 |                |    |                    |                     |                    |                                                                                             |
+-----------------+----------------+----+--------------------+---------------------+--------------------+---------------------------------------------------------------------------------------------+
| Raspberry Pi 4  | Arm Cortex-A72 | EL1| 505                | 702                 | 305                | `▶️ <https://l4re.org/download/ipcbench/arm64/l4re_ipcbench_rpi4-el1.uimage>`__             |
| 64bit           |                |    |                    |                     |                    |                                                                                             |
|                 |                +----+--------------------+---------------------+--------------------+---------------------------------------------------------------------------------------------+
|                 |                | EL2| 1388 [#2]_         | 1600 [#2]_          | 567 [#2]_          | `▶️ <https://l4re.org/download/ipcbench/arm64/l4re_ipcbench_rpi4-el2.uimage>`__             |
|                 |                |    |                    |                     |                    |                                                                                             |
+-----------------+----------------+----+--------------------+---------------------+--------------------+---------------------------------------------------------------------------------------------+
| NXP S32G2 64bit | Arm Cortex-A53 | EL1| 562                | 691                 | 230                | `▶️ <https://l4re.org/download/ipcbench/arm64/l4re_ipcbench_s32g-el1.uimage>`__             |
|                 |                |    |                    |                     |                    |                                                                                             |
|                 |                +----+--------------------+---------------------+--------------------+---------------------------------------------------------------------------------------------+
|                 |                | EL2| 661                | 770                 | 228                | `▶️ <https://l4re.org/download/ipcbench/arm64/l4re_ipcbench_s32g-el2.uimage>`__             |
|                 |                |    |                    |                     |                    |                                                                                             |
+-----------------+----------------+----+--------------------+---------------------+--------------------+---------------------------------------------------------------------------------------------+
| Ampere Altra (32| Arm Neoverse-N1| EL1| 257                | 399                 | 142                | `▶️ <https://l4re.org/download/ipcbench/arm64/l4re_ipcbench-sbsa-el1-20250602.elf>`__       |
| /80 Cores) 64bit|                |    |                    |                     |                    |                                                                                             |
|                 |                +----+--------------------+---------------------+--------------------+---------------------------------------------------------------------------------------------+
|                 |                | EL2| 299                | 440                 | 148                | `▶️ <https://l4re.org/download/ipcbench/arm64/l4re_ipcbench-sbsa-el2-20250602.elf>`__       |
|                 |                |    |                    |                     |                    |                                                                                             |
+-----------------+----------------+----+--------------------+---------------------+--------------------+---------------------------------------------------------------------------------------------+
| amd64 / x86_64  | Intel N100     |    | 173/622/557 [#1]_  | 390/1388/613 [#1]_  | 52/188/147 [#1]_   | `▶️ <https://l4re.org/download/ipcbench/amd64/l4re_ipcbench-20250602.elf>`__                |
+-----------------+----------------+----+--------------------+---------------------+--------------------+---------------------------------------------------------------------------------------------+
| amd64 / x86_64  | Intel          |    | 516/687/557 [#1]_  | 930/1240/613 [#1]_  | 118/158/147 [#1]_  | `▶️ <https://l4re.org/download/ipcbench/amd64/l4re_ipcbench-20250602.elf>`__                |
|                 | Core i9-13900K |    |                    |                     |                    |                                                                                             |
+-----------------+----------------+----+--------------------+---------------------+--------------------+---------------------------------------------------------------------------------------------+
| amd64 / x86_64  | Intel Xeon     |    | 511/649/543 [#1]_  | 934/1128/587 [#1]_  | 222/160/148 [#1]_  | `▶️ <https://l4re.org/download/ipcbench/amd64/l4re_ipcbench.elf32>`__                       |
|                 | Platinum 8352S |    |                    |                     |                    |                                                                                             |
+-----------------+----------------+----+--------------------+---------------------+--------------------+---------------------------------------------------------------------------------------------+
| amd64 / x86_64  | Intel Xeon     |    | 664/663/557 [#1]_  | 1172/1172/613 [#1]_ | 146/146/147 [#1]_  | `▶️ <https://l4re.org/download/ipcbench/amd64/l4re_ipcbench-20250602.elf>`__                |
|                 | Gold 6248R     |    |                    |                     |                    |                                                                                             |
+-----------------+----------------+----+--------------------+---------------------+--------------------+---------------------------------------------------------------------------------------------+

.. [#1] Values reflect the PMC's fixed-function counters 2 (TSC without halt) / 1 (clocks unhalted) / 0 (instructions retired)

.. [#2] The Cortex-A72 performs considerable slower in EL2 mode, compared to
        running in EL1, and compared to EL2 of other Arm cores. This has
        been analyzed down to the microarchitectural level and cannot be
        influenced by software.

For x86: You can boot the image directly in GRUB2, e.g. ``multiboot2 (http,l4re.org)/download/ipcbench/amd64/l4re_ipcbench-20250602.elf``

For the Raspberry Pi's, converting the uimage to a raw image for firmware
boot works like this: ``dd if=l4re_ipcbench_rpi5-elX.uimage of=l4re.raw bs=64 skip=1``.


Plots of Parallel Execution of the Benchmark
============================================

The following are plots showing IPC between two threads in the same task
(address space) and on the same core, and one such pair running in parallel
on each core. This benchmark shows the IPC scalability of the system. The
graph shall be horizontal and flat to indicate IPC is happening without
interference to and from other cores.

.. raw:: html

   <script src="_static/js/chart.js"></script>

.. raw:: html
   :file: ../_build/perf/arm_altra80_el1_ipc.html

.. raw:: html
   :file: ../_build/perf/arm_altra80_el2_ipc.html

.. raw:: html
   :file: ../_build/perf/x86_xeon_gold_6248R_2socket_noht.html

.. raw:: html
   :file: ../_build/perf/x86_xeon_gold_6248R_2socket_all.html

.. raw:: html
   :file: ../_build/perf/x86_n100.html
