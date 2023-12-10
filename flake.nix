{
  description = "Fangn's NixOS package collection";
  
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-23.11";
    flake-utils.url = "github:numtide/flake-utils";
  };
  
  outputs = { self, nixpkgs, flake-utils }:
    with flake-utils.lib;
    with nixpkgs.lib;
    with builtins;
    let
      # 默认发行版
      defaultSystem = "x86_64-linux";
      
      # 递归当前目录下的所有目录，获取其中的default.nix文件
      listNixFilesRecursive = dir:
        flatten (mapAttrsToList (name: type:
          let path = dir + "/${name}";
          in if type == "directory" then
            if pathExists (dir + "/${name}/default.nix") then
              path
            else
              listNixFilesRecursive path
          else if hasSuffix ".nix" name then
            path
          else
            [ ]) (readDir dir));
            
      # 根据default.nix中meta的platforms过滤发行系统
      filterBySystem = system: pkgs:
        filterAttrsRecursive (_: p:
          !(isDerivation p) || (if hasAttrByPath [ "meta" "platforms" ] p then
            elem system p.meta.platforms
          else
            system == defaultSystem)) pkgs;
            
      # 获取某个目录下的所有软件包
      getPackages = f: dir:
        let
          getAttrPathPrefix = target:
            filter (p: p != "") (splitString "/"
              (removePrefix (toString dir) (toString (dirOf target))));
          getName = target:
            let baseName = baseNameOf target;
            in if hasSuffix ".nix" baseName then
              removeSuffix ".nix" baseName
            else
              baseName;
          getAttrPath = target:
            ((getAttrPathPrefix target) ++ [ (getName target) ]);
        in foldl (set: target:
          recursiveUpdate set (setAttrByPath (getAttrPath target) (f target)))
        { } (listNixFilesRecursive dir);
        
      # 获取packages下的软件包
      makeUnfreePkgSet = f: getPackages f ./packages;
      
      # 为每个软件包都创建一个scope,并执行callPackage
      makeUnfreePkgScope = pkgs:
        makeScope pkgs.newScope (self:
          (makeUnfreePkgSet
            (n: self.callPackage n { } // { __definition_entry = n; })));
            
      # 把scope转为attrs
      mapRecurseIntoAttrs' = key: s:
        if any (k: k == key) (attrNames s) then
          s
        else
          mapAttrs (k: v:
            if !isAttrs v || isDerivation v then
              v
            else
              mapRecurseIntoAttrs' k v) (recurseIntoAttrs s);
      mapRecurseIntoAttrs = mapRecurseIntoAttrs' null;
    in eachDefaultSystem ( system_i:
      let
        pkgs = (import nixpkgs {
          inherit system_i;
          system = system_i;
          config.allowUnfree = true;
        });
        
        # 把polite-cat的pkgs和nixpkgs合并
        intree-packages = filterBySystem system_i (mapRecurseIntoAttrs (makeUnfreePkgScope pkgs));
      in rec {
        legacyPackages = intree-packages;
      }
    );
}

