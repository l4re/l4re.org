-- vim:ft=lua
Io.add_vbusses
{
  -- The SDHCI controller, for the eMMC driver
  sdhci = Io.Vi.System_bus
  {
    pci_08 = wrap(Io.system_bus():match("PCI/CC_0805"));
  };

  -- The Ethernet controller, for the network switch
  ethdevs = Io.Vi.System_bus(function ()
    Property.num_msis = 8;
    PCI0 = Io.Vi.PCI_bus(function ()
      pci_hd = wrap(Io.system_bus():match("PCI/CC_0200"));
    end);
  end);
};
