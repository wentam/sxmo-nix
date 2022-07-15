{stdenv, pkgs, lib, fetchgit, coreutils, findutils, gnused, busybox, ...}:

stdenv.mkDerivation rec {
  pname = "sxmo-utils";
  #version = "1.9.0";
  version = "0e2c352842833a7dc44f8d26410675a2e4829e85";

  src = fetchgit {
    url = "https://git.sr.ht/~mil/sxmo-utils";
    rev = version;
    sha256 = "sha256-YXAKmUYdkdUyiHqtBMPAhA5UwGFAYffiDhaZVjSxiW0=";
  };

  patches = [
    ./000-old-bemenu-compat.patch # To be removed when this is merged: https://github.com/NixOS/nixpkgs/pull/180440
    ./001-fix-makefile-appscript-symlinks.patch
    ./002-use-systemctl-poweroff.patch   # Normal 'poweroff' doesn't seem to work
    ./003-repoint-config-paths.patch     # Configs can reference data through /run/current-system/sw/share/
    ./004-coreutils-aliases.patch        # Aliases to force coreutils over busybox when needed
    ./005-sxmo_init_use_PATH.patch       # Reference sxmo_init.sh via $PATH, not /etc/profile.d
    ./006-system-manages-pipewire.patch
  ];

  passthru.providedSessions = [ "swmo" "sxmo" ];

  nativeBuildInputs = [ coreutils findutils gnused busybox ];
  buildPhase = "make";

  installPhase = ''
    make install OPENRC=0 DESTDIR=$out PREFIX=""
    mkdir -p $out/lib/udev
    mv $out/usr/lib/udev/rules.d $out/lib/udev/

    # Sxmo references sxmo_init.sh through /etc/profile. We symlink to bin so
    # sxmo can find it via $PATH
    ln -s $out/etc/profile.d/sxmo_init.sh $out/bin/sxmo_init.sh

    # Clean up empty directories
    rmdir $out/usr/lib/udev/
    rmdir $out/usr/lib/
    rmdir $out/usr/
  '';

  postPatch = ''
    # Sxmo references /usr/bin/ directly in a number of places. We can just
    # chop it off and everything will be found via $PATH
    find . -type f -exec sed -E -i "s|/usr/bin/||g" {} +
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
