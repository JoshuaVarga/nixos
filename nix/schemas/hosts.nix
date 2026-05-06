{ den, lib, ... }:
{
  # Schema for host definitions
  # Extensible base modules for declaring host metadata
  den.schema.host = { host, lib, ... }: {
    options.system = lib.mkOption {
      description = "System architecture";
      type = lib.types.str;
    };
  };

  # Hosts definitions
  den.hosts."x86_64-linux" = {
    titan = {
      system = "x86_64-linux";
      class = "nixos";
      users = {
        joshua = { };
      };
    };
  };
}
