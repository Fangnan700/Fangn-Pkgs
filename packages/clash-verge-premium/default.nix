{ lib
, stdenv
, fetchurl
, dpkg
, wrapGAppsHook
, autoPatchelfHook
, clash-meta
, openssl
, webkitgtk
, udev
, libayatana-appindicator
}:

stdenv.mkDerivation rec {
  pname = "clash-verge-premium";
  version = "1.0.0";

  src = fetchurl {
    url = "http://store.yvling.icu/packages/deb/clash/clash-verge-premium.deb";
    hash = "sha256-tQ2okttxNjUejyjjNUCpIw+QzKRq8uIW7dKyyYPOTGM=";
  };

  nativeBuildInputs = [
    dpkg
    wrapGAppsHook
    autoPatchelfHook
  ];

  buildInputs = [
    openssl
    webkitgtk
    stdenv.cc.cc
  ];

  runtimeDependencies = [
    (lib.getLib udev)
    libayatana-appindicator
  ];

  installPhase = ''
    runHook preInstall

    mkdir -p $out/bin
    mv clash-verge-premium/usr/* $out/

    runHook postInstall
  '';
}
