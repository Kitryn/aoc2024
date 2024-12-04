{ inputFile }:
let
    pkgs = import <nixpkgs> {};
    inherit (pkgs.lib.strings) splitString trim toInt;
    inherit (pkgs.lib.lists) zipLists take drop reverseList;
    inherit (builtins) foldl' readFile all any elemAt length;
    content = readFile inputFile
        |> trim
        |> splitString "\n"
        |> map (splitString " ")
        |> map (map toInt);
    sign = n: if n > 0 then 1 else if n < 0 then -1 else 0;
    abs = n: if n < 0 then -n else n;
    predicate = initSign: n1: n2:
        let
            difference = n2 - n1;
        in
            (sign difference == initSign)
            && 
            (abs difference <= 3);
    isSafeRec = trial: initSign: idx: lst:
        if trial > 1
        then false
        else if initSign == 0
        then isSafe (trial + 1) (drop 1 lst)
        else if idx == length lst - 1
        then true
        else if predicate initSign (elemAt lst idx) (elemAt lst (idx + 1)) 
        then isSafeRec trial initSign (idx + 1) lst
        else 
            (isSafe (trial + 1) (take idx lst ++ drop (idx + 1) lst))
            || (isSafe (trial + 1) (take (idx + 1) lst ++ drop (idx + 2) lst));
    isSafe = trial: lst:
        let revLst = reverseList lst;
        in
        (isSafeRec trial (sign (elemAt lst 1 - elemAt lst 0)) 0 lst)
        || (isSafeRec trial (sign (elemAt revLst 1 - elemAt revLst 0)) 0 revLst);
in
    content
    |> map (isSafe 0)
    |> foldl' (acc: v: if v then acc + 1 else acc) 0
