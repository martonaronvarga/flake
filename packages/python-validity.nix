{
  fetchFromGitHub,
  fetchurl,
  innoextract,
  lib,
  python3Packages,
}:
python3Packages.buildPythonApplication rec {
  pname = "python-validity";
  version = "0.15-unstable-2026-05-29";
  pyproject = false;

  src = fetchFromGitHub {
    owner = "uunicorn";
    repo = "python-validity";
    rev = "a6bbc21dce7b8b3c3cd92378a0b2579a2fb45920";
    hash = "sha256-RflX7e6nd11pSg8mh3mjZiVGNUSdox/SKXHR4W+PhMs=";
  };

  firmwareInstaller = fetchurl {
    url = "https://download.lenovo.com/pccbbs/mobiles/nz3gf07w.exe";
    hash = "sha512-pKTmBYseqKtyGVPSz9d1oee8WJhj0WDl67uQNEhY8UfWlRA2d6jfCy3gyVNF3xCL2pcZYkWwZ/RWMAOPt8gHzQ==";
  };

  nativeBuildInputs = [
    innoextract
    python3Packages.wrapPython
  ];

  propagatedBuildInputs = with python3Packages; [
    cryptography
    dbus-python
    pygobject3
    pyusb
    pyyaml
  ];

  installPhase = ''
    runHook preInstall

    sitePackages="$out/${python3Packages.python.sitePackages}"
    mkdir -p "$sitePackages" "$out/bin" "$out/lib/python-validity"
    cp -r validitysensor "$sitePackages/"
    install -m0555 bin/validity-led-dance bin/validity-sensors-firmware "$out/bin/"
    install -m0555 dbus_service/dbus-service "$out/lib/python-validity/"
    install -Dm0444 dbus_service/io.github.uunicorn.Fprint.conf \
      "$out/share/dbus-1/system.d/io.github.uunicorn.Fprint.conf"

    innoextract --silent --output-dir extracted "$firmwareInstaller"
    install -Dm0400 \
      "$(find extracted -name 6_07f_lenovo_mis_qm.xpfwext -print -quit)" \
      "$out/share/python-validity/6_07f_lenovo_mis_qm.xpfwext"

    wrapPythonProgramsIn "$out/bin" "$out $propagatedBuildInputs"
    wrapPythonProgramsIn "$out/lib/python-validity" "$out $propagatedBuildInputs"

    runHook postInstall
  '';

  doCheck = false;

  meta = {
    description = "Experimental userspace driver for selected Validity fingerprint sensors";
    homepage = "https://github.com/uunicorn/python-validity";
    license = lib.licenses.mit;
    platforms = lib.platforms.linux;
  };
}
