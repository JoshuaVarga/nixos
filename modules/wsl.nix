{ den, lib, ... }:
{
  den.aspects.wsl =
    { host, ... }:
    {
      includes = [
        den.aspects.dev-tools
        den.aspects.nh
      ];

      provides.to-users =
        { user, ... }:
        {
          name = "wsl-user/${user.userName}";
          user =
            { pkgs, ... }:
            {
              shell = pkgs.nushell;
            };
        };

      nixos =
        { config, pkgs, ... }:
        let
          xdg-open = pkgs.writeShellScriptBin "xdg-open" ''
            exec /mnt/c/Windows/System32/WindowsPowerShell/v1.0/powershell.exe \
              -NoProfile -NonInteractive -Command "Start-Process '$1'"
          '';
        in
        {
          assertions = lib.mapAttrsToList (name: _: {
            assertion = config.users.users.${name}.isNormalUser;
            message = "wsl host user ${name} is incomplete: its aspect must include den.provides.define-user and den.provides.primary-user";
          }) host.users;

          wsl.interop.includePath = false;
          wsl.wslConf.interop.appendWindowsPath = false;

          time.timeZone = "America/Toronto";

          programs.ssh.startAgent = true;

          environment.variables = {
            DISPLAY = ":0";
            BROWSER = "xdg-open";
          };

          environment.systemPackages = [
            pkgs.xclip
            xdg-open
          ];
        };
    };
}
