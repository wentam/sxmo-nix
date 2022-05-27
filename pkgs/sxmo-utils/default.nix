{stdenv, pkgs, lib, fetchgit, ...}:

stdenv.mkDerivation rec {
  pname = "sxmo-utils";
  version = "1.9.0";

  src = fetchgit {
    url = "https://git.sr.ht/~mil/sxmo-utils";
    rev = version;
    sha256 = "sha256-moe5sok/40Xc7y1RAvXiOEseja7cDpa9QMiw1VPZOPk";
  };

  patches = [
    ./remove-wmtoggle-doas.patch
  ];

  passthru.providedSessions = [ "swmo" "sxmo" ];

  buildInputs = [ pkgs.gcc pkgs.busybox ];
  buildPhase = "make";

  installPhase = ''
    make install DESTDIR=$out PREFIX=""
    mkdir -p $out/lib/udev
    mv $out/usr/lib/udev/rules.d $out/lib/udev/
  '';

  postPatch = ''
    # fix hardcoded paths
    find . -type f -exec sed -i "s|/usr/share|$out/share|g" {} +
    find . -type f -exec sed -i "s|/etc/profile.d|$out/share/sxmo/profile.d|g" {} +
    find . -type f -exec sed -i "s|/usr/bin/||g" {} +
    sed -i "s|/bin/chgrp|${pkgs.coreutils}/bin/chgrp|g" configs/udev/90-sxmo.rules
    sed -i "s|/bin/chmod|${pkgs.coreutils}/bin/chmod|g" configs/udev/90-sxmo.rules

    # replace some commands that need coreutils things that busybox does not have
    # depending on system config, they might be calling into busybox and that will break.
    find . -type f -exec sed -i "s|realpath |${pkgs.coreutils}/bin/realpath |g" {} +
    find . -type f -exec sed -i "s|stat |${pkgs.coreutils}/bin/stat |g" {} +
    find . -type f -exec sed -i "s|date |${pkgs.coreutils}/bin/date |g" {} +

    # 'busybox rfkill' isn't working for us, while util-linux is
    find . -type f -exec sed -i "s|busybox rfkill |rfkill |g" {} +
    find . -type f -exec sed -i "s|rfkill |${pkgs.util-linux}/bin/rfkill |g" {} +
  '';

  meta = with lib; {
    description = "Contains the scripts and small C programs that glues the sxmo enviroment together";
    homepage = "https://git.sr.ht/~mil/sxmo-utils";
    license = licenses.agpl3Only;
    platforms = platforms.linux;
    maintainers = with maintainers; [ wentam ];
  };
}
