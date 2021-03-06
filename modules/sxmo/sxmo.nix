{config, options, lib, pkgs, ...}:

let
  sxmopkgs = import ../../default.nix { inherit pkgs; };
  sxmoutils = (sxmopkgs.sxmo-utils.overrideAttrs (oldAttrs: rec { passthru.providedSessions = [ "sxmo" ]; }));
  dmcfg = config.services.xserver.desktopManager;
in
{
  imports = [ ./common.nix ];
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
     autocutsel # sxmo runs this to keep the cutbuffer and clipboard in sync
     sxmopkgs.sxmo-dwm
     sxmopkgs.sxmo-dmenu
     svkbd
     xdotool
     xprintidle
     conky # Used for clock
     clickclack # for keyboard feedback
     xorg.xmodmap
     feh
     unclutter-xfixes
     dunst
     gnome-icon-theme  # dunst needs these
     sxmopkgs.sxmo-st
     xsel
     xclip
   ] ++ lib.optionals dmcfg.sxmo.installScriptDeps [
     scrot
   ];

   # Define session
   services.xserver.displayManager.sessionPackages = [ sxmoutils  ];
 };
}
