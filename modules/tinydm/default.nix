{config, options, lib, pkgs, ...}:

with lib;

let
  sxmopkgs = import ../../default.nix { inherit pkgs; };
  dmcfg = config.services.xserver.displayManager;
  tinydm-run = pkgs.writeText "tinydm-run-session-wrapper.sh" ''
     export TINYDM_WAYLAND_SESSION_PATH="${dmcfg.sessionData.desktops}/share/wayland-sessions/"
     export TINYDM_XSESSION_PATH="${dmcfg.sessionData.desktops}/share/xsessions/"
     export TINYDM_X11_PROFILE_PATH="/var/empty/"
     export TINYDM_WAYLAND_PROFILE_PATH="/var/empty/"
     exec ${sxmopkgs.tinydm}/bin/tinydm-run-session
  '';
  xsession_path = "${dmcfg.sessionData.desktops}/share/xsessions/";
  wsession_path = "${dmcfg.sessionData.desktops}/share/wayland-sessions/";
in
{
  imports = [
    ../autologin 
  ];
  options = {
    services.xserver.displayManager.tinydm = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "";
      };
    };
 };

 config = lib.mkIf config.services.xserver.displayManager.tinydm.enable {

   assertions = [
     {
       assertion = config.services.xserver.enable;
       message = ''
         TinyDM requires services.xserver.enable to be true.
       '';
     }
     {
       assertion = dmcfg.autoLogin.enable;
       message = ''
         TinyDM requires services.xserver.displayManager.autoLogin.enable to be true.
       '';
     }
     {
       assertion = dmcfg.autoLogin.enable -> dmcfg.sessionData.autologinSession != null;
       message = ''
         TinyDM auto-login requires services.xserver.displayManager.defaultSession to be set.
       '';
     }
   ];

   # TODO nixpkgs/nixos/modules/services/x11/xserver.nix turns this off if we're not a recognized DM
   # (this is so that startx etc can work manually).
   #
   # It will also default us to lightdm because we are not recognized
   #
   # If upstreaming, update xserver.nix and remove these.
   systemd.services.display-manager.enable = true;
   services.xserver.displayManager.lightdm.enable = false;

   programs.autologin.enable = true;

   environment.systemPackages = [ sxmopkgs.tinydm ];

   # Set default session
   services.xserver.displayManager.job.preStart = ''
     if [ -e ${xsession_path}/${dmcfg.defaultSession}.desktop ]; then
       ${sxmopkgs.tinydm}/bin/tinydm-set-session -f -s ${xsession_path}/${dmcfg.defaultSession}.desktop
     fi

     if [ -e ${wsession_path}/${dmcfg.defaultSession}.desktop ]; then
       ${sxmopkgs.tinydm}/bin/tinydm-set-session -f -s ${wsession_path}/${dmcfg.defaultSession}.desktop
     fi
   '';

   # tinydm uses startx for X sessions
   services.xserver.displayManager.startx.enable = true;

   # Set up environment for our (patched) tinydm
   /*services.xserver.displayManager.job.environment = {
     TINYDM_WAYLAND_SESSION_PATH = "${dmcfg.sessionData.desktops}/share/wayland-sessions/";
     TINYDM_XSESSION_PATH="${dmcfg.sessionData.desktops}/share/xsessions/";
     TINYDM_X11_PROFILE_PATH="/var/empty/";
     TINYDM_WAYLAND_PROFILE_PATH="/var/empty/";
   };*/

   systemd.services.display-manager.after = [ "getty@tty1.service" "systemd-user-sessions.service" ];
   systemd.services.display-manager.conflicts = [ "getty@tty1.service" ];

   services.xserver.displayManager.job.execCmd = ''
     exec ${sxmopkgs.autologin}/bin/autologin ${dmcfg.autoLogin.user} /run/current-system/sw/bin/sh ${tinydm-run}
   '';
 };
}
