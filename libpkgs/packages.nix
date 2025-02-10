nixpkgs: pkgs:

rec {
  createPackageWithStdenvs = package: defaultStdenv: extraStdenvs: nixpkgs.lib.listToAttrs ([{
    inherit (package) name;
    value = defaultStdenv.mkDerivation package;
  }] ++ nixpkgs.lib.attrsets.mapAttrsToList (stdenvName: stdenv: {
    name = "${package.name}-${stdenvName}";
    value = stdenv.mkDerivation package;
  }) extraStdenvs);

  createPackages = args: packages:
  let
    stdenv = args.stdenv or pkgs.stdenv;
    extraStdenvs = args.extraStdenvs or {};
  in nixpkgs.lib.combineAttrs (nixpkgs.lib.attrsets.mapAttrsToList (n: v: createPackageWithStdenvs (v // { name = n; }) stdenv extraStdenvs) packages);

  packageAliases = flake: system: aliases: nixpkgs.lib.mapAttrs (_: v: flake.packages."${system}"."${v}") aliases;
}
