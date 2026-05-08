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

      # Hide the GPU's HDA controller from PipeWire. PipeWire's ACP can't generate
      # any profiles for it, so it gets exposed with zero profiles and Steam's
      # bundled libaudio.so segfaults on NULL when enumerating sinks.
      services.pipewire.wireplumber.extraConfig.disable-nvidia-hda = {
        "monitor.alsa.rules" = [
          {
            matches = [
              {
                "alsa.id" = "NVidia";
                "device.bus" = "pci";
              }
            ];
            actions.update-props."device.disabled" = true;
          }
        ];
      };
    };
}
