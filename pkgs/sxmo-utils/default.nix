{stdenv, pkgs, lib, fetchgit, coreutils, findutils, gnused, busybox, ...}:

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
    ./fix-makefile-appscript-symlinks.patch
    ./use-systemctl-poweroff.patch
    ./003-fix-orientation-detection.patch # Fix for upstream bug, probably remove next release
    ./004-repoint-config-paths.patch
    ./005-modem-use-coreutils-date.patch
  ];

  passthru.providedSessions = [ "swmo" "sxmo" ];

  nativeBuildInputs = [ coreutils findutils gnused busybox ];
  buildPhase = "make";

  installPhase = ''
    make install DESTDIR=$out PREFIX=""
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
    # We also ignore commented lines
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
    #
    # TODO: this set of rules only really applies to shell scripts.
    # While shell scripts are most of what exists here, we should still only
    # apply this to shell script/shell-script-like files.
    # We can't gaurantee this ruleset won't break something in a different file format.
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
    ${find_replace_with_trailing "/usr/share" "$out/share"}
    ${find_replace_with_trailing "/etc/profile.d" "$out/share/sxmo/profile.d"}
    ${find_replace_with_trailing "/usr/bin/" ""}
    sed -i "s|/bin/chgrp|${pkgs.coreutils}/bin/chgrp|g" configs/udev/90-sxmo.rules
    sed -i "s|/bin/chmod|${pkgs.coreutils}/bin/chmod|g" configs/udev/90-sxmo.rules

    # replace some commands that need coreutils things that busybox does not have
    # depending on system config, they might be calling into busybox and that will break.
    ${find_replace "realpath" "${pkgs.coreutils}/bin/realpath"}
    ${find_replace "stat --printf" "${pkgs.coreutils}/bin/stat --printf"}

    # 'busybox rfkill' isn't working for us, while util-linux is
    ${find_replace "busybox rfkill" "rfkill"}
    ${find_replace "rfkill list" "${pkgs.util-linux}/bin/rfkill list"}
    ${find_replace "rfkill block" "${pkgs.util-linux}/bin/rfkill block"}
    ${find_replace "rfkill unblock" "${pkgs.util-linux}/bin/rfkill unblock"}
  '';

  meta = with lib; {
    description = "Contains the scripts and small C programs that glues the sxmo enviroment together";
    homepage = "https://git.sr.ht/~mil/sxmo-utils";
    license = licenses.agpl3Only;
    platforms = platforms.linux;
    maintainers = with maintainers; [ wentam ];
  };
}
