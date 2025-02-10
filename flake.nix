{
  description = "jzbor's flake framework";

  inputs.nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";

  outputs = inputs: {
    lib = import ./lib inputs.nixpkgs;
    mkLib = pkgs: (import ./lib/withpkgs.nix inputs.nixpkgs).withPkgs pkgs;
    templates = import ./templates;
  };
}
