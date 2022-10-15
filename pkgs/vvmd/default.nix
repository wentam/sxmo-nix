{ stdenv
, lib
, fetchFromGitLab
, meson
, pkg-config
, cmake
, mobile-broadband-provider-info
, glib
, modemmanager
, curl
, libphonenumber
, ninja
, protobuf
}:

stdenv.mkDerivation rec {
  pname = "vvmd";
  version = "0.11";

  src = fetchFromGitLab {
    owner = "kop316";
    repo = "vvmd";
    rev = version;
    sha256 = "sha256-aunygF8DfQwXIHrzgvikN2Zf6HP80x1j8CHbLTW7BrU=";
  };

  nativeBuildInputs = [ meson pkg-config cmake ];
  buildInputs = [ mobile-broadband-provider-info glib modemmanager curl libphonenumber ninja protobuf ];

  meta = with lib; {
    description = "A lower level daemon that retrieves Visual Voicemail";
    homepage = "https://gitlab.com/kop316/vvmd/";
    license = licenses.gpl2;
    platforms = platforms.linux;
    maintainers = with maintainers; [ wentam ];
  };
}
