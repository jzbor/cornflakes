{
  description = "jzbor's flake framework";
  inputs = {
    nixpkgs.url = "nixpkgs";
  };

  outputs = { self, nixpkgs }@inputs:
  let
    lib = import ./lib.nix { inherit (nixpkgs) lib; inherit nixpkgs; };
    getPkgs = system: nixpkgs.legacyPackages."${system}";
  in ((lib.flakeForDefaultSystems (system:
  let
    pkgs = nixpkgs.legacyPackages."${system}";
    stdenvs = {
      gcc = pkgs.gccStdenv;
      clang = pkgs.clangStdenv;
    };
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
    }) // {
      gitlab-ci = lib.generateGitlabCITrigger self system "gitlab-ci-dyn";
      gitlab-ci-dyn = lib.generateDynGitlabCI self system;
    };
  })) // {
    inherit lib;
  });
}



