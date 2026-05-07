{
  den.aspects.nvidia.nixos =
    { config, ... }:
    {
      services.xserver.videoDrivers = [ "nvidia" ];

      hardware.nvidia = {
        # Blackwell (RTX 50xx) requires the open kernel modules.
        open = true;
        modesetting.enable = true;
        nvidiaSettings = true;
        powerManagement.enable = true;
        package = config.boot.kernelPackages.nvidiaPackages.production;
      };
    };
}
