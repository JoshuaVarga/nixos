{ den, inputs, lib }:
{ host, ... }@ctx:
{
  nixos = { config, pkgs, ... }: {
    boot.initrd.kernelModules = [ "hyperv_drm" ];
    boot.kernelModules = [ "hyperv_drm" ];
    services.xserver.videoDrivers = [ "modesetting" ];
  };
}
