{
  description = "jzbor's flake framework";
  inputs.nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";

  outputs = { self, nixpkgs }:
  (((import ./lib.nix nixpkgs).flakeForDefaultSystems (system:
  with builtins;
  let
    pkgs = nixpkgs.legacyPackages."${system}";
    lib = import ./lib.nix nixpkgs;
  in {

    ### EXAMPLES ###
    devShells = lib.createShells {
      inherit system;
      extraStdenvs.clang = pkgs.clangStdenv;
    } {
      example = {
        nativeBuildInputs = [ pkgs.hello ];
      };
    };

    packages = (lib.createPackages {
      inherit system;
      extraStdenvs.clang = pkgs.clangStdenv;
    } {
      example = {
        nativeBuildInputs = [ pkgs.hello ];
        src = "${self}";
        installPhase = ''
          mkdir -p $out
          hello > $out/hello.out
        '';
      };
    }) // (lib.packageAliases self system {
      default = "example";
    });

    ### APPS ###
    apps.gitlab-ci-discover = lib.createShellApp system {
      name = "gitlab-ci-discover";
      text = readFile ./scripts/gitlab-ci-discover.sh;
      runtimeInputs = with pkgs; [ jq gnused ];
    };

    apps.add-gitlab-ci = lib.createShellApp system {
      name = "add-gitlab-ci";
      text = "cp -vi ${self}/gitlab-ci/gitlab-ci.yml .gitlab-ci.yml";
    };
  })) // {
    mkLib = import ./lib.nix;
  });
}



