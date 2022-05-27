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
     # Give any previous sessions a chance to fully close. This makes auto-restart much more reliable.
     # TODO: there's probably a better solution for this
     ${pkgs.busybox}/bin/sleep 3
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

   # Oneshot service that clears our session on boot (and on nixos-rebuild) such that the next service
   # start runs the default session
   #
   # Tinydm users can change their session with tinydm-set-session, so we don't want to force the default
   # on every DM start (sxmo uses this, for example.)
   #
   # If the user has not yet defined a service, DM start will still write the default without a reboot.
   systemd.services.tinydm-setup = {
     description = "Tinydm setup";
     wantedBy = [ "multi-user.target" ];

     serviceConfig = {
       Type = "oneshot";
       StateDirectory = "/var/lib/tinydm/";
       User = "root";
       Group = "root";
       ExecStart = ''${pkgs.busybox}/bin/rm -f /var/lib/tinydm/default-session.desktop'';
     };
   };

   # Set default session on DM start if we don't have a session defined
   services.xserver.displayManager.job.preStart = ''
     if [ ! -e /var/lib/tinydm/default-session.desktop ]; then
       if [ -e ${xsession_path}/${dmcfg.defaultSession}.desktop ]; then
         ${sxmopkgs.tinydm}/bin/tinydm-set-session -f -s ${xsession_path}/${dmcfg.defaultSession}.desktop
       fi

       if [ -e ${wsession_path}/${dmcfg.defaultSession}.desktop ]; then
         ${sxmopkgs.tinydm}/bin/tinydm-set-session -f -s ${wsession_path}/${dmcfg.defaultSession}.desktop
       fi
       chmod -R 777 /var/lib/tinydm # TODO: use a group, or perhaps make it owned by the autologin user.
     fi
   '';

   # tinydm uses startx for X sessions
   services.xserver.displayManager.startx.enable = true;

   systemd.services.display-manager.after = [ "getty@tty1.service" "systemd-user-sessions.service" ];
   systemd.services.display-manager.conflicts = [ "getty@tty1.service" ];

   services.xserver.displayManager.job.execCmd = ''
     exec ${sxmopkgs.autologin}/bin/autologin ${dmcfg.autoLogin.user} /run/current-system/sw/bin/sh ${tinydm-run}
   '';
 };
}
