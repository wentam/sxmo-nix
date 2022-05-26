{config, options, lib, pkgs, ...}:

let
  sxmopkgs = import ../../default.nix { inherit pkgs; };
  sxmoutils = (sxmopkgs.sxmo-utils.overrideAttrs (oldAttrs: rec { passthru.providedSessions = [ "swmo" ]; }));
in
{
  imports = [];
  options = {
    services.xserver.desktopManager.swmo = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "";
      };
    };
 };

 config = lib.mkIf config.services.xserver.desktopManager.swmo.enable {
   environment.systemPackages = with pkgs; [
     sxmoutils
     sxmopkgs.sxmo-st
     sxmopkgs.superd
     sway
     busybox
     bemenu
     lisgd
     inotify-tools
     pn
     wvkbd
     gojq
   ];

   fonts.fonts = [ pkgs.nerdfonts ];

   programs.sway = {
     enable = true;
     wrapperFeatures.gtk = true; # so that gtk works properly
     extraPackages = with pkgs; [];
   };

   # Set default sway config to the sxmo template
   environment.etc."sway/config".source = "${sxmopkgs.sxmo-utils}/share/sxmo/appcfg/sway_template";

   # TODO: hack to get sxmo to find it's hooks/superd services
   environment.pathsToLink = [ "/share" ];

   libinput.enable = true;

   # $TERMCMD used by the sxmo sway template config
   environment.variables.TERMCMD = "st";

   # Power button shouldn't immediately power off the device
   # TODO: This change could apply to other sessions. It'd better find a way to do this at session start.
   services.logind.extraConfig = ''
       HandlePowerKey=ignore
   '';

   # Install udev rules
   services.udev.packages = [ sxmoutils ];

   # Define session
   services.xserver.displayManager.sessionPackages = [ sxmoutils ];
 };
}
