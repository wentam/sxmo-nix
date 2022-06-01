{stdenv, lib, fetchFromSourcehut, meson, ninja, pam, ...}:

stdenv.mkDerivation rec {
  pname = "autologin";
  version = "1.0.0";

  src = fetchFromSourcehut {
    owner = "~kennylevinsen";
    repo = "autologin";
    rev = version;
    sha256 = "sha256-Cy4v/1NuaiSr5Bl6SQMWk5rga8h1QMBUkHpN6M3bWOc=";
  };

  nativeBuildInputs = [ meson ninja ];
  buildInputs = [ pam ];

  meta = with lib; {
    description = "It logs you in. Automatically.";
    homepage = "https://git.sr.ht/~kennylevinsen/autologin";
    license = licenses.gpl3;
    platforms = platforms.linux;
    maintainers = with maintainers; [ wentam ];
  };
}
