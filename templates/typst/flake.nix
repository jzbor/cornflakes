{
  description = "REPLACEME";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";

    cf = {
      url = "github:jzbor/cornflakes";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    typix = {
      url = "github:loqusion/typix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { nixpkgs, cf, typix, ... }: (cf.mkLib nixpkgs).flakeForDefaultSystems (system:
  let
    #pkgs = nixpkgs.legacyPackages.${system};
    typixLib = typix.lib.${system};
    fontPaths = [
      #"${pkgs.noto}/share/fonts/noto"
    ];
  in {
    packages.default = typixLib.buildTypstProject {
      src = typixLib.cleanTypstSource ./.;
      typstSource = "main.typ";
      inherit fontPaths;
    };

    devShells.default = typixLib.devShell {
      inherit fontPaths;

      # Additional packages
      packages = [];
    };
  });
}
