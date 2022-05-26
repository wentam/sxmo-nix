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

  patches = [ ./run-session-env-paths.patch ];

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
    description = "";
    homepage = "";
    license = licenses.agpl3Only;
    platforms = platforms.linux;
    maintainers = with maintainers; [ wentam ];
  };
}
