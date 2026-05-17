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
        settings.default_session.command = "${pkgs.tuigreet}/bin/tuigreet --time --remember --asterisks --cmd niri-session --theme 'border=blue;text=white;prompt=cyan;time=magenta;container=black;action=blue;button=blue;greet=magenta'";
      };

      boot.kernelParams = [
        "vt.default_red=0x1a,0xf7,0x9e,0xe0,0x7a,0xbb,0x7d,0xa9,0x41,0xff,0xb9,0xff,0x7d,0xbb,0x0d,0xc0"
        "vt.default_grn=0x1b,0x76,0xce,0xaf,0xa2,0x9a,0xcf,0xb1,0x48,0x7a,0xf2,0x9e,0xa6,0x9a,0xb9,0xca"
        "vt.default_blu=0x26,0x8e,0x6a,0x68,0xf7,0xf7,0xff,0xd6,0x68,0x93,0x7c,0x64,0xff,0xf7,0xd7,0xf5"
      ];
    };
}
