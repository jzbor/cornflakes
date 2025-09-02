nixpkgs:

with builtins;
with nixpkgs.lib;
{
  combineAttrs = attrsets.foldAttrs (a: b: attrsets.recursiveUpdate a b) {};

  dirToAttrs = path: let
    files = readDir path;
    filterId = "__cf_filter";
    mapped = mapAttrs' (name: type: {
      name = (
        if type == "regular" && stringLength name > 4 && substring ((stringLength name) - 4) 4 name == ".nix"
        then substring 0 ((stringLength name) - 4) name
        else name
        );
      value = (
        if type == "regular" && stringLength name > 4 && substring ((stringLength name) - 4) 4 name == ".nix"
        then import (path + "/${name}")
        else if type == "directory" && pathExists (path + "/${name}/default.nix")
        then import (path + "/${name}/default.nix")
        else filterId
      );
    }) files;
    filtered = filterAttrs (n: v: v != filterId) mapped;
  in filtered;

  dirToAttrsFn = path: args: map (x: x args) (dirToAttrs path);
}
