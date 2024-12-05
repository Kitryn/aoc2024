{ inputFile }:
let 
    pkgs = import <nixpkgs> {};
    inherit (builtins) readFile foldl' length head tail elem attrValues attrNames listToAttrs elemAt;
    inherit (pkgs.lib.strings) trim splitString toInt;
    inherit (pkgs.lib.lists) flatten unique singleton imap1 reverseList zipLists;
    inherit (pkgs.lib.attrsets);
    inherit (pkgs.lib.trivial);
    content = readFile inputFile
        |> trim
        |> splitString "\n";
    rules = 
        foldl' (acc: line:
            let 
                parts = splitString "|" line;
                parent = head parts;
                children = tail parts;
            in
            if length parts != 2 then acc
            else acc // { ${parent} = (acc.${parent} or []) ++ children; }
        ) {} content;
    trials =
        foldl' (acc: line:
            let
                parts = splitString "," line;
            in
            if length parts == 1 then acc
            else acc ++ [parts]
        ) [] content;
    before = a: b: elem b (rules.${a} or []);
    pairWise = lst: zipLists lst (tail lst);
    getMiddle = lst:
        let len = length lst; in
        elemAt lst (len / 2);
in
    trials
    |> map (lst: foldl' (isSorted: node: if !isSorted then false else before node.fst node.snd) true (pairWise lst))
    |> zipLists trials
    |> foldl' (acc: elem: if !elem.snd then acc else acc + (toInt (getMiddle elem.fst))) 0
