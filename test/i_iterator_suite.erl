%%% ==========================================================================
%%% @author Damian T. Dobroczy\\'nski <qoocku@gmail.com> <email>
%%% @since 2011-03-18
%%% @doc Erlang Standard Collection Generic Iterators Tests Suite Utilities.
%%% @end
%%% ==========================================================================
-module  (i_iterator_suite).
-author  ("Damian T. Dobroczy\\'nski <qoocku@gmail.com> <email>").

-include_lib ("common_test/include/ct.hrl").

-export ([all/0,
          groups/0, 
          init_per_suite/1,
          end_per_suite/1,
          init_per_group/2,
          end_per_group/2,
          init_per_testcase/2,
          end_per_testcase/2]).

-export([test_foreach/1,         
         test_fold/1,
         test_map/1,
         test_filter/1,
         test_any/1,
         test_all/1]).

-export([test_foreach/2,         
         test_map/2,
         test_fold/2,
         test_filter/2,
         test_any/2,
         test_all/2]).


-export ([test_iterator/4,
          do_specific_test/2,
          do_specific_test/3,
          apply/3]).

groups () ->
  [{iterators, [parallel], [test_foreach,
                            test_fold,
                            test_map,
                            test_filter,
                            test_any,
                            test_all]}].

init_per_suite(Config) -> 
    Config. 

end_per_suite (_Config) ->    
    ok.

init_per_group (_, Config) ->
  Config.
end_per_group (_, _) ->
  ok.

init_per_testcase(_Case, Config) ->
  Config.

end_per_testcase(_Case, _Config) -> 
    ok. 

all() ->
    [{group, iterators}]. 

%% --------------------------------------------------------------------
%% TEST CASES
%% --------------------------------------------------------------------

test_foreach (Config) ->
  do_specific_test(test_foreach, Config).

test_foreach (_, Config) ->
  F = fun (A, B, C) ->
          put(acc, (?config(fold_fun, Config))(acc, ok)),
          ?MODULE:apply(A, B, C),
          get(acc)
      end,
  test_iterator(Config, foreach, foreach_fun, std, {F, F}).

test_fold (Config) ->
  do_specific_test(test_fold, Config).

test_fold (_, Config) ->
  test_reduce(Config, fold).

test_map (Config) ->
  do_specific_test(test_map, Config).

test_map (_, Config) ->
  test_traverse(Config, map).

test_filter (Config) ->
  do_specific_test(test_filter, Config).

test_filter (_, Config) ->
  test_iterator(Config, filter, pred_fun).

test_all (Config) ->
  do_specific_test(test_all, Config).

test_all (_, Config) ->
  test_predicate(Config, all).

test_any (Config) ->
  do_specific_test(test_any, Config).

test_any (_, Config) ->
  test_predicate(Config, any).

%%% ------- local functions --------

do_specific_test (Test, Config) ->
  do_specific_test(Test, Config, fun (_, Cfg) -> ?MODULE:Test(undefined, Cfg) end).

do_specific_test (Test, Config, Default) ->
  ErlMod = ?config(erl_mod, Config),
  case ?config({specific, Test}, Config) of
    undefined -> Default(ErlMod, Config);
    Fun       -> Fun(ErlMod, Config)
  end.

test_iterator (Config, Function, FunKey) ->
  test_iterator (Config, Function, FunKey, fun (X) -> [X] end).
  
test_iterator (Config, Function, FunKey, ArgFun) ->
  F = fun (M, F, A) -> ?MODULE:apply(M, F, A) end,
  test_iterator (Config, Function, FunKey, ArgFun, {F, F}).

test_iterator (Config, Function, FunKey, std, RFuns) ->
  test_iterator (Config, Function, FunKey, fun (X) -> [X] end, RFuns);
test_iterator (Config, Function, FunKey, ArgFun, {std, RF2}) ->
  test_iterator (Config, Function, FunKey, ArgFun, {fun ?MODULE:apply/3, RF2});
test_iterator (Config, Function, FunKey, ArgFun, {RF1, std}) ->
  test_iterator (Config, Function, FunKey, ArgFun, {RF1, fun ?MODULE:apply/3});
test_iterator (Config, Function, FunKey, ArgFun, {RF1, RF2}) ->
  Iterator           = ?config(iterator, Config),
  Samples            = ?config(samples, Config),
  ErlMod             = ?config(erl_mod, Config),
  {Result, Expected} = begin
                         Args = case ?config(FunKey, Config) of
                                  undefined -> [];
                                  Fun       -> ArgFun(Fun)
                                end,
                         {RF1(Iterator, Function, Args),
                          RF2(ErlMod, Function, Args ++ [Samples])}
                       end, 
  io:format("Comparing results: ~p =:= ~p\n", [Result, Expected]),
  true = (Result =:= Expected).
  
test_predicate (Config, Function) ->
  test_iterator(Config, Function, pred_fun).

test_traverse (Config, Function) ->
  F = fun (M, F, A) ->
          Iter = ?MODULE:apply(M, F, A),
          L = fun (I, Acc, Loop) ->
                  case I:next() of
                    {V, none} -> lists:reverse([V|Acc]);
                    {V, N}    -> Loop(N, [V|Acc], Loop)
                  end
              end,
          L(Iter, [], L)
      end,
  test_iterator(Config, Function, trav_fun, std, {F, std}).

test_reduce (Config, Function) ->
  test_iterator(Config, Function, fold_fun, fun (F) -> [F, F(acc, ok)] end).

apply ({Mod, Keys, D}, all, [Pred]) when Mod =:= dict orelse 
                                         Mod =:= orddict ->
  lists:all(Pred, [{K, Mod:fetch(K, D)} || K <- Keys]);
apply ({Mod, List}, all, [Pred]) when Mod =:= sets orelse
                                      Mod =:= ordsets orelse 
                                      Mod =:= lists ->
  lists:all(Pred, List);  
apply ({Mod, Keys, D}, any, [Pred]) when Mod =:= dict orelse
                                         Mod =:= orddict ->
  lists:all(Pred, [{K, Mod:fetch(K, D)} || K <- Keys]);
apply ({Mod, List}, any, [Pred]) when Mod =:= sets orelse
                                      Mod =:= ordsets orelse 
                                      Mod =:= lists ->
  lists:any(Pred, List);  
apply ({Mod, [], _}, _, _) when Mod =:= dict orelse
                                Mod =:= orddict ->
  none;
apply ({Mod, []}, _, _) when Mod =:= sets orelse
                             Mod =:= ordsets orelse
                             Mod =:= lists ->
  none;
apply ({Mod, Keys, D}, map, [Fun]) when Mod =:= dict orelse
                                        Mod =:= orddict ->
  {Fun({hd(Keys), Mod:fetch(hd(Keys), D)}), {tl(Keys), D}};
apply ({Mod, List}, map, [Fun]) when Mod =:= sets orelse
                                     Mod =:= ordsets orelse
                                     Mod =:= lists ->
  lists:map(Fun, List);
apply ({Mod, [K|Keys], D}, filter, [Pred]) when Mod =:= dict orelse
                                                Mod =:= orddict ->
  case Pred({K, V=Mod:fetch(K, D)}) of
    true  -> {V, {Mod, Keys, D}};
    false -> ?MODULE:apply({Mod, Keys, D}, filter, [Pred])
  end;
apply ({Mod, [I|List]}, filter, [Pred]) when Mod =:= sets orelse
                                             Mod =:= ordsets orelse
                                             Mod =:= lists ->
  case Pred(I) of
    true  -> {I, {Mod, List}};
    false -> ?MODULE:apply({Mod, List}, filter, [Pred])
  end;
apply ({Mod, Keys, D}, fold, [Fun, Acc]) when Mod =:= dict orelse
                                              Mod =:= orddict ->
  lists:foldl(Fun, Acc, [{K, Mod:fetch(K, D)} || K <- Keys]);
apply (Mod, fold, [Fun, Acc, List]) when Mod =:= lists orelse
                                         Mod =:= ordsets ->
  lists:foldl(Fun, Acc, List);
apply ({Mod, List}, fold, [Fun, Acc]) when Mod =:= lists orelse
                                           Mod =:= sets orelse
                                           Mod =:= ordsets ->
  lists:foldl(Fun, Acc, List);
apply ({Mod, [K|Keys], D}, foreach, [Fun]) when Mod =:= dict orelse
                                                Mod =:= orddict orelse
                                                Mod =:= sets orelse
                                                Mod =:= ordsets ->
  {Fun({K, Mod:fetch(K, D)}), {Mod, Keys, D}};
apply ({Mod, Keys, D}, next, []) when Mod =:= dict orelse
                                      Mod =:= orddict ->
  {hd(Keys), {tl(Keys), D}};
apply (Mod, Fun, Args) ->
  erlang:apply(Mod, Fun, Args).
  