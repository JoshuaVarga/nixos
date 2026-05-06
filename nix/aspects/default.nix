{ den, inputs, lib, ... }:
{
  # Base aspects index - will import individual aspects
  # Each aspect is a function returning multi-class config
  
  den.aspects.os-base = import ./os-base.nix { inherit den inputs lib; };
  den.aspects.hardware-titan = import ./hardware/titan-hyperv.nix { inherit den inputs lib; };
  den.aspects.services = import ./services.nix { inherit den inputs lib; };
  den.aspects.desktop = import ./desktop.nix { inherit den inputs lib; };
  den.aspects.shell = import ./shell.nix { inherit den inputs lib; };
  den.aspects.dev-tools = import ./dev-tools.nix { inherit den inputs lib; };
  den.aspects.user-joshua = import ./user-joshua.nix { inherit den inputs lib; };
}
