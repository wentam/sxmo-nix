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
  };
}
