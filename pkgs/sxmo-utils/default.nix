{stdenv, pkgs, lib, fetchgit, coreutils, findutils, gnused, busybox, ...}:

stdenv.mkDerivation rec {
  pname = "sxmo-utils";
  #version = "1.9.0";
  version = "d6a6fc2c4767a49e8fd1be7293c2bbd47da3f811";

  src = fetchgit {
    url = "https://git.sr.ht/~mil/sxmo-utils";
    rev = version;
    sha256 = "sha256-cuG4/hhi98+UFBI/lKwlKkz0vqlKtqR8G1vmHKMs1zE=";
  };

  patches = [
    ./000-paths.patch # replaces /usr/share with $XDG_DATA_DIRS usage
    ./001-fix-makefile-appscript-symlinks.patch
    ./002-use-systemctl-poweroff.patch    # normal 'poweroff' doesn't seem to work
    ./003-repoint-config-paths.patch
    ./004-modem-use-coreutils-date.patch # See https://todo.sr.ht/~mil/sxmo-tickets/446
    ./005-coreutils-aliases.patch        # aliases to force coreutils over busybox when needed
  ];

  passthru.providedSessions = [ "swmo" "sxmo" ];

  nativeBuildInputs = [ coreutils findutils gnused busybox ];
  buildPhase = "make";

  installPhase = ''
    make install OPENRC=0 DESTDIR=$out PREFIX=""
    mkdir -p $out/lib/udev
    mv $out/usr/lib/udev/rules.d $out/lib/udev/

    # Clean up empty directories
    rmdir $out/usr/lib/udev/
    rmdir $out/usr/lib/
    rmdir $out/usr/
  '';

  postPatch =
  let
    # SXMO loves hardcoded paths, and it would be painful to make patches for everything.
    # We need to use lots of sed.
    #
    # To keep substitutions reliable, we only replace when the thing we want to
    # replace is prefixed with whitespace or start-of-line,
    # and suffixed with whitespace or end-of-line.
    # we make exceptions for ([{}])=":<>& chars
    #
    # We also ignore commented lines (this is important to avoid unnecessary migrations by the user)
    #
    # For example with from=stat and to=otherstat:
    # * won't replace 'netstat' with 'netotherstat',
    # * won't replace '/foo/stat' with '/foo/otherstat'
    # * won't replace statfoo with 'otherstatfoo'
    # * won't replace $stat with '$otherstat'
    # * will replace ' stat thing' with ' otherstat thing'
    # * will replace 'stat thing' with 'otherstat thing'
    # * will replace '(stat thing' with '(otherstat thing'
    # * will replace 'thing stat)' with 'thing otherstat)'
    #
    # the _with_trailing functions don't perform the suffix check,
    # so you can replace the prefix portion of paths.
    sep = ''\|'';
    permittedSymbols = ''\(${sep}\[${sep}\{${sep}=${sep}\"${sep}\)${sep}\]${sep}\:${sep}\}${sep}\'${sep}\>${sep}\s+${sep}\&'';
    prefixCheck = ''(^${sep}${permittedSymbols})'';
    suffixCheck = ''($\|${permittedSymbols})'';
    beforeReplace = ''h;s/[^#]*//1;x;s/#.*//;''; # For ignoring comments
    afterReplace = '';G;s/(.*)\n/\1/'';          # for ignoring comments
    sed_replace = from: to: ''sed -E -i "${beforeReplace}s|${prefixCheck}${from}${suffixCheck}|\1${to}\2|g${afterReplace}"'';
    sed_replace_with_trailing = from: to: ''sed -E -i "${beforeReplace}s|${prefixCheck}${from}|\1${to}|g${afterReplace}"'';
    find_replace = from: to: ''find . -type f ! -name Makefile -exec ${sed_replace from to} {} +'';
    find_replace_with_trailing = from: to: ''find . -type f ! -name Makefile -exec ${sed_replace_with_trailing from to} {} +'';
  in
  ''
    # fix hardcoded paths
    ${find_replace_with_trailing "/etc/profile.d" "$out/share/sxmo/profile.d"}
    ${find_replace_with_trailing "/usr/bin/" ""}
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
