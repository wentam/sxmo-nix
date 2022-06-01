{config, options, lib, pkgs, ...}:

let
  sxmopkgs = import ../../default.nix { inherit pkgs; };
  sxmoutils = (sxmopkgs.sxmo-utils.overrideAttrs (oldAttrs: rec { passthru.providedSessions = [ "sxmo" ]; }));

  # unclutter-xfixes calls it's binary 'unclutter'.
  # We need both unclutter and unclutter-xfixes binaries. sxmo expects both!
  unclutter-xfixes-extrabin = pkgs.unclutter-xfixes.overrideAttrs (oldAttrs: {
    postInstall = ''
      ln -s $out/bin/unclutter $out/bin/unclutter-xfixes
    '';
  });
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
     sxmopkgs.sxmo-dwm
     sxmopkgs.sxmo-dmenu
     svkbd
     xdotool
     xprintidle
     conky # Used for clock
     clickclack # for keyboard feedback
     xorg.xmodmap
     feh
     unclutter-xfixes-extrabin
     dunst
     gnome-icon-theme  # dunst needs these
     sxmopkgs.sxmo-st
   ];

   services.xserver.libinput.enable = lib.mkDefault true;

   # Define session
   services.xserver.displayManager.sessionPackages = [ sxmoutils  ];
 };
}
