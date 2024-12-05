{ inputFile }:
let 
    pkgs = import <nixpkgs> {};
    inherit (builtins) readFile foldl' length head tail elem attrValues attrNames listToAttrs elemAt filter;
    inherit (pkgs.lib.strings) trim splitString toInt;
    inherit (pkgs.lib.lists) flatten unique singleton imap1 reverseList zipLists take drop;
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
    isSorted = lst: foldl' (acc: node: if !acc then false else before node.fst node.snd) true (pairWise lst);
    onlyUnsorted = filter (lst: !isSorted lst) trials;
    fixUnsorted = lst:
        let
            inner = lst':
                if length lst' <= 1 then lst'
                else let head' = take 2 lst'; in
                if before (elemAt head' 0) (elemAt head' 1)
                then [(elemAt head' 0)] ++ (inner (drop 1 lst'))
                else [(elemAt head' 1)] ++ (inner ([(elemAt head' 0)] ++ drop 2 lst'));
            fixed = inner lst;
        in
        if isSorted fixed then fixed else fixUnsorted fixed;
    allFixed = onlyUnsorted |> map fixUnsorted;
in
    allFixed
    |> map getMiddle
    |> foldl' (acc: node: acc + (toInt node)) 0
