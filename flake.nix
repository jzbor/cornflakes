{
  description = "jzbor's flake framework";

  outputs = _: rec {
    lib = import ./lib.nix;
    mkLib = lib.withPkgs;
    templates = import ./templates;
  };
}
