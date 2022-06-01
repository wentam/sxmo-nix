{stdenv, pkgs, lib, fetchFromSourcehut, ...}:

stdenv.mkDerivation rec {
  pname = "wayout";
  version = "0.1.2";

  src = fetchFromSourcehut {
    owner = "~proycon";
    repo = "wayout";
    rev = version;
    sha256 = "sha256-gbsAGpo4c/p8Ad2iF7dsDKjCsF2tZJxwr/ncWSNNyqQ=";
  };

  buildInputs = with pkgs; [ meson pkgconfig wayland-protocols wayland cairo pango scdoc ninja ];

  patches = [ ./remove-werror.patch ];

  meta = with lib; {
    description = "Wayout takes text from standard input and outputs it to a desktop-widget on Wayland desktops. ";
    homepage = "https://git.sr.ht/~proycon/wayout";
    license = licenses.gpl3;
    platforms = platforms.linux;
    maintainers = with maintainers; [ wentam ];
  };
}
