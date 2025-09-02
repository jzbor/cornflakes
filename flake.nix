{
  description = "jzbor's flake framework";

  outputs = inputs: {
    lib = import ./lib.nix;
    mkLib = pkgs: (import ./lib/withpkgs.nix inputs.nixpkgs).withPkgs pkgs;
    templates = import ./templates;
  };
}
