{
  description = "jzbor's flake framework";

  outputs = { self }: {
    mkLib = import ./lib.nix;
    templates = import ./templates;
  };
}
