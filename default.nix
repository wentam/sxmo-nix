{ pkgs ? import <nixpkgs> { } }:

rec {
  lib = import ./lib { inherit pkgs; }; # functions
  modules = import ./modules; # NixOS modules
  overlays = import ./overlays; # nixpkgs overlays

  sxmo-dwm    = pkgs.callPackage ./pkgs/sxmo-dwm {};
  sxmo-st     = pkgs.callPackage ./pkgs/sxmo-st {};
  sxmo-dmenu  = pkgs.callPackage ./pkgs/sxmo-dmenu {};
  superd      = pkgs.callPackage ./pkgs/superd {};
  tinydm      = pkgs.callPackage ./pkgs/tinydm {};
  autologin   = pkgs.callPackage ./pkgs/autologin {};
  proycon-wayout = pkgs.callPackage ./pkgs/proycon-wayout {};
  mnc         = pkgs.callPackage ./pkgs/mnc {};
  mmsd-tng    = pkgs.callPackage ./pkgs/mmsd-tng {};
  codemadness-frontends = pkgs.callPackage ./pkgs/codemadness-frontends {};
  vvmd        = pkgs.callPackage ./pkgs/vvmd {};
  sxmo-utils  = pkgs.callPackage ./pkgs/sxmo-utils {
    inherit
      codemadness-frontends
      mmsd-tng
      mnc
      superd
      vvmd
      sxmo-dwm
      sxmo-dmenu
      sxmo-st
    ;
  };
}
