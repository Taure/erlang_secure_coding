-module(esc_curriculum_SUITE).
-include_lib("stdlib/include/assert.hrl").

-export([all/0, groups/0]).
-export([
    modules_returns_list/1,
    modules_have_required_fields/1,
    module_ids_are_unique/1,
    get_module_returns_existing/1,
    get_module_returns_error_for_unknown/1,
    sections_have_content/1,
    quiz_questions_have_correct_answer/1,
    quiz_question_ids_unique_per_module/1
]).

all() ->
    [{group, data_integrity}].

groups() ->
    [
        {data_integrity, [parallel], [
            modules_returns_list,
            modules_have_required_fields,
            module_ids_are_unique,
            get_module_returns_existing,
            get_module_returns_error_for_unknown,
            sections_have_content,
            quiz_questions_have_correct_answer,
            quiz_question_ids_unique_per_module
        ]}
    ].

modules_returns_list(_Config) ->
    Modules = esc_curriculum:modules(),
    ?assert(is_list(Modules)),
    ?assert(length(Modules) > 0).

modules_have_required_fields(_Config) ->
    lists:foreach(
        fun(Module) ->
            ?assertMatch(
                #{
                    id := _,
                    number := _,
                    title := _,
                    description := _,
                    estimated_minutes := _,
                    sections := _,
                    quiz := _
                },
                Module
            ),
            #{id := Id, number := Num, estimated_minutes := Mins} = Module,
            ?assert(is_binary(Id)),
            ?assert(is_integer(Num) andalso Num > 0),
            ?assert(is_integer(Mins) andalso Mins > 0)
        end,
        esc_curriculum:modules()
    ).

module_ids_are_unique(_Config) ->
    Ids = esc_curriculum:module_ids(),
    ?assertEqual(length(Ids), length(lists:usort(Ids))).

get_module_returns_existing(_Config) ->
    lists:foreach(
        fun(Id) ->
            ?assertMatch({ok, #{id := Id}}, esc_curriculum:get_module(Id))
        end,
        esc_curriculum:module_ids()
    ).

get_module_returns_error_for_unknown(_Config) ->
    ?assertEqual(error, esc_curriculum:get_module(<<"nonexistent">>)).

sections_have_content(_Config) ->
    lists:foreach(
        fun(#{sections := Sections}) ->
            ?assert(length(Sections) > 0),
            lists:foreach(
                fun(Section) ->
                    ?assertMatch(#{title := _, content := _}, Section),
                    #{title := T, content := C} = Section,
                    ?assert(byte_size(T) > 0),
                    ?assert(byte_size(C) > 0)
                end,
                Sections
            )
        end,
        esc_curriculum:modules()
    ).

quiz_questions_have_correct_answer(_Config) ->
    lists:foreach(
        fun(#{quiz := Quiz}) ->
            ?assert(length(Quiz) > 0),
            lists:foreach(
                fun(Question) ->
                    ?assertMatch(
                        #{
                            id := _,
                            type := _,
                            prompt := _,
                            options := _,
                            correct := _,
                            explanation := _
                        },
                        Question
                    ),
                    #{options := Options, correct := Correct} = Question,
                    OptionIds = [OId || #{id := OId} <- Options],
                    ?assert(
                        lists:member(Correct, OptionIds),
                        {correct_not_in_options, Correct, OptionIds}
                    )
                end,
                Quiz
            )
        end,
        esc_curriculum:modules()
    ).

quiz_question_ids_unique_per_module(_Config) ->
    lists:foreach(
        fun(#{id := ModId, quiz := Quiz}) ->
            Ids = [QId || #{id := QId} <- Quiz],
            ?assertEqual(
                length(Ids),
                length(lists:usort(Ids)),
                {duplicate_question_ids, ModId}
            )
        end,
        esc_curriculum:modules()
    ).
