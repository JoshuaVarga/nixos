{ inputs, ... }:
{
  den.aspects.noctalia.homeManager = {
    imports = [ inputs.noctalia.homeModules.default ];
    programs.noctalia-shell.enable = true;
  };
}
