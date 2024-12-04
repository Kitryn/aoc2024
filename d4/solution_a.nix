{ inputFile }:
let
    pkgs = import <nixpkgs> {};
    inherit (builtins) 
        readFile elemAt getAttr foldl' all attrNames length add;
    inherit (pkgs.lib.strings) 
        trim splitString stringToCharacters;
    inherit (pkgs.lib.lists) imap0;
    inherit (pkgs.lib.trivial) id;
    content = readFile inputFile 
        |> trim
        |> splitString "\n"
        |> map stringToCharacters;
    maxX = length (elemAt content 0);
    maxY = length content;
    target = ["X" "M" "A" "S"];
    directions = {
        right = { dx = 1; dy = 0; };
        down = { dx = 0; dy = 1; };
        left = { dx = -1; dy = 0; };
        up = { dx = 0; dy = -1; };
        upRight = { dx = 1; dy = -1; };
        downRight = { dx = 1; dy = 1; };
        downLeft = { dx = -1; dy = 1; };
        upLeft = { dx = -1; dy = -1; };
    };
    isMatch = c: x: y: c == elemAt (elemAt content y) x;
    search = direction: { curX, curY }:
        imap0 (i: c: 
            let 
            inherit(getAttr direction directions) dx dy;
            x' = i * dx + curX;
            y' = i * dy + curY;
            in 
            if y' >= maxY || y' < 0 || x' >= maxX || x' < 0
            then false
            else isMatch c x' y'
        ) target |> all id;
    searches = { curX, curY }@args:
        map (fn: fn args) (map search (attrNames directions))
        |> foldl' (acc: v: if v then acc + 1 else acc) 0;
in
    content 
    |> builtins.trace (toString content)
    |> builtins.trace (toString (length content))
    |> imap0 (y: row: imap0 (x: c: 
        if c == "X" then searches { curX = x; curY = y; } else 0
        ) row)
    |> map (foldl' add 0)
    |> foldl' add 0
