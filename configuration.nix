{ config, lib, pkgs, inputs, ... }:

{
  imports =
    [ 
      ./hardware-configuration.nix
    ];

  hardware.graphics.enable = true;
  hardware.bluetooth.enable = true;

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "titan";
  networking.networkmanager.enable = true;

  time.timeZone = "Canada/Toronto";

  users.users.joshua = {
    isNormalUser = true;
    extraGroups = [ "wheel" ]; # Enable ‘sudo’ for the user.
    packages = with pkgs; [
      tree
    ];
  };

  programs.firefox.enable = true;
  programs.hyprland.enable = true;
  programs.ssh.startAgent = true;

  environment.systemPackages = with pkgs; [
    inputs.noctalia.packages.${pkgs.stdenv.hostPlatform.system}.default
    vim
    neovim
    wget
    wezterm
    nushell
    starship
    git
    chezmoi
  ];

  services.openssh.enable = true;
  services.tuned.enable = true;
  services.upower.enable = true;
  services.greetd = {
    enable = true;
    settings.default_session = {
      command = "start-hyprland";
      user = "joshua";
    };
  };

  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  boot.initrd.kernelModules = [ "hyperv_drm" ];
  boot.kernelModules = [ "hyperv_drm" ];
  
  services.xserver.videoDrivers = [ "modesetting" ];

  system.stateVersion = "25.11";
}

