.. _use-case-rtc:

RTC - Real-Time Clock
*********************

In this use-case we will run the ``rtc`` service on x86 hardware.

The ``rtc`` service provides access to the real-time clock of the system.
Consequently it needs access to the rtc device of the platform and ``io``
needs to be configured accordingly.


.. sourcecode:: lua
   :linenos:

    -- vim:ft=lua
    local L4 = require("L4");
    local ld = L4.default_loader;

    local io_vbus_rtc = ld:new_channel();
    ld:start({
                caps = {
                  icu       = L4.Env.icu,
                  sigma0    = L4.Env.sigma0,
                  vbus_rtc  = io_vbus_rtc:svr(),
                },
             }, "rom/io rom/x86-legacy.devs rom/vbus.io");

    local rtc = ld:new_channel();

    ld:start({
               caps = {
                 vbus = io_vbus_rtc,
                 rtc  = rtc:svr(),
               },
             },
             "rom/rtc");

    ld:start({
               caps = {
                 rtc = rtc,
               },
             },
             "rom/rtc-client");


The script references two files for configuring the io component.
``x86-legacy.devs`` describes some of the always existing devices in an x86-based
system and can be found `here <https://github.com/L4Re/io/blob/main/io/configs/x86-legacy.devs>`_.

``vbus.io`` creates a virtual bus for the rtc service, using this content:

.. sourcecode:: lua
   :linenos:

   -- vim:ft=lua
   local hw = Io.system_bus();

   Io.add_vbusses
   {
     vbus_rtc = Io.Vi.System_bus(function()
       rtc = wrap(hw.RTC);
     end);
   }

