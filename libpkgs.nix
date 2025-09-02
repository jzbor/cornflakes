pkgs:

with builtins;
with pkgs.lib;
with (import ./lib.nix);
rec {
  ### PACKAGES ###
  createPackageWithStdenvs = package: defaultStdenv: extraStdenvs: listToAttrs ([{
    inherit (package) name;
    value = defaultStdenv.mkDerivation package;
  }] ++ attrsets.mapAttrsToList (stdenvName: stdenv: {
    name = "${package.name}-${stdenvName}";
    value = stdenv.mkDerivation package;
  }) extraStdenvs);

  createPackages = args: packages:
  let
    stdenv = args.stdenv or pkgs.stdenv;
    extraStdenvs = args.extraStdenvs or {};
  in combineAttrs (attrsets.mapAttrsToList (n: v: createPackageWithStdenvs (v // { name = n; }) stdenv extraStdenvs) packages);

  packageAliases = flake: system: aliases: mapAttrs (_: v: flake.packages."${system}"."${v}") aliases;


  ### SHELLS ###
  createShellWithStdenvs = shell: defaultStdenv: extraStdenvs: listToAttrs ([{
    inherit (shell) name;
    value = pkgs.mkShell.override { stdenv = defaultStdenv; } (shell // {
      shellHook = "export ENV_NAME=${shell.name}" + "\n" + (shell.shellHook or "");
    });
  }] ++ mapAttrsToList (stdenvName: stdenv: {
    name = "${shell.name}-${stdenvName}";
    value = pkgs.mkShell.override { inherit stdenv; } (shell // {
      shellHook = "export ENV_NAME=${shell.name}-${stdenvName}" + "\n" + (shell.shellHook or "");
    });
  }) extraStdenvs);

  createShells = args: shells:
  let
    stdenv = args.stdenv or pkgs.stdenv;
    extraStdenvs = args.extraStdenvs or {};
  in combineAttrs (attrsets.mapAttrsToList (n: v: createShellWithStdenvs (v // { name = n; }) stdenv extraStdenvs) shells);

  shellAliases = flake: system: aliases: mapAttrs (_: v: flake.devShells."${system}"."${v}") aliases;
} // (import ./lib.nix)

