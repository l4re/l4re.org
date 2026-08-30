.. _use-case-emmc-s32g:

eMMC on NXP S32G
****************

In this use-case we will run the emmc-driver on the NXP S32G.

The emmc-driver provides access to eMMC and SD-Card like devices, giving
clients a block interface to read and write blocks via the
Virtio-block protocol.

To run the emmc-driver, it needs access to the eMMC or SD controller of the
platform which it gets via the io component.

An appropriate script for ned may look like this:

.. sourcecode:: lua
   :linenos:

   -- vim:ft=lua

   local L4 = require("L4");
   local ld = L4.default_loader;

   local io_vbus_emmc = ld:new_channel();
   ld:start({
               caps = {
                 icu       = L4.Env.icu,
                 sigma0    = L4.Env.sigma0,
                 vbus_emmc = io_vbus_emmc:svr(),
               },
            }, "rom/io rom/hw_devices.io rom/vbus.io");

    local emmc_driver = ld:new_channel();

    ld:start({
               caps = {
                 vbus = io_vbus_emmc,
                 svr  = emmc_driver:svr(),
               },
             },
             "rom/emmc-drv");

    -- Provide clients access to specific GPT partitions. Either use a GPT
    -- partition label or the GPT partition's UUID:
    -- Example:
    ld:start({
               caps = {
                 virtio_blk1 = emmc_driver:create(0, "device=partlabel:NAME"),
                 virtio_blk2 = emmc_driver:create(0, "device=partuuid:B874C937-5588-4231-A85C-1E629BF4364E"),
               },
             }, "rom/client");


The script references two files for configuring the io component.
``hw_devices.io`` is the hardware device configuration of the S32G, as found
`here <https://github.com/L4Re/io/blob/main/io/configs/plat-s32g/hw_devices.io>`_.

``vbus.io`` creates a virtual bus for the emmc driver, using this content:


.. sourcecode:: lua
   :linenos:

   -- vim:ft=lua

   local hw = Io.system_bus();

   Io.add_vbusses
   {
     vbus_emmc = Io.Vi.System_bus(function()
       usdhc0  = wrap(hw.usdhc0);
     end);
   }


When launching this setup, the final output should be like this. No errors
shall be displayed::

   emmc-drv| eMMC[factory]: Assuming host clock of 400MHz.
   emmc-drv| Capability 'sdhci_adma_buf' not found -- allocating buffer.
   emmc-drv| Capability 'iobuf' not found -- allocating buffer.
   emmc-drv| eMMC-0[device]: Found eMMC device.
   emmc-drv| eMMC-0[device]: Device initialization took 260ms (0ms busy wait, 251ms sleep).
   emmc-drv| eMMC-0[device]: Successfully set 'HS400 Dual Data Rate eMMC at 200MHz (1.8V)'.

When investigating any issues, adding ``-v`` options to ``rom/io`` and
``rom/emmc-drv``, also multiple times, gives more valuable output.
