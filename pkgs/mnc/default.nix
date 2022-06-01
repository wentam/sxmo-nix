{stdenv, pkgs, lib, fetchFromSourcehut, buildGoModule, ...}:

buildGoModule rec {
  pname = "mnc";
  version = "0.4";
  vendorSha256 = "sha256-H0KmGTWyjZOZLIEWophCwRYPeKLxBC050RI7cMXNbPs=";

  src = fetchFromSourcehut {
    owner = "~anjan";
    repo = "mnc";
    rev = version;
    sha256 = "sha256-S7MBIxuYI+cc8OMQULt7VS7ouPqhq0Jk+rz6E5GyKac=";
  };

  meta = with lib; {
    description = "mnc (my next cron) opens the user's crontab and echos the time when the next cronjob will be ran.";
    homepage = "https://git.sr.ht/~anjan/mnc";
    license = licenses.unlicense;
    platforms = platforms.linux;
    maintainers = with maintainers; [ wentam ];
  };
}
