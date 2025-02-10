nixpkgs: pkgs:

nixpkgs.lib.fold (a: b: a // b) {} (map (x: import x nixpkgs pkgs) [
  ./packages.nix
  ./shells.nix
  ./apps.nix
])


