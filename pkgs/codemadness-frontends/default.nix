{ stdenv, lib, fetchurl, libressl, glibc, ... }:

stdenv.mkDerivation rec {
  pname = "codemadness-frontends";
  version = "0.5";

  patches = [ ./001-link-dynamically.patch ];

  buildInputs = [ libressl glibc ];

  makeFlags = [ "RANLIB=${stdenv.cc.targetPrefix}ranlib" ];

  src = fetchurl {
    url = "https://www.codemadness.org/releases/frontends/frontends-${version}.tar.gz";
    sha256 = "sha256-8NKSfyIMSzaWTgIkFdcPTX/ECeQiasZPfZG1Ft/LOUw=";
  };

  installPhase = ''
    install -D reddit/cli $out/bin/reddit-cli
    install -D reddit/gopher $out/bin/reddit-gopher
    install -D duckduckgo/cli $out/bin/duckduckgo-cli
    install -D duckduckgo/gopher $out/bin/duckduckgo-gopher
    install -D youtube/cli $out/bin/youtube-cli
    install -D youtube/cgi $out/bin/youtube-cgi
    install -D youtube/gopher $out/bin/youtube-gopher
  '';

  meta = with lib; {
    description = "Frontends for duckduckgo, reddit, twitch, and youtube";
    homepage = "https://www.codemadness.org/";
    license = licenses.isc;
    platforms = platforms.linux;
    maintainers = with maintainers; [ wentam ];
  };
}
