{ nixpkgs, lib }:

with lib;
with builtins;
let
  getPkgs = system: nixpkgs.legacyPackages.${system};
in rec {
  ### ATTRSETS ###
  combineAttrs = attrsets.foldAttrs (a: b: a // b) {};


  ### SYSTEMS ###
  defaultSystems = [ "aarch64-linux" "aarch64-darwin" "x86_64-darwin" "x86_64-linux" ];

  foreachSystem = systems: content: listToAttrs (map (name: {
    inherit name;
    value = content name;
  }) systems);
  foreachDefaultSystem = foreachSystem defaultSystems;

  flakeForSystems = systems: flake: combineAttrs (flatten (map (system: attrsets.mapAttrsToList (attrName: attrValue: {
    ${attrName}.${system} = attrValue;
  }) (flake system)) systems));

  flakeForDefaultSystems = flakeForSystems defaultSystems;


  ### SHELLS ###
  createShellWithStdenvs = shell: defaultStdenv: extraStdenvs: system: listToAttrs ([{
    name = shell.name;
    value = (getPkgs system).mkShell.override { stdenv = defaultStdenv; } (shell // {
      shellHook = "export ENV_NAME=${shell.name}" + "\n" + (shell.shellHook or "");
    });
  }] ++ attrsets.mapAttrsToList (stdenvName: stdenv: {
    name = "${shell.name}-${stdenvName}";
    value = (getPkgs system).mkShell.override { stdenv = stdenv; } (shell // {
      shellHook = "export ENV_NAME=${shell.name}-${stdenvName}" + "\n" + (shell.shellHook or "");
    });
  }) extraStdenvs);

  createShells = args: shells:
  let
    system = args.system;
    stdenv = args.stdenv or (getPkgs system).stdenv;
    extraStdenvs = args.extraStdenvs or {};
  in combineAttrs (attrsets.mapAttrsToList (n: v: createShellWithStdenvs (v // { name = n; }) stdenv extraStdenvs system) shells);

  shellAliases = flake: system: aliases: mapAttrs (n: v: flake.devShells."${system}"."${v}") aliases;


  ### PACKAGES ###
  createPackageWithStdenvs = package: defaultStdenv: extraStdenvs: system: listToAttrs ([{
    name = package.name;
    value = defaultStdenv.mkDerivation package;
  }] ++ attrsets.mapAttrsToList (stdenvName: stdenv: {
    name = "${package.name}-${stdenvName}";
    value = stdenv.mkDerivation package;
  }) extraStdenvs);

  createPackages = args: packages:
  let
    system = args.system;
    stdenv = args.stdenv or (getPkgs system).stdenv;
    extraStdenvs = args.extraStdenvs or {};
  in combineAttrs (attrsets.mapAttrsToList (n: v: createPackageWithStdenvs (v // { name = n; }) stdenv extraStdenvs system) packages);

  packageAliases = flake: system: aliases: mapAttrs (n: v: flake.packages."${system}"."${v}") aliases;


  ### CI ###
  generateGitlabCITrigger = flake: system: ciPkgName: let
    ciImage = "nixos/nix";
    ciFile = "gitlab-ci.yml";
    discoverStage = "discover";
    content = ''
      image: nixos/nix

      stages:
      - ${discoverStage}

      before_script:
      - mkdir -vp ~/.config/nix
      - echo "experimental-features = nix-command flakes" > ~/.config/nix/nix.conf

      discover:
        stage: discover
        script:
          - nix build ".#${ciPkgName}"
          - cp result/${ciFile} ./${ciFile}
        trigger:
          include:
            - local: ./${ciFile}
          strategy: depend

    '';
  in (getPkgs system).stdenv.mkDerivation {
    name = "gitlab-ci";
    dontUnpack = true;
    buildPhase = ''
      mkdir $out
      cp "${toFile "${ciFile}" content}" $out/${ciFile}
    '';
  };
  generateDynGitlabCI = flake: system: let
    ciImage = "nixos/nix";
    ciFile = "dynamic-gitlab-ci.yml";
    packages = attrNames flake.outputs.packages."${system}";
    header = ''
      image: nixos/nix

      stages:
      - discover

      before_script:
      - mkdir -vp ~/.config/nix
      - echo "experimental-features = nix-command flakes" > ~/.config/nix/nix.conf
    '';
    builds = concatStringsSep "\n" (map (package: ''
      ${dynamicStage}:${package}:
        stage: ${dynamicStage}
        script:
          - nix build .#${package} -o result-${package}
        artifacts:
          paths:
            - result-${package}
    '') packages);
    content = concatStringsSep "\n" [ header builds ];
  in (getPkgs system).stdenv.mkDerivation {
    name = "gitlab-ci";
    dontUnpack = true;
    buildPhase = ''
      mkdir $out
      cp "${toFile "${ciFile}" content}" $out/${ciFile}
    '';
  };
}
