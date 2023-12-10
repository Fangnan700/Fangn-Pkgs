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
  version = "2.4.3";
  src = fetchurl {
    url = "https://cdn.apifox.com/download/Apifox-linux-latest.zip";
    sha256 = "sha256-H0I28I3PLww86LNhQA2jOehl9bfqIOsRIh0hPWmb/ak=";
  };
  
  # Work around the "unpacker appears to have produced no directories"
  # case that happens when the archive doesn't have a subdirectory.
  sourceRoot = ".";

  buildInputs = [ makeWrapper unzip ];

  installPhase = ''
    mkdir -p $out/bin
    mkdir -p $out/share/Apifox
    unzip -d ./Apifox $src
    mv ./Apifox/Apifox.AppImage $out/share/Apifox/
    chmod a+x $out/share/Apifox/Apifox.AppImage
    
    makeWrapper ${appimage-run}/bin/appimage-run $out/bin/apifox \
      --argv0 "apifox" \
      --add-flags "$out/share/Apifox/Apifox.AppImage"
  '';
}
