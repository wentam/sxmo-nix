# sxmo-nix

Packaging Sxmo/Swmo for NixOS with a goal of upstreaming to nixpkgs.

See also: https://git.sr.ht/~noneucat/nur-packages

# Usage

```nix
{
  imports = [
    ./sxmo-nix/modules/sxmo/swmo.nix #
    ./sxmo-nix/modules/sxmo/sxmo.nix #
    ./sxmo-nix/modules/tinydm        # Or wherever they're located
  ];

  services.xserver = {
    enable = true;
    desktopManager.swmo.enable = true; # Wayland
    desktopManager.sxmo.enable = true; # X11

    displayManager = {
      tinydm.enable = true;    # power->toggle WM in sxmo only works with tinytm
      autoLogin.enable = true;
      autoLogin.user = "[your_user]";
      defaultSession = "swmo"; # Or sxmo for X session
    };
  };
}
```

# Notes
* You must use tinydm if you want menu->power->toggle WM to work. It may be worth looking into providing alternative hooks for other DMS later on though!
* Your user must be in group 'wheel' for sxmo's power off, wifi toggle, bluetooth toggle, modem toggle fetaures to work
* If sxmo doesn't have a profile for your device, you'll need to [patch one in.](https://git.sr.ht/~mil/sxmo-utils/tree/master/item/scripts/deviceprofiles) Also consider upstreaming to sxmo!

# Debugging tips
* If you're using tinydm, ~/.local/state/tinydm.log contains sxmo's output

# Donations
Much of my time is volunteered towards open-source projects to improve the free software ecosystem
for all.

[You can support my work here](https://liberapay.com/wentam) :+1:.
