nixpkgs:

let
  inherit (import ./attrsets.nix nixpkgs) combineAttrs;
in rec {
  defaultSystems = [ "aarch64-linux" "aarch64-darwin" "x86_64-darwin" "x86_64-linux" ];

  foreachSystem = systems: content: nixpkgs.lib.listToAttrs (map (name: {
    inherit name;
    value = content name;
  }) systems);
  foreachDefaultSystem = foreachSystem defaultSystems;

  flakeForSystems = systems: flake: combineAttrs (
    nixpkgs.lib.flatten (
      map (system: nixpkgs.lib.attrsets.mapAttrsToList (
        attrName: attrValue: {
          ${attrName}.${system} = attrValue;
        }) (flake system)) systems));

  flakeForDefaultSystems = flakeForSystems defaultSystems;

  mkPkgs = nixpkgs: system: nixpkgs.legacyPackages."${system}";
}
