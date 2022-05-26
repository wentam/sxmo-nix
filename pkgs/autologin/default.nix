{stdenv, pkgs, lib, fetchgit, ...}:

stdenv.mkDerivation rec {
  pname = "autologin";
  version = "1.0.0";

  src = fetchgit {
    url = "https://git.sr.ht/~kennylevinsen/autologin";
    rev = version;
    sha256 = "sha256-Cy4v/1NuaiSr5Bl6SQMWk5rga8h1QMBUkHpN6M3bWOc=";
  };

  buildInputs = with pkgs; [ meson pam ninja ];

  meta = with lib; {
    description = "It logs you in. Automatically.";
    homepage = "https://git.sr.ht/~kennylevinsen/autologin";
    license = licenses.gpl3;
    platforms = platforms.linux;
    maintainers = with maintainers; [ wentam ];
  };
}
