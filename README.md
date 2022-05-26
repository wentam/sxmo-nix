# sxmo-nix

Packaging sxmo/swmo for nixOS with a hope of eventually upstreaming to nixpkgs.

See also: https://git.sr.ht/~noneucat/nur-packages

# Usage

```nix
{
  imports = [
    ./sxmo-nix/modules/swmo   #
    ./sxmo-nix/modules/sxmo   #
    ./sxmo-nix/modules/tinydm # Or wherever they're located
  ];

  services.xserver = {
    enable = true;
    desktopManager.swmo.enable = true; # Wayland
    desktopManager.sxmo.enable = true; # X11

    displayManager = {
      tinydm.enable = true;
      autoLogin.enable = true;
      autoLogin.user = "[your_user]";
      defaultSession = "swmo"; # Or sxmo for X session
    };
  };
}
```
