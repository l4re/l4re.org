-- vim:ft=lua
package.path = "rom/?.lua";

local L4  = require("L4");
local vmm = require("vmm");
local ld  = L4.default_loader;

-- Console multiplexer, directly connected to the VM's console
vmm.loader.log_fab = ld:new_channel();
ld:start({ log  = L4.Env.log,
           caps = { cons = vmm.loader.log_fab:svr() } },
         "rom/cons -a -c vm1");

-- Platform bus with one vbus for the SDHCI and one for the Ethernet controller
local vbus_sdhci = ld:new_channel();
local vbus_eth   = ld:new_channel();
ld:start({ caps = { sigma0  = L4.Env.sigma0,
                    icu     = L4.Env.icu,
                    iommu   = L4.Env.iommu,
                    dma_mgr = L4.Env.dma_mgr,
                    sdhci   = vbus_sdhci:svr(),
                    ethdevs = vbus_eth:svr() },
           log  = { "io", "red" } },
         "rom/io rom/hw_devices.io rom/vbus.io");

-- eMMC driver, exporting partitions as virtio-block devices. Clients are
-- created via its factory, one for each partition.
local emmc = ld:new_channel();
ld:start({ caps = { vbus = vbus_sdhci, svr = emmc:svr() },
           log  = { "emmc", "cyan" } },
         "rom/emmc-drv");

-- Network switch, with the Ethernet controller as one of its ports
local switch = ld:new_channel();
ld:start({ caps = { svr = switch:svr(), vbus = vbus_eth },
           log  = { "switch", "blue" } },
         "rom/l4vio_switch");

-- The VM, starting u-boot instead of a Linux kernel
vmm.start_vm{
  id       = 1,
  mem      = 256,
  kernel   = "rom/u-boot.bin",
  fdt      = { "rom/virt-arm_virt-64.dtb", "rom/uboot-vm.dtbo" },
  net      = switch:create(0, "ds-max=4", "name=vm1",
                           "mac=02:08:0f:2a:00:01"),
  ext_caps = {
    disk = emmc:create(0, "device=partlabel:vm1-disk",  "ds-max=4"),
    env  = emmc:create(0, "device=partlabel:uboot-env", "ds-max=4"),
  },
};
