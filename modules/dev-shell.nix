{
  perSystem =
    {
      config,
      pkgs,
      ...
    }:
    {
      devShells.default = pkgs.mkShell {
        packages = [
          config.treefmt.build.wrapper
          pkgs.pre-commit
          pkgs.gitleaks
          pkgs.vulnix
        ];
        shellHook = config.pre-commit.installationScript;
      };
    };
}
