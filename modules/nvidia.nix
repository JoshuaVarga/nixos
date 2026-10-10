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

      # Hide the GPU's HDA controller from PipeWire to keep Steam's bundled
      # libaudio.so from segfaulting while enumerating PulseAudio cards.
      # Match on device-level props: alsa.id is null at device-creation time,
      # so the previous alsa.id match never fired.
      services.pipewire.wireplumber.extraConfig.disable-nvidia-hda = {
        "monitor.alsa.rules" = [
          {
            matches = [
              {
                "device.api" = "alsa";
                "device.bus" = "pci";
                "device.vendor.id" = "0x10de";
              }
            ];
            actions.update-props."device.disabled" = true;
          }
        ];
      };
    };
}
