{config, options, lib, pkgs, ...}:

let
  sxmopkgs = import ../../default.nix { inherit pkgs; };
  sxmoutils = (sxmopkgs.sxmo-utils.overrideAttrs (oldAttrs: rec { passthru.providedSessions = [ "sxmo" ]; }));
in
{
  imports = [];
  options = {
    services.xserver.desktopManager.sxmo = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "";
      };
    };
 };

 config = lib.mkIf config.services.xserver.desktopManager.sxmo.enable {
   environment.systemPackages = with pkgs; [
     sxmoutils
     sxmopkgs.sxmo-dwm
     sxmopkgs.sxmo-st
     sxmopkgs.sxmo-dmenu
     sxmopkgs.superd
     busybox
     lisgd
     svkbd
     inotify-tools
     pn
     gojq
     xdotool
   ];

   fonts.fonts = [ pkgs.nerdfonts ];

  # TODO: hack to get sxmo to find it's hooks/superd services
  environment.pathsToLink = [ "/share" ];

  libinput.enable = true; 

   environment.variables.TERMCMD = "st"; # TODO: does X11 sxmo use this var?

   # Power button shouldn't immediately power off the device
   # TODO: This change could apply to other sessions. It'd better find a way to do this at session start.
   services.logind.extraConfig = ''
       HandlePowerKey=ignore
   '';

   # Install udev rules
   services.udev.packages = [ sxmoutils ];

   # Define session
   services.xserver.displayManager.sessionPackages = [ sxmoutils  ];
 };
}
