{config, options, lib, pkgs, ...}:

with lib;

let
  sxmopkgs = import ../../default.nix { inherit pkgs; };
in
{
  imports = [];
  options = {
    programs.autologin = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "";
      };
    };
 };

 config = lib.mkIf config.programs.autologin.enable {
   environment.systemPackages = [ sxmopkgs.autologin ];

   security.pam.services."autologin" = {
     startSession = true;
     allowNullPassword = true;
     showMotd = true;
     updateWtmp = true;
   };
 };
}
