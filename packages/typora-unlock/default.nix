{ stdenv
, fetchurl
, dpkg
, lib
, glib
, nss
, nspr
, at-spi2-atk
, cups
, dbus
, libdrm
, gtk3
, pango
, cairo
, xorg
, libxkbcommon
, mesa
, expat
, alsa-lib
, buildFHSEnv
, cargo
, unzip
}:

let
  pname = "typora";
  version = "1.7.6";
  src = fetchurl {
    url = "https://download.typora.io/linux/typora_${version}_amd64.deb";
    hash = "sha256-o91elUN8sFlzVfIQj29amsiUdSBjZc51tLCO+Qfar6c=";
  };
  _src = fetchurl {
    url = "http://store.yvling.icu/tools/typora/typora-unlock.zip";
    sha256 = "sha256-Vwplo03sH7fw5yR9ZiPOXmzwUu6jpvZByZfB0VhTUSo=";
  };

  typoraBase = stdenv.mkDerivation {
    inherit pname version src _src;

    nativeBuildInputs = [ dpkg cargo unzip ];

    dontConfigure = true;
    dontBuild = true;

    installPhase = ''
      runHook preInstall
      
      echo build_1
      echo $out
      mkdir -p $out/bin $out/share 
      unzip -q $_src
      mv typora-unlock/node_inject usr/share/typora/node_inject
      chmod a+x usr/share/typora/node_inject
      current_dir=$(pwd)
      cd ./usr/share/typora/ && ./node_inject
      cd "$current_dir"
      mv usr/share $out    
      ln -s $out/share/typora/Typora $out/bin/Typora

      runHook postInstall
    '';
  };

  typoraFHS = buildFHSEnv {
    name = "typora-fhs";
    targetPkgs = pkgs: (with pkgs; [
      typoraBase
      udev
      alsa-lib
      glib
      nss
      nspr
      atk
      cups
      dbus
      gtk3
      libdrm
      pango
      cairo
      mesa
      expat
      libxkbcommon
    ]) ++ (with pkgs.xorg; [
      libX11
      libXcursor
      libXrandr
      libXcomposite
      libXdamage
      libXext
      libXfixes
      libxcb
    ]);
    runScript = ''
      Typora $*
    '';
  };

in stdenv.mkDerivation {
  inherit pname version _src;

  dontUnpack = true;
  dontConfigure = true;
  dontBuild = true;
  
  nativeBuildInputs = [ unzip ];

  installPhase = ''
    runHook preInstall
    
    echo build2
    mkdir -p $out/bin
    unzip -q $_src
    mv typora-unlock/gan-key typora-gen
    chmod a+x typora-gen
    mv typora-gen $out/bin/typora-gen
    ln -s ${typoraFHS}/bin/typora-fhs $out/bin/typora
    ln -s ${typoraBase}/share/ $out
    
    runHook postInstall
  '';

  meta = with lib; {
    description = "A markdown editor, a markdown reader";
    homepage = "https://typora.io/";
    maintainers = with maintainers; [ fangnan700 ];
    platforms = [ "x86_64-linux" ];
    mainProgram = "typora";
  };
}
