-module(ktn_os_SUITE).

-export([all/0]).

-export([command/1]).

-define(EXCLUDED_FUNS,
        [
         module_info,
         all,
         test,
         init_per_suite,
         end_per_suite
        ]).

-type config() :: [{atom(), term()}].

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Common test
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

-spec all() -> [atom()].
all() ->
    Exports = ?MODULE:module_info(exports),
    [F || {F, _} <- Exports, not lists:member(F, ?EXCLUDED_FUNS)].

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Test Cases
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

-spec command(config()) -> ok.
command(_Config) ->
  Opts = #{log_fun => fun(_) -> ok end},

  {0, "/\n"} = ktn_os:command("cd /; pwd", Opts),

  {ok, Cwd} = file:get_cwd(),
  Result = Cwd ++ "\n",
  {0, Result} = ktn_os:command("pwd", Opts),

  {1, _} = ktn_os:command("pwd; ls w4th3v3r", Opts),

  Result2 = Result ++ "Hi\n",
  {0, Result2} = ktn_os:command("pwd; echo Hi", #{}),

  {0, "/\n"} = ktn_os:command("cd /; pwd"),

  ok = try ktn_os:command("sleep 5", #{timeout => 1000})
       catch _:timeout -> ok end,

  Fun = fun() -> ktn_os:command("cd /; pwd") end,
  FilterFun =
    fun(Line) ->
        case re:run(Line, "=INFO REPORT==== .* ===") of
          nomatch -> false;
          {match, _}-> true
        end
    end,
  check_some_line_output(Fun, FilterFun).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Helper functions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

check_some_line_output(Fun, FilterFun) ->
  ct:capture_start(),
  Fun(),
  ct:capture_stop(),
  Lines = ct:capture_get([]),
  ListFun = fun(Line) -> FilterFun(Line) end,
  [_ | _] = lists:filter(ListFun, Lines).
