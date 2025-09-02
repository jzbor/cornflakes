with builtins;
rec {
  ### WITHPKGS ###
  withPkgs = pkgs: import ./libpkgs.nix pkgs;


  ### LISTS ###
  # From nixpkgs.lib
  foldr =
    op: nul: list:
    let
      len = length list;
      fold' = n: if n == len then nul else op (elemAt list n) (fold' (n + 1));
    in
    fold' 0;
  flatten = x: if isList x then concatMap (y: flatten y) x else [ x ];


  ### ATTRSETS ###
  combineAttrs = foldAttrs (a: b: recursiveUpdate a b) {};

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

  dirToAttrsFn = path: args: mapAttrs (_: x: x args) (dirToAttrs path);

  dirsToAttrs = paths: let
    deepAttrs = map (path: { ${baseNameOf path} = dirToAttrs path; }) paths;
  in combineAttrs deepAttrs;
  dirsToAttrsFn = paths: args: let
    deepAttrs = map (path: { ${baseNameOf path} = dirToAttrsFn path args; }) paths;
  in combineAttrs deepAttrs;

  subdirsToAttrs = path: let
    dirs = attrNames (filterAttrs (_: type: type == "directory") (readDir path));
  in dirsToAttrs (map (sub: path + "/${sub}") dirs);
  subdirsToAttrsFn = path: let
    dirs = attrNames (filterAttrs (_: type: type == "directory") (readDir path));
  in dirsToAttrsFn (map (sub: path + "/${sub}") dirs);


  # From nixpkgs.lib
  filterAttrs = pred: set: removeAttrs set (filter (name: !pred name set.${name}) (attrNames set));
  mapAttrs' = f: set: listToAttrs (mapAttrsToList f set);
  mapAttrsToList = f: attrs: attrValues (mapAttrs f attrs);
  foldAttrs =
    op: nul: list_of_attrs:
    foldr (
      n: a: foldr (name: o: o // { ${name} = op n.${name} (a.${name} or nul); }) a (attrNames n)
      ) { } list_of_attrs;
  recursiveUpdate =
    lhs: rhs:
    recursiveUpdateUntil (
      path: lhs: rhs:
      !(isAttrs lhs && isAttrs rhs)
      ) lhs rhs;
  recursiveUpdateUntil =
    pred: lhs: rhs:
    let
      f =
        attrPath:
        zipAttrsWith (
          n: values:
          let
            here = attrPath ++ [ n ];
          in
          if length values == 1 || pred here (elemAt values 1) (head values) then
            head values
          else
            f here values
        );
    in
    f [ ] [ rhs lhs ];
  mapCartesianProduct = f: attrsOfLists: map f (cartesianProduct attrsOfLists);


  ### FLAKES ###
  defaultSystems = [ "aarch64-linux" "aarch64-darwin" "x86_64-darwin" "x86_64-linux" ];

  foreachSystem = systems: content: listToAttrs (map (name: {
    inherit name;
    value = content name;
  }) systems);
  foreachDefaultSystem = foreachSystem defaultSystems;

  flakeForSystems = systems: flake: combineAttrs (
    flatten (
      map (system: mapAttrsToList (
        attrName: attrValue: {
          ${attrName}.${system} = attrValue;
        }) (flake system)) systems));

  flakeForDefaultSystems = flakeForSystems defaultSystems;

  mkPkgs = nixpkgs: system: nixpkgs.legacyPackages."${system}";

  mkFlake = args: let
    cfLib = import ./lib.nix;
    defaultArgs = {
      inputs = {};
      systems = [ "x86_64-linux" "aarch64-linux" ];
      perSystem = _: {};
      outputs = _: {};
    };
    finalArgs = defaultArgs // args // (
      if !(args ? nixpkgs) && args ? inputs && args.inputs ? nixpkgs
      then { inherit (args.inputs) nixpkgs; }
      else {}
    );
    perSystemOutputs = combineAttrs (map (system:
      mapAttrs' (attrName: attrValue: {
        name = attrName;
        value.${system} = attrValue;
      }) (finalArgs.perSystem (
        {
          inherit (finalArgs) inputs;
        } // (
          if finalArgs ? nixpkgs
          then { pkgs = mkPkgs finalArgs.nixpkgs system; }
          else {}
        ) // (
          if finalArgs ? nixpkgs
          then { cfLib = cfLib.withPkgs (mkPkgs finalArgs.nixpkgs system); }
          else { inherit cfLib; }
        )
      )
    )) finalArgs.systems);
    otherOutputs = finalArgs.outputs {
      inherit (finalArgs) inputs;
      inherit cfLib;
    };
  in perSystemOutputs // otherOutputs;
}

