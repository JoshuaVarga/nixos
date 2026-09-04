{ lib, ... }:
{
  den.schema.host =
    { lib, ... }:
    {
      options.memory = {
        totalGiB = lib.mkOption {
          type = lib.types.nullOr lib.types.ints.positive;
          default = null;
        };
        swapFileGiB = lib.mkOption {
          type = lib.types.ints.unsigned;
          default = 0;
        };
      };
    };

  den.aspects.memory =
    { host, ... }:
    let
      totalGiB = host.memory.totalGiB;
      gib = n: "${toString n}G";
    in
    {
      nixos = {
        assertions = [
          {
            assertion = host.memory.totalGiB != null;
            message = "den.aspects.memory requires memory.totalGiB to be set on the host";
          }
        ];

        nix.settings = {
          max-jobs = 2;
          cores = totalGiB / 8;
        };

        systemd.services.nix-daemon.serviceConfig = {
          MemoryMax = gib (totalGiB * 4 / 5);
          MemorySwapMax = gib (totalGiB / 2);
        };

        zramSwap = {
          enable = true;
          algorithm = "zstd";
          memoryPercent = 25;
        };

        swapDevices = lib.optional (host.memory.swapFileGiB > 0) {
          device = "/var/lib/swapfile";
          size = host.memory.swapFileGiB * 1024;
        };

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
    };
}
