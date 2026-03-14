-module(esc_progress).

-export([init/0, load/1, complete_module/3, is_completed/2, get_score/2]).

-type progress() :: #{
    completed := sets:set(binary()),
    scores := #{binary() => esc_quiz_grader:score()}
}.

-export_type([progress/0]).

-spec init() -> ok.
init() ->
    ets:new(?MODULE, [named_table, public, set]),
    ok.

-spec load(binary()) -> progress().
load(SessionId) ->
    case ets:lookup(?MODULE, SessionId) of
        [{_, Progress}] -> Progress;
        [] -> new()
    end.

-spec complete_module(binary(), binary(), esc_quiz_grader:score()) -> ok.
complete_module(SessionId, ModuleId, Score) ->
    Progress = load(SessionId),
    #{completed := Completed, scores := Scores} = Progress,
    Updated = Progress#{
        completed := sets:add_element(ModuleId, Completed),
        scores := Scores#{ModuleId => Score}
    },
    ets:insert(?MODULE, {SessionId, Updated}),
    ok.

-spec is_completed(binary(), progress()) -> boolean().
is_completed(ModuleId, #{completed := Completed}) ->
    sets:is_element(ModuleId, Completed).

-spec get_score(binary(), progress()) -> esc_quiz_grader:score() | undefined.
get_score(ModuleId, #{scores := Scores}) ->
    maps:get(ModuleId, Scores, undefined).

%% Internal

-spec new() -> progress().
new() ->
    #{completed => sets:new([{version, 2}]), scores => #{}}.
