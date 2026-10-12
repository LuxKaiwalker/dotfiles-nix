{ config, pkgs, lib, ... }:

let
  sharedSessionVariables = {
    FLUTTER_HOME = "/home/vincent/flutter";
    JAVA_HOME = "/usr/lib/jvm/java-17-openjdk";
    EDITOR = "nvim";
    VISUAL = "nvim";
    SUDO_EDITOR = "nvim";
  };
in
{
  home.username = "vincent";
  home.homeDirectory = "/home/vincent";
  home.stateVersion = "26.05";

  xdg.enable = true;

  nixpkgs.config.allowUnfree = true;

  home.sessionVariables = sharedSessionVariables;

    gtk = {
    enable = true;

    theme = {
      name = "Adwaita-dark";
      package = pkgs.gnome-themes-extra;
    };

    iconTheme = {
      name = "Adwaita";
      package = pkgs.adwaita-icon-theme;
    };

    cursorTheme = {
      name = "Adwaita";
      package = pkgs.adwaita-icon-theme;
    };

    gtk3.extraConfig = {
      gtk-application-prefer-dark-theme = 1;
    };

    gtk4.extraConfig = {
      gtk-application-prefer-dark-theme = 1;
    };
  };

  qt = {
    enable = true;
    platformTheme.name = "gtk";
    style.name = "Adwaita-dark";
  };

  dconf = {
    enable = true;

    settings."org/gnome/desktop/interface" = {
      color-scheme = "prefer-dark";
    };
  };

  home.packages = with pkgs; [
    btop-cuda
    brightnessctl
    cliphist
    discord
    firefox
    gsimplecal
    git
    jq
    kitty
    nemo
    pavucontrol
    procps
    wl-clipboard
  ];

  # SUPER+A waybar toggle (see hypr/hyprland.conf); hl.bind'd directly in
  # Lua on the Arch side (~/coding/dotfiles/hypr/conf/statusbar.lua), but
  # hyprlang has no scripting of its own, so this hands the script to
  # hyprctl exec via home.file instead.
  home.file.".local/bin/waybar-toggle" = {
    source = ./hypr/waybar-toggle.sh;
    executable = true;
  };

  programs.home-manager.enable = true;

  programs.bash = {
    enable = true;

    shellAliases = {
      ls = "ls --color=auto";
      grep = "grep --color=auto";
    };

    initExtra = ''
      export PATH="$FLUTTER_HOME/bin:$FLUTTER_HOME/bin/cache/dart-sdk/bin:$JAVA_HOME/bin:$HOME/bin:$HOME/.local/bin:$PATH"

      if [ -s "$HOME/.nvm/nvm.sh" ]; then
        . "$HOME/.nvm/nvm.sh"
      fi

      if [ -f "$HOME/.ghcup/env" ]; then
        . "$HOME/.ghcup/env"
      fi
    '';
  };

  programs.fish = {
    enable = true;

    shellAliases = {
      ls = "ls --color=auto";
      grep = "grep --color=auto";
    };

    interactiveShellInit = ''
      set -gx PATH $FLUTTER_HOME/bin $FLUTTER_HOME/bin/cache/dart-sdk/bin $JAVA_HOME/bin $HOME/bin $HOME/.local/bin $PATH

      set -g fish_greeting
    '';
  };

  programs.neovim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;

    initLua = builtins.readFile ./nvim/init.lua;
  };

  wayland.windowManager.hyprland = {
    enable = true;
    configType = "hyprlang";
    systemd.enable = true;

    extraConfig = builtins.readFile ./hypr/hyprland.conf;
  };

  services.hyprpolkitagent.enable = true;

  programs.waybar = {
    enable = true;

    settings = {
      mainBar = {
        layer = "top";
        position = "left";
        width = 36;
        margin-top = 0;
        margin-bottom = 0;
        margin-left = 0;
        margin-right = 0;
        spacing = 0;

        "modules-left" = [ "hyprland/workspaces" ];
        "modules-center" = [ "hyprland/window" ];
        "modules-right" = [
          "cpu"
          "network"
          "bluetooth"
          "wireplumber"
          "clock"
          "custom/power"
        ];

        "hyprland/workspaces" = {
          orientation = "vertical";
          format = "●";
          "on-click" = "activate";
          all-outputs = false;
          "sort-by-number" = true;

          "persistent-workspaces" = {
            "HDMI-A-1" = [ 1 2 3 4 5 ];
            "DP-1" = [ 6 7 8 9 10 ];
          };
        };

        "hyprland/window" = {
          rotate = 90;
          tooltip = true;
        };

        cpu = {
          format = "";
          rotate = 90;
          "on-click" = "kitty -e btop";
          "tooltip-format" = "CPU usage: {usage}%";
        };
                
        network = {
          "format-wifi" = "";
          "format-ethernet" = "󰈀";
          rotate = 90;
          "on-click" = "kitty -e nmtui";
          "tooltip-format-wifi" = "{essid} {signalStrength}%";
          "tooltip-format-ethernet" = "Ethernet: {ifname}";
          "tooltip-format-disconnected" = "No network connected";
        };

        bluetooth = {
          format = "";
          rotate = 90;
          "on-click" = "kitty --title 'bluetui-float' -e bluetui";
          "tooltip-format" = "{status} {device_enumerate}";
        };

        wireplumber = {
          format = "{icon}";
          rotate = 90;
          "format-icons" = [ "" "" "" ];
          "on-click" = "pavucontrol";
          "tooltip-format" = "{volume}%";
        };

        clock = {
          format = "{:%H:%M}";
          rotate = 90;
          "on-click" = "gsimplecal";
          "tooltip-format" = "{:%A, %B %d, %Y}";
        };

        "custom/power" = {
          format = "";
          "on-click" = "wlogout";
          tooltip = false;
        };
      };
    };

    style = builtins.readFile ./waybar/style.css;
  };

  services.mako = {
    enable = true;

    settings = {
      font = "Cozette 11";
      format = "<b>%a ⏵</b> %s\n%b";
      sort = "-time";
      output = "DP-2";
      layer = "overlay";
      anchor = "bottom-left";
      background-color = "#2e344080";
      width = 300;
      height = 110;
      margin = 5;
      padding = "0,5,10";
      border-size = 2;
      border-color = "#88c0d0";
      border-radius = 15;
      icons = 0;
      max-icon-size = 64;
      default-timeout = 10000;
      ignore-timeout = 1;

      "urgency=normal" = {
        border-color = "#d08770";
      };

      "urgency=high" = {
        border-color = "#bf616a";
        default-timeout = 0;
      };

      "app-name=lightcord" = {
        border-color = "#88c0d0";
      };

      "summary~=\"log-.*\"" = {
        border-color = "#a3be8c";
      };

      "app-name=lightcord summary~=\"(.*(^| )orz|ORZ|sto|STO|otl|OTL( |$).*)\"" = {
        invisible = 1;
      };

      "app-name=Firefox" = {
        invisible = 1;
      };
    };
  };

  programs.wofi = {
    enable = true;

    settings = {
      width = 400;
      height = 300;
      location = "center";
      show = "drun";
      prompt = "Type to search...";
      filter_rate = 100;
      allow_markup = true;
      no_actions = true;
      halign = "fill";
      content_halign = "fill";
      insensitive = true;
      allow_images = true;
      image_size = 24;
    };

    style = builtins.readFile ./wofi/style.css;
  };

    programs.wlogout = {
    enable = true;

    layout = [
      {
        label = "lock";
        action = "hyprlock";
        text = "";
      }
      {
        label = "logout";
        action = "hyprctl dispatch exit";
        text = "";
      }
      {
        label = "suspend";
        action = "systemctl suspend";
        text = "";
      }
      {
        label = "hibernate";
        action = "systemctl hibernate";
        text = "";
      }
      {
        label = "reboot";
        action = "systemctl reboot";
        text = "";
      }
      {
        label = "shutdown";
        action = "systemctl poweroff";
        text = "";
      }
    ];

    style = builtins.readFile ./wlogout/style.css;
  };

  programs.hyprlock = {
    enable = true;

    extraConfig = builtins.readFile ./hypr/hyprlock.conf;
  };
}