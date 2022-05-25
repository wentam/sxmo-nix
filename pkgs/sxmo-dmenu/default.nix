{stdenv, pkgs, lib, fetchgit, dmenu, ...}:

(dmenu.overrideAttrs (oldAttrs: rec {
  name = "smxo-dmenu";
  version = "5.0.14";

  src = fetchgit {
    url = "https://git.sr.ht/~mil/sxmo-dmenu";
    rev = version;
    sha256 = "sha256-r5E1XhefEvUKRpMVGp/77ewzUHNTc6CuiFtQwjh4CWk=";
  };

  meta = with lib; {
    description = "Dmenu for sxmo";
    homepage = "https://git.sr.ht/~mil/sxmo-dmenu";
    license = licenses.mit;
    platforms = platforms.linux;
    maintainers = with maintainers; [ wentam ];
  };
}))
