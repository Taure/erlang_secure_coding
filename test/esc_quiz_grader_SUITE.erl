-module(esc_quiz_grader_SUITE).
-include_lib("stdlib/include/assert.hrl").

-export([all/0, groups/0]).
-export([
    grade_correct_answer/1,
    grade_incorrect_answer/1,
    grade_quiz_all_correct/1,
    grade_quiz_mixed/1,
    grade_quiz_ignores_unknown_questions/1,
    score_all_correct/1,
    score_none_correct/1,
    score_mixed/1,
    score_empty/1
]).

all() ->
    [{group, grading}, {group, scoring}].

groups() ->
    [
        {grading, [parallel], [
            grade_correct_answer,
            grade_incorrect_answer,
            grade_quiz_all_correct,
            grade_quiz_mixed,
            grade_quiz_ignores_unknown_questions
        ]},
        {scoring, [parallel], [
            score_all_correct,
            score_none_correct,
            score_mixed,
            score_empty
        ]}
    ].

grade_correct_answer(_Config) ->
    Question = #{
        id => <<"q1">>,
        type => multiple_choice,
        prompt => <<"Test?">>,
        options => [#{id => <<"a">>, text => <<"A">>}],
        correct => <<"a">>,
        explanation => <<"Because A">>
    },
    Result = esc_quiz_grader:grade_answer(Question, <<"a">>),
    ?assertMatch(#{correct := true, explanation := <<"Because A">>}, Result).

grade_incorrect_answer(_Config) ->
    Question = #{
        id => <<"q1">>,
        type => multiple_choice,
        prompt => <<"Test?">>,
        options => [
            #{id => <<"a">>, text => <<"A">>},
            #{id => <<"b">>, text => <<"B">>}
        ],
        correct => <<"a">>,
        explanation => <<"Because A">>
    },
    Result = esc_quiz_grader:grade_answer(Question, <<"b">>),
    ?assertMatch(#{correct := false, explanation := <<"Because A">>}, Result).

grade_quiz_all_correct(_Config) ->
    Answers = #{
        <<"intro_q1">> => <<"c">>,
        <<"intro_q2">> => <<"false">>,
        <<"intro_q3">> => <<"b">>
    },
    Results = esc_quiz_grader:grade_quiz(<<"introduction">>, Answers),
    ?assertEqual(3, maps:size(Results)),
    lists:foreach(
        fun(QId) ->
            ?assertMatch(#{correct := true}, maps:get(QId, Results))
        end,
        maps:keys(Answers)
    ).

grade_quiz_mixed(_Config) ->
    Answers = #{
        <<"intro_q1">> => <<"c">>,
        <<"intro_q2">> => <<"true">>,
        <<"intro_q3">> => <<"a">>
    },
    Results = esc_quiz_grader:grade_quiz(<<"introduction">>, Answers),
    ?assertMatch(#{correct := true}, maps:get(<<"intro_q1">>, Results)),
    ?assertMatch(#{correct := false}, maps:get(<<"intro_q2">>, Results)),
    ?assertMatch(#{correct := false}, maps:get(<<"intro_q3">>, Results)).

grade_quiz_ignores_unknown_questions(_Config) ->
    Answers = #{<<"nonexistent_q">> => <<"a">>},
    Results = esc_quiz_grader:grade_quiz(<<"introduction">>, Answers),
    ?assertEqual(0, maps:size(Results)).

score_all_correct(_Config) ->
    Results = #{
        <<"q1">> => #{correct => true, explanation => <<>>},
        <<"q2">> => #{correct => true, explanation => <<>>}
    },
    ?assertMatch(#{correct := 2, total := 2}, esc_quiz_grader:score(Results)).

score_none_correct(_Config) ->
    Results = #{
        <<"q1">> => #{correct => false, explanation => <<>>},
        <<"q2">> => #{correct => false, explanation => <<>>}
    },
    ?assertMatch(#{correct := 0, total := 2}, esc_quiz_grader:score(Results)).

score_mixed(_Config) ->
    Results = #{
        <<"q1">> => #{correct => true, explanation => <<>>},
        <<"q2">> => #{correct => false, explanation => <<>>},
        <<"q3">> => #{correct => true, explanation => <<>>}
    },
    ?assertMatch(#{correct := 2, total := 3}, esc_quiz_grader:score(Results)).

score_empty(_Config) ->
    ?assertMatch(#{correct := 0, total := 0}, esc_quiz_grader:score(#{})).
