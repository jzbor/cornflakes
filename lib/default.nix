nixpkgs:

nixpkgs.lib.fold (a: b: a // b) {} (map (x: import x nixpkgs) [
  ./attrsets.nix
  ./systems.nix
  ./withpkgs.nix
])

