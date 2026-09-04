{ lib, ... }:
{
  den.aspects.oom-hardening.nixos = {
    nix.settings = {
      max-jobs = 2;
      cores = 8;
    };

    systemd.services.nix-daemon.serviceConfig = {
      MemoryHigh = "20G";
      MemoryMax = "26G";
      MemorySwapMax = "2G";
    };

    zramSwap = {
      enable = true;
      algorithm = "zstd";
      memoryPercent = 50;
    };

    swapDevices = lib.mkForce [ ];

    boot.kernel.sysctl = {
      "vm.swappiness" = 180;
      "vm.watermark_boost_factor" = 0;
      "vm.watermark_scale_factor" = 125;
      "vm.page-cluster" = 0;
    };

    systemd.oomd = {
      enable = true;
      enableRootSlice = true;
      enableSystemSlice = true;
      enableUserSlices = true;
    };
  };
}
