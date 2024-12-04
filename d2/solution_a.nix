{ inputFile }:
let
    pkgs = import <nixpkgs> {};
    inherit (pkgs.lib.strings) splitString trim toInt;
    inherit (pkgs.lib.lists) zipLists drop;
    inherit (builtins) foldl' readFile all any;
    content = readFile inputFile
        |> trim
        |> splitString "\n"
        |> map (splitString " ")
        |> map (map toInt);
    sign = n: if n > 0 then 1 else if n < 0 then -1 else 0;
    abs = n: if n < 0 then -n else n;
    pairWise = lst: zipLists lst (drop 1 lst);
    diff = lst: pairWise lst |> map (e: e.snd - e.fst);
    isSafe = lst:
        (all (n: sign n == 1) lst || all (n: sign n == -1) lst)
        && !(any (n: n > 3) (map abs lst));
in
    content
    |> map diff
    |> map isSafe
    |> foldl' (acc: v: if v then acc + 1 else acc) 0
