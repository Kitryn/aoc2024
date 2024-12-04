{ inputFile }:
let
    pkgs = import <nixpkgs> {};
    inherit (builtins) readFile;
    inherit (pkgs.lib.strings) trim;
    inherit (pkgs.lib.lists);
    content = readFile inputFile |> trim;
in
    content
