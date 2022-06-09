{config, options, lib, pkgs, ...}:

let
  sxmopkgs = import ../../default.nix { inherit pkgs; };
  dmcfg = config.services.xserver.desktopManager;
in
{
  options = {
    services.xserver.desktopManager.sxmo.mms = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Enables MMS support within sxmo/swmo (installs mmsd-tng)";
      };
    };
    services.xserver.desktopManager.sxmo.installScriptDeps = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Puts the dependencies needed for sxmo's builtin scripts into environment.systemPackages.";
    };
  };

  config = lib.mkIf (config.services.xserver.desktopManager.swmo.enable || 
                     config.services.xserver.desktopManager.sxmo.enable) {
    environment.systemPackages = with pkgs; [
      libnotify     # For sending desktop notifications
      inotify-tools
      xdg-user-dirs # Used for xdg-user-dirs-update to create XDG user
                    # directories such as ~/Pictures

      light         # Used to adjust backlight
      sxmopkgs.sxmo-utils # Sxmo's main repo
      sxmopkgs.superd     # Sxmo manages it's services with superd
      busybox      # Sxmo sometimes uses busybox directly with 'busybox [thing]'
      lisgd        # Sxmo's gesture daemon
      pn           # Phone number parsing/formatting/validation
      gojq         # Used for parsing purposes throughout sxmo
      doas         # Used to run certain commands with root privileges
      sxmopkgs.mnc # Used to schedule suspend wakeups for cron
      lsof
      bc
      dbus         # dbus-run-session
      file
      curl
    ] ++ lib.optionals dmcfg.sxmo.installScriptDeps [
      sxmopkgs.codemadness-frontends # reddit-cli and youtube-cli for sxmo_[reddit|youtube].sh
      sfeed      # For sxmo_rss.sh
      libxml2    # For sxmo_weather.sh
      youtube-dl # For sxmo_youtube.sh
      sxiv       # To view images with the file browser and sxmo_open.sh
      mediainfo  # For sxmo_record.sh
      gawk
    ] ++ lib.optionals dmcfg.sxmo.mms.enable [
      sxmopkgs.mmsd-tng # For MMS support
    ] ++ lib.optionals config.sound.enable [
      alsaUtils
      callaudiod # For phone call audio routing
      mpv        # Used to play system sounds (notification ding etc)
    ] ++ lib.optionals config.hardware.pulseaudio.enable [
      pamixer # Used to adjust volume if you're running pulseaudio
    ];

    services.udev.packages = [ sxmopkgs.sxmo-utils ];  # Install udev rules
    fonts.fonts = [ pkgs.nerdfonts ];                  # Sxmo uses nerdfonts for it's icons
    powerManagement.enable = lib.mkDefault true;       # For suspend
    services.xserver.libinput.enable = lib.mkDefault true;

    # Needed for sxmo to find it's hooks/superd services, and for the user's
    # local sxmo configuration to reference resources without needing to migrate
    # for every single nix store path change.
    environment.pathsToLink = [ "/share" ];

    # For sxmo scripts to work over ssh etc, we need these vars defined
    environment.variables.XDG_CONFIG_HOME = lib.mkDefault "$HOME/.config";
    environment.variables.XDG_DATA_HOME   = lib.mkDefault "$HOME/.local/share";
    environment.variables.XDG_CACHE_HOME  = lib.mkDefault "$HOME/.cache";
    environment.variables.XDG_BIN_HOME    = lib.mkDefault "$HOME/.local/bin";
    environment.variables.PATH = [
      "${config.environment.variables.XDG_BIN_HOME}"
      "${config.environment.variables.XDG_CONFIG_HOME}/sxmo/hooks/"
      "${sxmopkgs.sxmo-utils}/share/sxmo/default_hooks/"
    ];

    # Power button shouldn't immediately power off the device
    # (sxmo uses it for menus etc)
    services.logind.extraConfig = lib.mkDefault ''
       HandlePowerKey=ignore
    '';

    # Sxmo uses doas to run these commands as root. We need to allow that.
    # sxmo-utils provides this config, but we shouldn't ask the application
    # what the application is permitted to run as root :)
    #
    # As such, we maintain it here.
    #
    # Note: this allows *any wheel user* to run the commands prefixed with 'nopass' here
    # as root without a password. This isn't too bad, because generally it's intended
    # that wheel users have access to the root account in some way.
    security.doas.enable = true;
    security.doas.extraConfig = ''
     permit persist :wheel
     permit nopass :wheel as root cmd busybox args poweroff
     permit nopass :wheel as root cmd busybox args reboot
     permit nopass :wheel as root cmd poweroff
     permit nopass :wheel as root cmd systemctl args poweroff
     permit nopass :wheel as root cmd reboot
     permit nopass :wheel as root cmd sxmo_wifitoggle.sh
     permit nopass :wheel as root cmd sxmo_bluetoothtoggle.sh
     permit nopass :wheel as root cmd systemctl args restart bluetooth
     permit nopass :wheel as root cmd tinydm-set-session
     permit nopass :wheel as root cmd systemctl args start eg25-manager
     permit nopass :wheel as root cmd systemctl args stop eg25-manager
     permit nopass :wheel as root cmd systemctl args start ModemManager
     permit nopass :wheel as root cmd systemctl args stop ModemManager
     permit setenv { NIX_PATH } :wheel as root cmd nohup args nixos-rebuild switch --upgrade
    '';

    # Sxmo uses rtcwake to suspend the system, we need
    # setuid to give it access
    security.wrappers."rtcwake" = {
      setuid = true;
      source = "${pkgs.util-linux}/bin/rtcwake";
      owner  = "root";
      group  = "wheel";
    };
  };
}
