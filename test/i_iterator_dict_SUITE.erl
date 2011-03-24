%%% ==========================================================================
%%% @author Damian T. Dobroczy\\'nski <qoocku@gmail.com> <email>
%%% @since 2011-03-17
%%% @doc Commont Tests for iterators implemented as lists.
%%% @end
%%% ==========================================================================
-module (i_iterator_dict_SUITE).
-extends (i_iterator_suite).

-include_lib ("common_test/include/ct.hrl").

-export ([suite/0,
          all/0,
          groups/0, 
          init_per_group/2]).

suite() -> 
  [{timetrap, {minutes,1}}].  

groups () ->
  ?BASE_MODULE:groups() ++
    [{dict, [parallel], [{group, iterators}]}].

init_per_group (dict, Config) ->
  Samples = dict:from_list(lists:zip(lists:seq(1, 1000), lists:seq(1000, 1, -1))),
  [{iterator, i_iterator_dict:new(Samples)},
   {samples, Samples},
   {erl_mod, dict},
   {fold_fun, fun
                (acc, _) -> 0;
                ({_, I}, Acc) -> Acc + I 
              end},
   {foreach_fun, fun({_, V}) -> put(acc, get(acc) + V) end},
   {pred_fun, fun ({K, V}) -> V =< 500 andalso K > 300 end},
   {trav_fun, fun ({K, V}) -> {K*1234, V*123} end} | Config];
init_per_group (Group, Config) ->
  ?BASE_MODULE:init_per_group(Group, Config).

all() ->
    [{group, dict}]. 

%% --------------------------------------------------------------------
%% TEST CASES
%% --------------------------------------------------------------------
