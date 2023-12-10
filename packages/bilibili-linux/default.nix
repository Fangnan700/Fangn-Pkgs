{ stdenv
, fetchurl
, electron
, lib
, makeWrapper
, ...
} @ args:

stdenv.mkDerivation rec {
  pname = "bilibili";
  version = "1.12.5.3101";
  src = fetchurl {
    url = "https://github.com/msojocs/bilibili-linux/releases/download/continuous/io.github.msojocs.bilibili_${version}-continuous_amd64.deb";
    sha256 = "sha256-rr1SVj+x3+dLWLp+wNy4cQv6ZjFNjTO9eOsRFgbQBpk=";
  };

  # 解压 deb 包
  unpackPhase = ''
    ar x ${src}
    tar xf data.tar.xz
  '';

  # makeWrapper 可以自动生成一个调用其它命令的命令（也就是 wrapper），并且可以在原命令上修改参数、环境变量等
  buildInputs = [ makeWrapper ];

  installPhase = ''
    mkdir -p $out/bin

    # 替换菜单项目（desktop 文件）中的路径
    cp -r usr/share $out/share
    sed -i "s|Exec=.*|Exec=$out/bin/bilibili|" $out/share/applications/*.desktop

    # 复制出客户端的 Javascript 部分，其它的不要了
    cp -r opt/apps/io.github.msojocs.bilibili/files/bin/app $out/opt

    # 生成 bilibili 命令，运行这个命令时会调用 electron 加载客户端的 Javascript 包（$out/opt/app.asar）
    makeWrapper ${electron}/bin/electron $out/bin/bilibili \
      --argv0 "bilibili" \
      --add-flags "$out/opt/app.asar"
  '';
  
  meta = with lib; {
    homepage = "https://github.com/msojocs/bilibili-linux";
    description = "哔哩哔哩 Linux版";
    platforms = [ "x86_64-linux" ];
    sourceProvenance = with sourceTypes; [ binaryNativeCode ];
    maintainers = with lib.maintainers; [ fangnan700 ];
  };
}
