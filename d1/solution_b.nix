{ inputFile }:
let
    pkgs = import <nixpkgs> {};
    inherit (pkgs.lib.strings) splitString trim toInt;
    inherit (builtins) intersectAttrs foldl' getAttr elemAt attrValues readFile mapAttrs groupBy length;
    content = readFile inputFile;
    unzip = pairs: [
        (map (p: elemAt p 0) pairs)
        (map (p: elemAt p 1) pairs)
    ];
    sum = foldl' (acc: elem: acc + elem) 0;
    calcDistance = xs:
        let
            nums1 = elemAt xs 0;
            nums2 = elemAt xs 1;
        in
        intersectAttrs nums2 nums1
        |> mapAttrs (key: value: toInt key * value * (getAttr key nums2))
        |> attrValues
        |> sum;
in
    content
    |> trim
    |> splitString "\n"
    |> map (splitString "   ")
    |> unzip
    |> map (groupBy (p: p))
    |> map (mapAttrs (name: values: length values))
    |> calcDistance
    # |> builtins.toJSON
