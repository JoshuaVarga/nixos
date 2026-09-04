{
  perSystem =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      pcBin = "${pkgs.pre-commit}/bin/pre-commit";
      hookScript = ''
        #!/usr/bin/env bash
        PC=${pcBin}
        ARGS=(hook-impl --config=.pre-commit-config.yaml --hook-type=pre-commit)
        HERE="$(cd "$(dirname "$0")" && pwd)"
        ARGS+=(--hook-dir "$HERE" -- "$@")
        if [ ! -x "$PC" ]; then
            nix develop /etc/nixos --command true && exec "$0" "$@"
        fi
        exec "$PC" "''${ARGS[@]}"
      '';
    in
    {
      devShells.default = pkgs.mkShell {
        packages = [
          config.treefmt.build.wrapper
          pkgs.pre-commit
          pkgs.gitleaks
          pkgs.vulnix
        ];
        shellHook = ''
          ${config.pre-commit.installationScript}
          _hook="$(git rev-parse --absolute-git-dir)/hooks/pre-commit"
          printf '%s' ${lib.escapeShellArg hookScript} > "$_hook"
          chmod +x "$_hook"
          rm -f "$_hook.legacy"
        '';
      };
    };
}
