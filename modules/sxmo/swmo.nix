{config, options, lib, pkgs, ...}:

let
  sxmopkgs = import ../../default.nix { inherit pkgs; };
  sxmoutils = (sxmopkgs.sxmo-utils.overrideAttrs (oldAttrs: rec { passthru.providedSessions = [ "swmo" ]; }));
in
{
  imports = [ ./common.nix ];
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
     sway
     bemenu
     wvkbd
     swayidle
     wob
     mako
     sxmopkgs.wayout
     foot
   ];

   programs.sway = {
     enable = true;
     wrapperFeatures.gtk = true; # so that gtk works properly
     extraPackages = with pkgs; [];
   };

   # Set default sway config to the sxmo template
   environment.etc."sway/config".source = lib.mkDefault "${sxmopkgs.sxmo-utils}/share/sxmo/appcfg/sway_template";

   # Define session
   services.xserver.displayManager.sessionPackages = [ sxmoutils ];
 };
}
