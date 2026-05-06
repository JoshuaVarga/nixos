{ den, lib, ... }:
{
  # Schema for user definitions
  # Extensible base modules for declaring user metadata
  den.schema.user = { user, lib, ... }: {
    config.classes = [ "homeManager" ];
    
    options.mainGroup = lib.mkOption {
      description = "User's main group";
      default = user.userName;
    };
  };

  # User definitions
  den.homes."joshua@titan" = { };
}
