{
  lib,
  stdenvNoCC,
  requireFile,
  unzip,
}:
stdenvNoCC.mkDerivation {
  pname = "tx-02";
  version = "2.002";

  src = requireFile {
    name = "berkeley-mono.zip";
    hash = "sha256-1CkrOrw5jYt56jk6FTU5qq4TP5dej4NBjVhnSagaKH4=";
    message = ''
      Copy the licensed archive to the Nix store with:
        nix-store --add-fixed sha256 /persist/home/usu/downloads/berkeley-mono.zip
    '';
  };

  nativeBuildInputs = [unzip];
  sourceRoot = ".";
  dontConfigure = true;
  dontBuild = true;

  unpackPhase = ''
    runHook preUnpack
    unzip "$src" 'TX-02 2.002/*.ttf'
    runHook postUnpack
  '';

  installPhase = ''
    runHook preInstall
    install -Dm644 "TX-02 2.002/"*.ttf -t "$out/share/fonts/truetype"
    runHook postInstall
  '';

  preferLocalBuild = true;
  allowSubstitutes = false;

  meta = {
    description = "TX-02 2.002 typeface";
    license = lib.licenses.unfree;
    platforms = lib.platforms.all;
    sourceProvenance = [lib.sourceTypes.binaryNativeCode];
  };
}
