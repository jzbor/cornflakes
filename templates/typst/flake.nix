{
  description = "REPLACEME";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    cf.url = "github:jzbor/cornflakes";

    typix = {
      url = "github:loqusion/typix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, cf, typix, ... }: (cf.mkLib nixpkgs).flakeForDefaultSystems (system:
  let
    pkgs = nixpkgs.legacyPackages.${system};
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

    apps.default = self.apps.${system}.open;
    apps.open = {
      type = "app";
      program = pkgs.writeShellApplication {
        name = "open";
        text = "${pkgs.xdg-utils}/bin/xdg-open ${self.packages.${system}.default}";
      } + "/bin/open";
    };
  });
}
