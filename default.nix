{ pkgs ? import <nixpkgs> { } }:

rec {
  lib = import ./lib { inherit pkgs; }; # functions
  modules = import ./modules; # NixOS modules
  overlays = import ./overlays; # nixpkgs overlays

  sxmo-utils = pkgs.callPackage ./pkgs/sxmo-utils {};
  sxmo-dwm   = pkgs.callPackage ./pkgs/sxmo-dwm {};
  sxmo-st    = pkgs.callPackage ./pkgs/sxmo-st {};
  sxmo-dmenu = pkgs.callPackage ./pkgs/sxmo-dmenu {};
  superd     = pkgs.callPackage ./pkgs/superd {};
}
