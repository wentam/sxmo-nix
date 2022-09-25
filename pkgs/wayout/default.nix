{ stdenv
, lib
, fetchFromSourcehut
, meson
, wayland-protocols
, wayland
, cairo
, pango
, scdoc
, ninja
, cmake
, pkg-config
, wayland-scanner
}:

stdenv.mkDerivation rec {
  pname = "wayout";
  version = "0.1.2";

  src = fetchFromSourcehut {
    owner = "~proycon";
    repo = "wayout";
    rev = version;
    sha256 = "sha256-gbsAGpo4c/p8Ad2iF7dsDKjCsF2tZJxwr/ncWSNNyqQ=";
  };

  depsBuildBuild = [ pkg-config ];
  nativeBuildInputs = [ scdoc ninja meson cmake pkg-config wayland-scanner ];
  buildInputs = [ wayland-protocols wayland cairo pango wayland-scanner ];

  patches = [ ./remove-werror.patch ];

  meta = with lib; {
    description = "Takes text from standard input and outputs it to a desktop-widget on Wayland desktops. ";
    homepage = "https://git.sr.ht/~proycon/wayout";
    license = licenses.gpl3;
    platforms = platforms.linux;
    maintainers = with maintainers; [ wentam ];
  };
}
