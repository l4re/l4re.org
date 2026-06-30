-- vi:ft=lua
local L4 = require("L4");
local ld = L4.default_loader;

local emmc_driver_params = "" ..
  "-v " ..
  "--client disk1 --device 0FC63DAF-8483-4772-8E79-3D69D8477DE4"

local hw_desc_file = "";
if L4.Info.arch() == "arm64" or L4.Info.arch() == "arm" then
  hw_desc_file = "rom/hw_devices.io";
end

local vbus_sdhci = ld:new_channel();
ld:start({ caps = {
                    sigma0   = L4.Env.sigma0;
                    icu      = L4.Env.icu;
                    iommu    = L4.Env.iommu,
                    sdhci    = vbus_sdhci:svr();
           },
         },
         "rom/io -vvvv " .. hw_desc_file .. " rom/vbus.io");

local emmc_part1 = ld:new_channel()
ld:start({ caps = {
                    vbus   = vbus_sdhci,
                    disk1  = emmc_part1:svr(),
           },
           log = { "emmc", "cyan" },
         }, "rom/emmc-drv " .. emmc_driver_params);

-- 'emmc_part1' is now a valid virtio-block capability
