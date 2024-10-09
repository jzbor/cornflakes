{
  description = "jzbor's flake framework";

  outputs = _: {
    mkLib = import ./lib.nix;
    templates = import ./templates;
  };
}
