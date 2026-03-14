-module(esc_quiz_grader).

-export([grade_answer/2, grade_quiz/2, score/1]).

-type result() :: #{correct := boolean(), explanation := binary()}.
-type results() :: #{binary() => result()}.
-type score() :: #{correct := non_neg_integer(), total := non_neg_integer()}.

-export_type([result/0, results/0, score/0]).

-spec grade_answer(esc_curriculum:quiz_question(), binary()) -> result().
grade_answer(#{correct := Correct, explanation := Explanation}, Answer) ->
    #{correct => Correct =:= Answer, explanation => Explanation}.

-spec grade_quiz(binary(), #{binary() => binary()}) -> results().
grade_quiz(ModuleId, Answers) ->
    {ok, Module} = esc_curriculum:get_module(ModuleId),
    #{quiz := Questions} = Module,
    maps:fold(
        fun(QuestionId, Answer, Acc) ->
            case find_question(QuestionId, Questions) of
                {ok, Question} ->
                    Acc#{QuestionId => grade_answer(Question, Answer)};
                error ->
                    Acc
            end
        end,
        #{},
        Answers
    ).

-spec score(results()) -> score().
score(Results) ->
    {Correct, Total} = maps:fold(
        fun
            (_Id, #{correct := true}, {C, T}) -> {C + 1, T + 1};
            (_Id, #{correct := false}, {C, T}) -> {C, T + 1}
        end,
        {0, 0},
        Results
    ),
    #{correct => Correct, total => Total}.

%% Internal

-spec find_question(binary(), [esc_curriculum:quiz_question()]) ->
    {ok, esc_curriculum:quiz_question()} | error.
find_question(Id, Questions) ->
    case [Q || Q = #{id := QId} <- Questions, QId =:= Id] of
        [Question] -> {ok, Question};
        [] -> error
    end.
