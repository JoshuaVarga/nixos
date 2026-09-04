{ inputs, ... }:
{
  imports = [ inputs.git-hooks.flakeModule ];

  perSystem =
    { pkgs, ... }:
    {
      pre-commit.settings.hooks = {
        commitizen.enable = true;

        gitleaks = {
          enable = true;
          name = "gitleaks";
          description = "detect hardcoded secrets";
          entry = "${pkgs.gitleaks}/bin/gitleaks protect --staged --verbose --redact";
          language = "system";
          pass_filenames = false;
        };

        treefmt.enable = true;
      };
    };
}
