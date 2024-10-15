{
  description = "REPLACEME";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    cf.url = "github:jzbor/cornflakes";
  };

  outputs = { self, nixpkgs, cf, ... }: (cf.mkLib nixpkgs).flakeForDefaultSystems (system:
  let
    pkgs = nixpkgs.legacyPackages.${system};
  in {
    packages.default = pkgs.hello;

    devShells.default = pkgs.mkShellNoCC {
      inherit (self.packages.${system}.default) name;
      nativeBuildInputs = [ pkgs.hello ];
    };
  });
}
