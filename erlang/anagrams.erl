-module (anagrams).
-compile (export_all).

filter (CriterionBag, Dict) ->
    lists:filter (fun ({Candidate, _}) ->
                          bag:subtract (CriterionBag, Candidate) > 0
                  end,
                  Dict).

combine (Words, Anagrams) ->
    lists:flatmap(fun (W) ->
                          lists:map (fun (An) -> [W | An] end, Anagrams) end,
                  Words).

anagrams (Bag, Dict)->
    pairfold:pairfold (
      fun (SubDict, Accum) ->
              [{ThisKey, TheseWords}|_] = SubDict,

              case bag:subtract (Bag, ThisKey) of
                  0 -> Accum;
                  1 -> [[W] || W <- TheseWords] ++ Accum;
                  SmallerBag ->
                      combine (TheseWords,
                               anagrams (SmallerBag,
                                         filter (SmallerBag, SubDict)
                                        )) ++ Accum
              end
      end,
      Dict).

tinydict () ->
    [
     {bag:bag ("cat"), ["cat"]},
     {bag:bag ("dog"), ["dog", "god"]},
     {bag:bag ("at"), ["at"]}
    ].

main ([])->
    io:format ("Dude.  How 'bout an argument?~n");
main ([CriterionString])->
    B = bag:bag (CriterionString),

    Filtered = filter (B, 
                       wheedledict:snarf ()),

%%%     Filtered = tinydict (),
    
    io:format ("Dictionary has ~p entries that are included in ~p.~n",
               [length (Filtered), CriterionString]),
    Tada = anagrams (B, Filtered),
    io:format ("~p anagrams of ~p:~n",
               [length (Tada),
                CriterionString]);
main ([CriterionString|Crap]) ->
    io:format ("(ignoring ~p ...)", [Crap]),
    main ([CriterionString]).
