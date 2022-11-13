{ stdenv
, pkgs
, lib
, fetchFromSourcehut
, coreutils
, findutils
, gnused
, gnugrep
, busybox
, libnotify
, inotify-tools
, xdg-user-dirs
, mmsd-tng
, alsa-utils
, callaudiod
, light
, superd
, lisgd
, pn
, gojq
, mnc
, lsof
, bc
, dbus
, file
, curl
, vvmd
, mpv
, pamixer
, codemadness-frontends
, sfeed
, libxml2
, youtube-dl
, sxiv
, mediainfo
, gawk
, modemmanager
, util-linux
, proycon-wayout
, autocutsel
, sxmo-dwm
, sxmo-dmenu
, svkbd
, xdotool
, xprintidle
, conky
, clickclack
, xmodmap
, feh
, unclutter-xfixes
, dunst
, gnome-icon-theme
, sxmo-st
, xsel
, xclip
, scrot
, sway
, bemenu
, wvkbd
, swayidle
, wob
, mako
, foot
, grim
, slurp
, x11Support ? true
, waylandSupport ? true
, ...
}:

stdenv.mkDerivation rec {
  pname = "sxmo-utils";

  # Important: When updating version, grep for /usr/share in sxmo-utils. All instances should be
  # replaced with uses of the xdg_data_path function in sxmo_common.sh, and the devs often forget
  # this. Use your patch here, but also submit your patch to sxmo-utils.
  version = "1.11.1";

  src = fetchFromSourcehut {
    owner = "~mil";
    repo = "sxmo-utils";
    rev = version;
    sha256 = "sha256-uV5+erJCe7JmJhKnJF5IQ2kBX6WNxYJRXLo7MBkE0fk=";
  };

  patches = [
    ./001-fix-makefile-appscript-symlinks.patch
    ./003-repoint-config-paths.patch     # Configs can reference data through /run/current-system/sw/share/
    ./006-system-manages-pipewire.patch  # Sxmo trying to manage pipewire conflicts with system.

    ./007-xdg-data-path.patch            # Fix hardcoded /usr/share refs. Submitted to sxmo-utils. remove after next update
    ./008-fix-status-bar.patch           # Fix for bug specific to current release, remove after next update
  ];

  passthru.providedSessions = lib.optionals x11Support [ "sxmo" ]
                           ++ lib.optionals waylandSupport [ "swmo" ];

  nativeBuildInputs = [ coreutils findutils gnused busybox ];

  makeFlags = [
    "DESTDIR=$(out)"
    "PREFIX="
    "OPENRC=0"
  ];

  postInstall = ''
    mkdir -p $out/lib/udev
    mv $out/usr/lib/udev/rules.d $out/lib/udev/
    cd $out && rmdir -p usr/lib/udev/
  '';

  postPatch = ''
    # Sxmo references /usr/bin/ directly in a number of places. We can just
    # chop it off and everything will be found via $PATH
    find . -type f -exec sed -E -i "s|/usr/bin/||g" {} +

    substituteInPlace configs/udev/90-sxmo.rules \
      --replace /bin/chgrp ${coreutils}/bin/chgrp \
      --replace /bin/chmod ${coreutils}/bin/chmod

    # We'll be wrapping the sxmo scripts by modifying sxmo_common.sh.
    # Make sure sxmo_common.sh is sourced everywhere so this is consistently applied
    sed -i '2i . sxmo_common.sh' \
      $(${gnugrep}/bin/grep -rL "\. sxmo_common.sh" --include \*.sh --exclude sxmo_common.sh .)

    # Script dependencies
    sed -i '2i export PATH="'"$out"'/bin:${lib.makeBinPath ([
      libnotify      # For sending desktop notifications
      inotify-tools
      xdg-user-dirs  # For xdg-user-dirs-update
      modemmanager
      mmsd-tng       # MMS support
      alsa-utils
      callaudiod     # Call audio routing
      light          # Used to adjust backlight
      superd         # Manages sxmo's services
      util-linux     # setsid, rfkill
      busybox        # Sxmo sometimes uses busybox binary directly
      lisgd          # Gesture daemon
      pn             # Phone number parsing/formatting/validation
      gojq           # JSON parsing
      mnc            # Used to schedule suspend wakeups for cron
      lsof
      bc
      dbus           # dbus-run-session
      file
      curl
      vvmd           # Visual voicemail
      mpv
      pamixer        # Volume control when using pulse/pipewire
      codemadness-frontends # reddit-cli and youtube-cli for sxmo_[reddit|youtube].sh
      sfeed      # sxmo_rss.sh
      libxml2    # sxmo_weather.sh
      youtube-dl # sxmo_youtube.sh
      sxiv       # To view images with file browser and sxmo_open.sh
      mediainfo  # sxmo_record.sh
      gawk
    ] ++ lib.optionals x11Support [
      autocutsel # sxmo runs this to keep the cutbuffer and clipboard in sync
      sxmo-dwm
      sxmo-dmenu
      svkbd
      xdotool
      xprintidle
      conky # Used for clock
      clickclack # for keyboard feedback
      xmodmap
      feh
      unclutter-xfixes
      dunst
      gnome-icon-theme  # dunst needs these
      sxmo-st
      xsel
      xclip
      scrot
    ] ++ lib.optionals waylandSupport [
      (sway.override {
        withBaseWrapper = true;
        withGtkWrapper = true;
      })
      bemenu
      wvkbd
      swayidle
      wob
      mako
      proycon-wayout
      foot

      # scripts
      grim
      slurp
    ])}''${PATH:+:}$PATH"' scripts/core/sxmo_common.sh

    sed -i '2i export PATH="\$XDG_BIN_HOME:\$XDG_CONFIG_HOME/sxmo/hooks/:'"$out"'/share/sxmo/default_hooks/''${PATH:+:}$PATH"' \
      scripts/core/sxmo_common.sh

    # Need environment variables to run sxmo script over ssh/without graphical session
    sed -i '2i export XDG_DATA_DIRS="'"$out"'/share''${XDG_DATA_DIRS:+:}$XDG_DATA_DIRS"' \
      scripts/core/sxmo_common.sh

    # These need to be set for some scripts to work over ssh/outside of graphical session.
    # Should match the values in sxmo_init.sh
    sed -i '2i export XDG_CONFIG_HOME="''${XDG_CONFIG_HOME:-$HOME/.config}"' \
      scripts/core/sxmo_common.sh
    sed -i '2i export XDG_DATA_HOME="''${XDG_DATA_HOME:-$HOME/.local/share}"' \
      scripts/core/sxmo_common.sh
    sed -i '2i export XDG_CACHE_HOME="''${XDG_CACHE_HOME:-$HOME/.cache}"' \
      scripts/core/sxmo_common.sh

    # Sometimes sxmo assumes certain non-standard features in common utilities.
    # Explicitly define these cases with aliases to ensure the relevant features are present.
    ${if waylandSupport then
      ''
        sed -i '2i alias wayout="${proycon-wayout}/bin/proycon-wayout"' \
          scripts/core/sxmo_common.sh
      ''
      else ""
    }
    sed -i '2i alias realpath="${coreutils}/bin/realpath"' \
      scripts/core/sxmo_common.sh
    sed -i '2i alias stat="${coreutils}/bin/stat"' \
      scripts/core/sxmo_common.sh
    sed -i '2i alias mktemp="${coreutils}/bin/mktemp"' \
      scripts/core/sxmo_common.sh
    sed -i '2i alias date="${coreutils}/bin/date"' \
      scripts/core/sxmo_common.sh
    sed -i 's|alias rfkill=.*$||' scripts/core/sxmo_common.sh
    sed -i '2i alias rfkill="${util-linux}/bin/rfkill"' \
      scripts/core/sxmo_common.sh

    # Make poweroff work
    substituteInPlace scripts/core/sxmo_power.sh \
      --replace "doas poweroff" "doas systemctl poweroff"

    # sxmo hardcodes path to sxmo_init.sh, repoint
    substituteInPlace \
      scripts/core/sxmo_winit.sh \
      scripts/core/sxmo_xinit.sh \
      scripts/core/sxmo_rtcwake.sh \
      scripts/core/sxmo_migrate.sh \
      --replace "/etc/profile.d/sxmo_init.sh" "$out/etc/profile.d/sxmo_init.sh"
  '';

  meta = with lib; {
    description = "Contains the scripts and small C programs that glues the sxmo enviroment together";
    homepage = "https://git.sr.ht/~mil/sxmo-utils";
    license = licenses.agpl3Only;
    platforms = platforms.linux;
    maintainers = with maintainers; [ wentam ];
  };
}
