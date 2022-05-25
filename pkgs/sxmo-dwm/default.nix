{stdenv, pkgs, lib, fetchgit, dwm, ...}:

(dwm.overrideAttrs (oldAttrs: rec {
  name = "smxo-dwm";
  version = "6.2.17";

  src = fetchgit {
    url = "https://git.sr.ht/~mil/sxmo-dwm";
    rev = version;
    sha256 = "sha256-/q4QdXWDlNkhsLudAehAxofDs7BCMRAPna0S9gDZjZs=";
  };

  meta = with lib; {
    description = "Dwm for sxmo - multikey, swallow, dock, among other patches.";
    homepage = "https://git.sr.ht/~mil/sxmo-dwm";
    license = licenses.mit;
    platforms = platforms.linux;
    maintainers = with maintainers; [ wentam ];
  };
}))
