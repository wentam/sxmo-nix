{config, options, lib, pkgs, ...}:

let
  sxmopkgs = import ../../default.nix { inherit pkgs; };
  dmcfg = config.services.xserver.desktopManager;
in
{
  options = {
    services.xserver.desktopManager.sxmo = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "";
      };
    };
    services.xserver.desktopManager.sxmo.package = lib.mkOption {
      type = lib.types.package;
      default = sxmopkgs.sxmo-utils;
      description = "sxmo-utils package to use";
    };
  };

  config = lib.mkIf config.services.xserver.desktopManager.sxmo.enable {
    environment.systemPackages = [ dmcfg.sxmo.package sxmopkgs.superd ];

    services.udev.packages = [ dmcfg.sxmo.package ];  # Install udev rules
    fonts.fonts = [ pkgs.nerdfonts ];                  # Sxmo uses nerdfonts for it's icons
    powerManagement.enable = lib.mkDefault true;       # For suspend
    services.xserver.libinput.enable = lib.mkDefault true;

    # Needed for sxmo to find it's hooks/superd services, and for the user's
    # local sxmo configuration to reference resources without needing to migrate
    # for every single nix store path change.
    environment.pathsToLink = [ "/share" ];

    services.xserver.displayManager.sessionPackages = [ dmcfg.sxmo.package ];

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
     permit nopass :wheel as root cmd rtcwake
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
