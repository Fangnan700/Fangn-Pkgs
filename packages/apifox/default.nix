{ stdenv
, fetchurl
, electron
, lib
, makeWrapper
, unzip
, appimage-run
, ...
} @ args:

stdenv.mkDerivation rec {
  pname = "apifox";
  version = "";
  src = fetchurl {
    url = "https://cdn.apifox.com/download/Apifox-linux-latest.zip";
    sha256 = "sha256-PAaAhhVQ2sI9yuX2Nzn6HY4tatJYKog4McluUSQspoA=";
  };
  
  # Work around the "unpacker appears to have produced no directories"
  # case that happens when the archive doesn't have a subdirectory.
  sourceRoot = ".";

  buildInputs = [ makeWrapper unzip appimage-run ];

  installPhase = ''
    mkdir -p $out/bin
    mkdir -p $out/share/Apifox
    mkdir -p $out/share/applications
    
    unzip -d ./Apifox $src
    cp -r ./Apifox/Apifox.AppImage $out/share/Apifox/
    
    appimage-run -x ./Apifox-image ./Apifox/Apifox.AppImage
    cp -r ./Apifox-image/*.desktop $out/share/applications/
    cp -r ./Apifox-image/resources/app.asar.unpacked/dist/assets/logo.png $out/share/Apifox/
    
    chmod a+x $out/share/Apifox/Apifox.AppImage
    
    sed -i "s|Exec=.*|Exec=${appimage-run}/bin/appimage-run $out/share/Apifox/Apifox.AppImage|" $out/share/applications/*.desktop
    sed -i "s|Icon=.*|Icon=$out/share/Apifox/logo.png|" $out/share/applications/*.desktop

    makeWrapper ${appimage-run}/bin/appimage-run $out/bin/apifox \
      --argv0 "apifox" \
      --add-flags "$out/share/Apifox/Apifox.AppImage"
  '';
}
