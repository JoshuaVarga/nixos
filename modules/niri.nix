{
  den.aspects.niri.nixos =
    { pkgs, ... }:
    {
      programs.niri.enable = true;

      environment.systemPackages = with pkgs; [
        xwayland-satellite
      ];

      xdg.portal = {
        enable = true;
        extraPortals = with pkgs; [
          xdg-desktop-portal-gnome
          xdg-desktop-portal-gtk
        ];
      };

      security.polkit.enable = true;

      services.gnome.gcr-ssh-agent.enable = false;

      services.greetd = {
        enable = true;
        settings.default_session = {
          command = "niri-session";
          user = "joshua";
        };
      };
    };
}
