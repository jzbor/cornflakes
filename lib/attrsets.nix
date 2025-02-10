nixpkgs:
{
  ### ATTRSETS ###
  combineAttrs = nixpkgs.lib.attrsets.foldAttrs (a: b: nixpkgs.lib.attrsets.recursiveUpdate a b) {};


}
