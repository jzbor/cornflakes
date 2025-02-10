nixpkgs: pkgs:

rec {
  createShellWithStdenvs = shell: defaultStdenv: extraStdenvs: nixpkgs.lib.listToAttrs ([{
    inherit (shell) name;
    value = pkgs.mkShell.override { stdenv = defaultStdenv; } (shell // {
      shellHook = "export ENV_NAME=${shell.name}" + "\n" + (shell.shellHook or "");
    });
  }] ++ nixpkgs.lib.attrsets.mapAttrsToList (stdenvName: stdenv: {
    name = "${shell.name}-${stdenvName}";
    value = pkgs.mkShell.override { inherit stdenv; } (shell // {
      shellHook = "export ENV_NAME=${shell.name}-${stdenvName}" + "\n" + (shell.shellHook or "");
    });
  }) extraStdenvs);

  createShells = args: shells:
  let
    stdenv = args.stdenv or pkgs.stdenv;
    extraStdenvs = args.extraStdenvs or {};
  in nixpkgs.lib.combineAttrs (nixpkgs.lib.attrsets.mapAttrsToList (n: v: createShellWithStdenvs (v // { name = n; }) stdenv extraStdenvs) shells);

  shellAliases = flake: system: aliases: nixpkgs.lib.mapAttrs (_: v: flake.devShells."${system}"."${v}") aliases;
}
