{
  inputs = {
    nixpkgs.url = "nixpkgs/nixos-unstable";
    
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    den = {
      url = "github:vic/den";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    
    noctalia = {
      url = "github:noctalia-dev/noctalia-shell";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.noctalia-qs.follows = "noctalia-qs";
    };

    noctalia-qs = {
      url = "github:noctalia-dev/noctalia-qs";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs@{ self, nixpkgs, home-manager, den, ... }:
  let
    lib = nixpkgs.lib;
    system = "x86_64-linux";
    
    # Dendritic aspect composition context
    ctx = {
      host = "titan";
      user = "joshua";
    };
    
    # Load aspects directly as modules
    aspects = {
      os-base = (import ./nix/aspects/os-base.nix { inherit den inputs lib; }) ctx;
      hardware-titan = (import ./nix/aspects/hardware/titan-hyperv.nix { inherit den inputs lib; }) ctx;
      services = (import ./nix/aspects/services.nix { inherit den inputs lib; }) ctx;
      desktop = (import ./nix/aspects/desktop.nix { inherit den inputs lib; }) ctx;
      shell = (import ./nix/aspects/shell.nix { inherit den inputs lib; }) ctx;
      dev-tools = (import ./nix/aspects/dev-tools.nix { inherit den inputs lib; }) ctx;
      user-joshua = (import ./nix/aspects/user-joshua.nix { inherit den inputs lib; }) ctx;
    };
    
    # Compose nixos class from aspects
    nixosModules = [
      aspects.os-base.nixos
      aspects.hardware-titan.nixos
      aspects.services.nixos
      aspects.desktop.nixos
      aspects.shell.nixos
      aspects.dev-tools.nixos
      aspects.user-joshua.nixos
    ];
    
    # Compose homeManager class from aspects
    homeManagerModules = [
      aspects.shell.homeManager or {}
      aspects.dev-tools.homeManager or {}
      aspects.user-joshua.homeManager
    ];
    
  in {
    nixosConfigurations.titan = lib.nixosSystem {
      inherit system;
      specialArgs = { inherit inputs; };
      modules = [
        ./hardware-configuration.nix
      ] ++ nixosModules ++ [
        home-manager.nixosModules.home-manager
        {
          home-manager = {
            useGlobalPkgs = true;
            useUserPackages = true;
            users.joshua = { ... }: {
              imports = homeManagerModules;
            };
            backupFileExtension = "bak";
          };
        }
      ];
    };
  };
}
