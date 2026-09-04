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
      hookTypes = [
        "pre-commit"
        "commit-msg"
      ];
      hookScript = type: ''
        #!/usr/bin/env bash
        PC=${pcBin}
        ARGS=(hook-impl --config=.pre-commit-config.yaml --hook-type=${type})
        HERE="$(cd "$(dirname "$0")" && pwd)"
        ARGS+=(--hook-dir "$HERE" -- "$@")
        if [ ! -x "$PC" ]; then
            nix develop /etc/nixos --command true && exec "$0" "$@"
        fi
        exec "$PC" "''${ARGS[@]}"
      '';
      installHook = type: ''
        _hook="$(git rev-parse --absolute-git-dir)/hooks/${type}"
        printf '%s' ${lib.escapeShellArg (hookScript type)} > "$_hook"
        chmod +x "$_hook"
        rm -f "$_hook.legacy"
      '';
    in
    {
      devShells.default = pkgs.mkShell {
        packages = [
          config.treefmt.build.wrapper
          pkgs.pre-commit
          pkgs.commitizen
          pkgs.gitleaks
          pkgs.vulnix
        ];
        shellHook = ''
          ${config.pre-commit.installationScript}
          ${lib.concatMapStringsSep "\n" installHook hookTypes}
        '';
      };
    };
}
