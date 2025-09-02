{
  description = "REPLACEME";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    cf.url = "github:jzbor/cornflakes";
  };

  outputs = inputs: inputs.cf.lib.mkFlake {
    inherit inputs;
    perSystem = { cfLib, ... }@args: cfLib.subdirsToAttrsFn ./nix args;
  };
}
