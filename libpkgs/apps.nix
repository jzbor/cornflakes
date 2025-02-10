_: pkgs:

{
  createShellApp = attrs: let
    application = pkgs.writeShellApplication attrs;
  in {
    type = "app";
    program = "${application}/bin/${attrs.name}";
  };
}
