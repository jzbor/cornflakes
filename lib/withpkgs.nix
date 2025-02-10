nixpkgs:

{
  withPkgs = pkgs: (import ../lib nixpkgs) // (import ../libpkgs nixpkgs pkgs);
}

