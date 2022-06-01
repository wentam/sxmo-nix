{stdenv, pkgs, lib, fetchFromSourcehut, st, ...}:

(st.overrideAttrs (oldAttrs: rec {
  name = "smxo-st";
  version = "0.8.4.1";

  src = fetchFromSourcehut {
    owner = "~mil";
    repo = "sxmo-st";
    rev = version;
    sha256 = "sha256-yqm1/hZq+ekAfyplmOm4wcf4QEs1/RXXhYa4fgMGhNo=";
  };

  meta = with lib; {
    description = "St terminal emulator for sxmo.";
    homepage = "https://git.sr.ht/~mil/sxmo-st";
    license = licenses.mit;
    platforms = platforms.linux;
    maintainers = with maintainers; [ wentam ];
  };
}))
