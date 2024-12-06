{ inputFile }:
let 
    pkgs = import <nixpkgs> {};
    inherit (builtins) 
        readFile foldl' length head tail elem attrValues attrNames listToAttrs elemAt toString;
    inherit (pkgs.lib.strings) 
        trim splitString toInt stringToCharacters;
    inherit (pkgs.lib.lists) 
        flatten unique singleton imap1 reverseList zipLists imap0 range;
    inherit (pkgs.lib.attrsets);
    inherit (pkgs.lib.trivial);
    inherit (pkgs.lib.debug)
        traceSeq;
    # debugPrint = x: builtins.trace ("debug") x |> traceSeq x;
    debugPrintBoard = state:
        let
            printRow = row: foldl' (acc: idx: acc + row.${toString idx}) "" (range 0 (maxX - 1));
            printBoard = board: foldl' (acc: idx: acc + printRow board.${toString idx} + "\n") "" (range 0 (maxY - 1));
        in traceSeq (printBoard state.board) state;
    content = readFile inputFile
        |> trim
        |> splitString "\n"
        |> map (stringToCharacters)
        |> imap0 (
            yPos: row: { 
                name = toString yPos; 
                value = listToAttrs (imap0 (xPos: c: { name = toString xPos; value = c; }) row);
            })
        |> listToAttrs;
    maxX = attrNames content.${"0"} |> length;
    maxY = attrNames content |> length;
    charAt = board: x: y: board.${toString y}.${toString x};
    xPos = row: 
        foldl' (pos: idx: if pos >= 0 then pos else if row.${toString idx} == "^" then idx else -1) (-1) (range 0 (maxX - 1));
    startingPoint = 
        foldl' (pos: yIdx:
            let 
                row = content.${toString yIdx}; 
                x' = xPos row;
            in if x' >= 0 then { curX = x'; curY = yIdx; } else pos
        ) { curX = -1; curY = -1; } (range 0 (maxY - 1));
    directions = {
        "^" = { dx = 0; dy = -1; };
        "v" = { dx = 0; dy = 1; };
        "<" = { dx = -1; dy = 0; };
        ">" = { dx = 1; dy = 0; };
    };
    setAt = board: x: y: v:
        let
            yIdx = toString y;
            xIdx = toString x;
            row = board.${yIdx};
        in
            board // { ${yIdx} = row // { ${xIdx} = v; }; };
    iterState = { curX, curY, ... }@state:
        let
            direction = directions.${charAt state.board curX curY};
            newX = curX + direction.dx;
            newY = curY + direction.dy;
            willEnd = (newX < 0 || newX >= maxX || newY < 0 || newY >= maxY);
            right = {
                "^" = ">";
                ">" = "v";
                "v" = "<";
                "<" = "^";
            };
            doMove = board: x: y: newX: newY:
                let
                    curChar = charAt board x y;
                    destination = charAt board newX newY;
                    newChar = if destination == "#" then right.${curChar} else curChar;
                    newX' = if destination == "#" then x else newX;
                    newY' = if destination == "#" then y else newY;
                in
                {
                    board = setAt board x y "a" |> (board: setAt board newX' newY' newChar);
                    curX = newX';
                    curY = newY';
                };
            newBoard = if state.done then state else
            if willEnd then (state // { done = willEnd; board = setAt state.board curX curY "a"; })
            else ({ done = false; } // doMove state.board curX curY newX newY);
        in newBoard;
    run = state:
        if state.done then state
        else run (iterState state);
    countScore = board:
        foldl' (score: y: 
            let yIdx = toString y; in
            score + foldl' (score: x: 
                let c = board.${yIdx}.${toString x}; in
                if c == "a" then score + 1 else score) 0 (range 0 (maxX - 1))
        ) 0 (range 0 (maxY - 1));
in
    run { board = content; done = false; curX = startingPoint.curX; curY = startingPoint.curY; }
    |> (state: countScore state.board)
