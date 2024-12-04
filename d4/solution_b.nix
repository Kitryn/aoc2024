{ inputFile }:
let
    pkgs = import <nixpkgs> {};
    inherit (builtins) 
        readFile elemAt foldl' length attrValues;
    inherit (pkgs.lib.strings) 
        trim splitString stringToCharacters;
    inherit (pkgs.lib.lists) imap0 flatten;
    content = readFile inputFile 
        |> trim
        |> splitString "\n"
        |> map stringToCharacters;
    maxX = length (elemAt content 0);
    maxY = length content;
    directions = {
        upRight = { dx = 1; dy = -1; };
        downRight = { dx = 1; dy = 1; };
        downLeft = { dx = -1; dy = 1; };
        upLeft = { dx = -1; dy = -1; };
    };
    lookup = x: y: elemAt (elemAt content y) x;
    isMatch = c: x: y: lookup x y == c;
    searchSingle = { dx, dy }: { curX, curY }:
        # bounds checks
        (curX + dx >= 0 && curX + dx < maxX && curY + dy >= 0 && curY + dy < maxY)
        && (curX - dx >= 0 && curX - dx < maxX && curY - dy >= 0 && curY - dy < maxY)
        && isMatch "M" (curX + dx) (curY + dy)
        && isMatch "S" (curX - dx) (curY - dy);
    search = { curX, curY }@args:
        if (lookup curX curY) != "A" then 0
        else
        map (fn: fn args) (map (searchSingle) (attrValues directions))
        |> foldl' (acc: v: if v then acc + 1 else acc) 0;
in
    content 
    |> imap0 (y: row: imap0 (x: _: search { curX = x; curY = y; }) row)
    |> flatten
    |> foldl' (acc: v: if v == 2 then acc + 1 else acc) 0
