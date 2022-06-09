{stdenv, pkgs, lib, fetchFromSourcehut, buildGoModule, scdoc, ...}:

buildGoModule rec {
  pname = "superd";
  version = "0.3.2";
  vendorSha256 = "sha256-u9xEtuTqhVjKV29bfwW4tHu3HTk45UqH+yC+XQYQdQA=";

  nativeBuildInputs = [ scdoc ];

  src = fetchFromSourcehut {
    owner = "~craftyguy";
    repo = "superd";
    rev = version;
    sha256 = "sha256-yPwenjvSMz2yt8g7WXTrYyhjkZygEPsUKcKCYSj4tDs=";
  };

  postInstall = ''
    # Install man pages
    make doc
    mkdir -p $out/man/man1 $out/man/man5
    install -m 0644 superd.1 $out/man/man1/
    install -m 0644 superd.service.5 $out/man/man5/
    install -m 0644 superctl.1 $out/man/man1/
  '';

  meta = with lib; {
    description = "A user service supervisor";
    homepage = "https://git.sr.ht/~craftyguy/superd";
    license = licenses.gpl3;
    platforms = platforms.linux;
    maintainers = with maintainers; [ wentam ];
  };
}
