{config, options, lib, pkgs, ...}:

{
  config = lib.mkIf (config.services.xserver.desktopManager.swmo.enable || 
                     config.services.xserver.desktopManager.sxmo.enable) {
    environment.systemPackages = with pkgs; [
      libnotify
      mpv # used to play system sounds
      (lib.mkIf config.hardware.pulseaudio.enable pamixer)
      xdg-user-dirs
      autocutsel
      callaudiod
      dunst
      light # for adjusting backlight
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
