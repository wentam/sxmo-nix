{stdenv, pkgs, lib, fetchgit, ...}:

stdenv.mkDerivation rec {
  pname = "sxmo-utils";
  version = "1.9.0";

  src = fetchgit {
    url = "https://git.sr.ht/~mil/sxmo-utils";
    rev = version;
    sha256 = "sha256-moe5sok/40Xc7y1RAvXiOEseja7cDpa9QMiw1VPZOPk";
  };

  passthru.providedSessions = [ "swmo" "sxmo" ];

  buildInputs = [ pkgs.gcc pkgs.busybox ];
  buildPhase = "make";

  installPhase = ''
    make install DESTDIR=$out PREFIX=""
    mkdir -p $out/lib/udev
    mv $out/usr/lib/udev/rules.d $out/lib/udev/
  '';

  prePatch = ''
    # fix hardcoded paths
    find . -type f -exec sed -i "s|/usr/share|$out/share|g" {} +
    find . -type f -exec sed -i "s|/etc/profile.d|$out/share/sxmo/profile.d|g" {} +
    find . -type f -exec sed -i "s|/usr/bin/||g" {} +
    sed -i "s|/bin/chgrp|${pkgs.coreutils}/bin/chgrp|g" configs/udev/90-sxmo.rules
    sed -i "s|/bin/chmod|${pkgs.coreutils}/bin/chmod|g" configs/udev/90-sxmo.rules
  '';

  meta = with lib; {
    description = "Contains the scripts and small C programs that glues the sxmo enviroment together";
    homepage = "https://git.sr.ht/~mil/sxmo-utils";
    license = licenses.agpl3Only;
    platforms = platforms.linux;
    maintainers = with maintainers; [ wentam ];
  };
}
