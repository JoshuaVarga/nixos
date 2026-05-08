{
  den.aspects.niri = {
    nixos =
      { pkgs, ... }:
      {
        environment.systemPackages = with pkgs; [
          niri
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
      };

    homeManager =
      { ... }:
      {
        xdg.configFile."niri/config.kdl".text = ''
          input {
              keyboard {
                  xkb {
                  }
                  repeat-delay 250
                  repeat-rate 35
              }
              touchpad {
                  tap
                  natural-scroll
              }
              mouse {
              }
              warp-mouse-to-focus
              focus-follows-mouse max-scroll-amount="0%"
          }

          layout {
              gaps 8
              center-focused-column "never"
              preset-column-widths {
                  proportion 0.33333
                  proportion 0.5
                  proportion 0.66667
              }
              default-column-width { proportion 0.5; }
              focus-ring {
                  width 2
                  active-color "#7fc8ff"
                  inactive-color "#505050"
              }
              border {
                  off
              }
          }

          prefer-no-csd

          screenshot-path "~/Pictures/Screenshots/Screenshot from %Y-%m-%d %H-%M-%S.png"

          hotkey-overlay {
              skip-at-startup
          }

          spawn-at-startup "noctalia-shell"

          binds {
              Alt+Shift+E      { quit; }
              Alt+Shift+Q      { close-window; }

              Alt+Space        { spawn "noctalia-shell" "ipc" "call" "launcher" "toggle"; }
              Alt+Return       { spawn "wezterm"; }

              Alt+1            { focus-workspace 1; }
              Alt+2            { focus-workspace 2; }
              Alt+3            { focus-workspace 3; }
              Alt+4            { focus-workspace 4; }
              Alt+5            { focus-workspace 5; }
              Alt+6            { focus-workspace 6; }
              Alt+7            { focus-workspace 7; }
              Alt+8            { focus-workspace 8; }
              Alt+9            { focus-workspace 9; }

              Alt+Shift+1      { move-column-to-workspace 1; }
              Alt+Shift+2      { move-column-to-workspace 2; }
              Alt+Shift+3      { move-column-to-workspace 3; }
              Alt+Shift+4      { move-column-to-workspace 4; }
              Alt+Shift+5      { move-column-to-workspace 5; }
              Alt+Shift+6      { move-column-to-workspace 6; }
              Alt+Shift+7      { move-column-to-workspace 7; }
              Alt+Shift+8      { move-column-to-workspace 8; }
              Alt+Shift+9      { move-column-to-workspace 9; }

              Alt+H            { focus-column-left; }
              Alt+L            { focus-column-right; }
              Alt+J            { focus-window-down; }
              Alt+K            { focus-window-up; }
              Alt+Left         { focus-column-left; }
              Alt+Right        { focus-column-right; }
              Alt+Down         { focus-window-down; }
              Alt+Up           { focus-window-up; }

              Alt+Shift+H      { move-column-left; }
              Alt+Shift+L      { move-column-right; }
              Alt+Shift+J      { move-window-down; }
              Alt+Shift+K      { move-window-up; }
              Alt+Shift+Left   { move-column-left; }
              Alt+Shift+Right  { move-column-right; }
              Alt+Shift+Down   { move-window-down; }
              Alt+Shift+Up     { move-window-up; }

              Alt+U            { set-column-width "-2%"; }
              Alt+P            { set-column-width "+2%"; }
              Alt+I            { set-window-height "-2%"; }
              Alt+O            { set-window-height "+2%"; }

              Alt+F            { fullscreen-window; }
              Alt+Shift+Space  { toggle-window-floating; }

              Alt+V            { toggle-column-tabbed-display; }
              Alt+T            { toggle-window-floating; }

              Alt+Shift+A      { move-workspace-to-monitor-left; }
              Alt+Shift+F      { move-workspace-to-monitor-right; }
              Alt+Shift+D      { move-workspace-to-monitor-up; }
              Alt+Shift+S      { move-workspace-to-monitor-down; }

              Alt+S            { focus-workspace-down; }
              Alt+A            { focus-workspace-up; }
              Alt+D            { focus-workspace-previous; }

              XF86AudioRaiseVolume allow-when-locked=true { spawn "wpctl" "set-volume" "-l" "1" "@DEFAULT_AUDIO_SINK@" "5%+"; }
              XF86AudioLowerVolume allow-when-locked=true { spawn "wpctl" "set-volume" "@DEFAULT_AUDIO_SINK@" "5%-"; }
              XF86AudioMute        allow-when-locked=true { spawn "wpctl" "set-mute" "@DEFAULT_AUDIO_SINK@" "toggle"; }
              XF86AudioMicMute     allow-when-locked=true { spawn "wpctl" "set-mute" "@DEFAULT_AUDIO_SOURCE@" "toggle"; }
              XF86MonBrightnessUp                          { spawn "brightnessctl" "-e4" "-n2" "set" "5%+"; }
              XF86MonBrightnessDown                        { spawn "brightnessctl" "-e4" "-n2" "set" "5%-"; }
              XF86AudioNext        allow-when-locked=true { spawn "playerctl" "next"; }
              XF86AudioPrev        allow-when-locked=true { spawn "playerctl" "previous"; }
              XF86AudioPlay        allow-when-locked=true { spawn "playerctl" "play-pause"; }
              XF86AudioPause       allow-when-locked=true { spawn "playerctl" "play-pause"; }

              Print            { screenshot; }
              Ctrl+Print       { screenshot-screen; }
              Alt+Print        { screenshot-window; }
          }
        '';
      };
  };
}
