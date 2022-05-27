{config, options, lib, pkgs, ...}:

{
  imports = [ ./sxmo.nix ./swmo.nix ];
  config = lib.mkIf (config.services.xserver.desktopManager.swmo.enable || 
                     config.services.xserver.desktopManager.sxmo.enable) {
    environment.systemPackages = with pkgs; [
      libnotify
      mpv
      pamixer # TODO: only needed if pulse?
      swayidle
      xdg-user-dirs
      autocutsel
      callaudiod
      dunst
      mako
      wob
      conky
    ];

    powerManagement.enable = true;

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
