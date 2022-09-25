{
  stdenv,
  lib,
  fetchFromGitLab,
  meson,
  ninja,
  mobile-broadband-provider-info,
  pkg-config,
  glib,
  modemmanager,
  libsoup,
  c-ares,
  libphonenumber,
  protobuf,
  dbus,
  json_c,
  ...
}:

stdenv.mkDerivation rec {
  pname = "mmsd-tng";
  version = "1.9";

  src = fetchFromGitLab {
    owner = "kop316";
    repo = "mmsd";
    rev = version;
    sha256 = "sha256-IK3MU/sKHQLoCvnzjm1cyk3Gv00VKL04gTlN8hzxXNA=";
  };

  nativeBuildInputs = [ meson pkg-config ninja ];
  buildInputs = [ mobile-broadband-provider-info glib modemmanager libsoup c-ares libphonenumber protobuf dbus json_c ];

  configurePhase = ''
    meson _build -Dbuild-mmsctl=true
  '';

  buildPhase = ''
    meson compile -C _build
  '';

  installPhase = ''
    mkdir -p $out/bin
    install _build/mmsdtng $out/bin/
    install _build/tools/create-hex-array $out/bin/
    install _build/tools/decode-mms $out/bin/
    install _build/tools/mmsctl $out/bin/
  '';

  meta = with lib; {
    description = "Multimedia Messaging Service Daemon - The Next Generation";
    homepage = "https://gitlab.com/kop316/mmsd/";
    license = licenses.gpl2;
    platforms = platforms.linux;
    maintainers = with maintainers; [ wentam ];
  };
}
