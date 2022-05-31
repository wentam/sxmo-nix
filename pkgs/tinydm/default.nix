{stdenv, pkgs, lib, fetchFromGitLab, ...}:

stdenv.mkDerivation rec {
  pname = "tinydm";
  version = "1.1.2";

  src = fetchFromGitLab {
    owner = "postmarketOS";
    repo = "tinydm";
    rev = version;
    sha256 = "sha256-6wmjquhumQHFgE9Hf5bn9fWfqQ5G3nAIvxuGwr5tLpM=";
  };

  patches = [
    ./001-use-xdg-data-dirs.patch
  ];

  buildInputs = [ pkgs.gcc pkgs.busybox ];
  buildPhase = '':'';
  installPhase = ''
   mkdir -p $out/bin
   install -Dm755 tinydm-run-session.sh $out/bin/tinydm-run-session
   install -Dm755 tinydm-set-session.sh $out/bin/tinydm-set-session
   install -Dm755 tinydm-unset-session.sh $out/bin/tinydm-unset-session
  '';
  #prePatch = '''';

  meta = with lib; {
    description = "Tiny wayland / x11 session starter for single user machines";
    homepage = "https://gitlab.com/postmarketOS/tinydm";
    license = licenses.gpl3;
    platforms = platforms.linux;
    maintainers = with maintainers; [ wentam ];
  };
}
