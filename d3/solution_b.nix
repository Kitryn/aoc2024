{ inputFile }:
let
    pkgs = import <nixpkgs> {};
    inherit (pkgs.lib.strings) trim toInt;
    inherit (pkgs.lib.lists) drop range foldl flatten;
    inherit (builtins) foldl' readFile tryEval substring stringLength concatStringsSep head tail elemAt;
    sum = foldl' (acc: elem: acc + elem) 0;
    content = readFile inputFile
            |> trim;
    satisfy = pred: str:
        if str == "" then { rest = str; }
        else if pred (substring 0 1 str)
        then {
            result = substring 0 1 str;
            rest = substring 1 (stringLength str) str;
        }
        else { rest = str; };
    seq = p1: p2: str:
        let r1 = p1 str; in
        if r1 ? result
        then let r2 = p2 r1.rest; in 
            if r2 ? result
            then {
                result = [r1.result r2.result];
                rest = r2.rest;
            }
            else { rest = str; }
        else { rest = str; };
    lift = p: str:
        let r = p str; in
        if r ? result
        then {
            result = [r.result];
            rest = r.rest;
        }
        else { rest = str; };
    compose = ps: 
        let lps = map lift ps;
        in
        foldl (f: g: x:
            let r = seq f g x; in
                if r ? result then r // { result = flatten r.result; }
            else r
        ) (head lps) (tail lps);
    manyRec = maxDepth: curDepth: p: str:
        if curDepth >= maxDepth then {
            rest = str;
        }
        else let r = p str; in
        if r ? result
        then let rest = manyRec maxDepth (curDepth + 1) p r.rest; in {
            result = [r.result] ++ (rest.result or []);
            rest = rest.rest;
        }
        else { rest = str; };
    many = maxDepth: p: str: manyRec maxDepth 0 p str;
    isDigit = satisfy (x: (tryEval (toInt x)).success);
    isDigits = str: 
        let
            res = many 3 isDigit str;
        in 
        if res ? result then {
            result = toInt (concatStringsSep "" res.result);
            rest = res.rest;
        } else {
            rest = str;
        };
    isComma = satisfy (x: x == ",");
    isOpenParen = satisfy (x: x == "(");
    isCloseParen = satisfy (x: x == ")");
    isMulFnName = str:
        if str == "" then { rest = str; }
        else if substring 0 3 str == "mul"
        then {
            result = "mul";
            rest = substring 3 (stringLength str) str;
        }
        else { rest = str; };
    isMul = str:
        let r = compose [isMulFnName isOpenParen isDigits isComma isDigits isCloseParen] str;
        in if r ? result then {
            result = (elemAt r.result 2) * (elemAt r.result 4);
            rest = r.rest;
        } else {
            rest = str;
        };
    isDo = str:
        if str == "" then { rest = str; }
        else if substring 0 4 str == "do()"
        then {
            result = "start";
            rest = substring 4 (stringLength str) str;
        }
        else { rest = str; };
    isDont = str:
        if str == "" then { rest = str; }
        else if substring 0 7 str == "don't()"
        then {
            result = "stop";
            rest = substring 7 (stringLength str) str;
        }
        else { rest = str; };
    alt = p1: p2: str:
        let r1 = p1 str; in
        if r1 ? result then r1
        else let r2 = p2 str; in
        if r2 ? result then r2
        else { rest = str; };
    parse = str:
        let
            stepEnabled = state:
                let 
                    p = alt isMul isDont;
                    r = p state.input;
                in
                if !(r ? result)
                then state // { input = substring 1 (stringLength state.input) state.input; }
                else if (r.result == "stop")
                then state // { enabled = false; input = r.rest; }
                else state // {
                    acc = state.acc ++ [r.result];
                    input = r.rest;
                };
            
            stepDisabled = state:
                let
                    r = isDo state.input;
                in
                if !(r ? result)
                then state // { input = substring 1 (stringLength state.input) state.input; }
                else state // { enabled = true; input = r.rest; };

            step = state:
                if state.input == ""
                then state // { done = true; }
                else if state.enabled
                then stepEnabled state
                else stepDisabled state;
            initialState = {
                enabled = true;
                acc = [];
                input = str;
                done = false;
            };
            finalState = (
                foldl' (state: _: if state.done then state else step state) initialState (range 0 500000)
            );
        in finalState.acc;
in
    parse content |> sum
