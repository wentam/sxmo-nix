{config, options, lib, pkgs, ...}:

let
  sxmopkgs = import ../../default.nix { inherit pkgs; };
in
{
  config = lib.mkIf (config.services.xserver.desktopManager.swmo.enable || 
                     config.services.xserver.desktopManager.sxmo.enable) {
    environment.systemPackages = with pkgs; [
      libnotify
      inotify-tools
      (lib.mkIf config.sound.enable mpv) # used to play system sounds
      (lib.mkIf config.hardware.pulseaudio.enable pamixer)
      xdg-user-dirs
      autocutsel
      (lib.mkIf config.sound.enable callaudiod)
      dunst
      light # for adjusting backlight
      sxmopkgs.sxmo-utils
      sxmopkgs.sxmo-st
      sxmopkgs.superd
      busybox
      lisgd
      pn
      gojq
      doas
    ];

    # We need nerdfonts for all of sxmo's icons to work.
    fonts.fonts = [ pkgs.nerdfonts ];

    powerManagement.enable = lib.mkDefault true;

    # TODO: hack to get sxmo to find it's hooks/superd services
    environment.pathsToLink = [ "/share" ];

    services.xserver.libinput.enable = lib.mkDefault true;

    environment.variables.TERMCMD = lib.mkDefault "st";

   # Power button shouldn't immediately power off the device
   # TODO: This change could apply to other sessions. It'd better find a way to do this at session start.
   services.logind.extraConfig = ''
       HandlePowerKey=ignore
   '';

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
