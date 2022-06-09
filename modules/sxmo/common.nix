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
      libnotify
      inotify-tools
      xdg-user-dirs
      autocutsel
      light # for adjusting backlight
      sxmopkgs.sxmo-utils
      sxmopkgs.superd
      busybox
      lisgd
      pn
      gojq
      doas
      sxmopkgs.mnc # for scheduling suspend wakeups for cron
    ] ++ lib.optionals dmcfg.sxmo.installScriptDeps [
      sxmopkgs.codemadness-frontends
      sfeed
      libxml2
      youtube-dl
      sxiv
      mediainfo
    ] ++ lib.optionals dmcfg.sxmo.mms.enable [
      sxmopkgs.mmsd-tng
    ] ++ lib.optionals config.sound.enable [
      callaudiod
      mpv # used to play system sounds
    ] ++ lib.optionals config.hardware.pulseaudio.enable [
      pamixer
    ];

    # Install udev rules
    services.udev.packages = [ sxmopkgs.sxmo-utils ];

    # We need nerdfonts for all of sxmo's icons to work.
    fonts.fonts = [ pkgs.nerdfonts ];

    powerManagement.enable = lib.mkDefault true;

    # TODO: We currently need this for sxmo to find it's hooks/superd services,
    # and for the user's local configuration to reference sxmo things without
    # needing to migrate for every nix store path change.
    #
    # I don't see any easy way around it, but it'd be nice if it wasn't necessary 
    environment.pathsToLink = [ "/share" ];

    services.xserver.libinput.enable = lib.mkDefault true;

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
    # TODO: This change could apply to other sessions. It'd better find a way to do this at session start.
    services.logind.extraConfig = lib.mkDefault ''
       HandlePowerKey=ignore
    '';

    # Sxmo uses doas to run these commands as root. We need to allow that.
    # sxmo-utils provides this config, but we shouldn't ask the application
    # what the application is permitted to run as root :)
    #
    # As such, we maintain it here.
    #
    # Note: this allows *any wheel user* to run these commands as root without a password.
    # This isn't too bad, because generally it's intended that wheel users have access
    # to the root account in some way.
    #
    # TODO: this requires that the sxmo user be in wheel.
    # This means, for example, that any non-wheel user can't shut down the device or toggle wifi.
    # It may be better to split this up into more specific groups, perhaps:
    # sessionctl,rfctl,powerctl
    #
    # Downside is that this would need to be specifically documented for any users of the module,
    # as these groups are not a standard sxmo thing.
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
    security.doas.enable = true;

    # sxmo uses rtcwake to suspend the system, we need
    # setuid to give it access
    # TODO: maybe better to require a 'suspend' group?
    security.wrappers."rtcwake" = {
      setuid = true;
      source = "${pkgs.util-linux}/bin/rtcwake";
      owner  = "root";
      group  = "wheel";
    };

  };
}
