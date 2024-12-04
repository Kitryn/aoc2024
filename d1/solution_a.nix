{ inputFile }:
let
    pkgs = import <nixpkgs> {};
    inherit (pkgs.lib.strings) splitString trim toInt;
    inherit (pkgs.lib.lists) zipLists;
    inherit (builtins) intersectAttrs foldl' getAttr elemAt attrValues readFile mapAttrs groupBy length sort lessThan;
    content = readFile inputFile
        |> trim
        |> splitString "\n"
        |> map (splitString "   ")
        |> map (map toInt);
    unzip = pairs: [
        (map (p: elemAt p 0) pairs)
        (map (p: elemAt p 1) pairs)
    ];
    sign = n: if n > 0 then 1 else if n < 0 then -1 else 0;
    abs = n: n * sign n;
    sum = foldl' (acc: elem: acc + elem) 0;
in
    content
    |> unzip
    |> map (sort lessThan)
    |> (lst: zipLists (elemAt lst 0) (elemAt lst 1))
    |> map (pair: abs (pair.fst - pair.snd))
    |> sum
