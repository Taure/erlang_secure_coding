-module(esc_page_controller).

-export([index/1, show_module/1, submit_quiz/1]).

-type response() :: {ok, map(), map()}.

-spec index(Req :: map()) -> response().
index(_Req) ->
    {ok, #{modules => esc_curriculum:modules()}, #{view => esc_home}}.

-spec show_module(Req :: map()) -> response().
show_module(Req) ->
    Qs = maps:from_list(cowboy_req:parse_qs(Req)),
    Section = section_index(maps:get(~"section", Qs, ~"0")),
    case esc_curriculum:get_module(module_id(Req)) of
        {ok, Module} ->
            {ok, module_bindings(Module, Section, #{}, #{}, false), #{view => esc_module}};
        error ->
            not_found()
    end.

-spec submit_quiz(Req :: map()) -> response().
submit_quiz(Req) ->
    ModuleId = module_id(Req),
    Params = maps:get(params, Req, #{}),
    Section = section_index(maps:get(~"section", Params, ~"0")),
    Answers = quiz_answers(Params),
    case esc_curriculum:get_module(ModuleId) of
        {ok, Module} ->
            Results = esc_quiz_grader:grade_quiz(ModuleId, Answers),
            {ok, module_bindings(Module, Section, Answers, Results, true), #{view => esc_module}};
        error ->
            not_found()
    end.

%% Internal

module_id(Req) ->
    Bindings = maps:get(bindings, Req, #{}),
    maps:get(~"module_id", Bindings, undefined).

not_found() ->
    {ok, #{}, #{view => esc_not_found, status_code => 404}}.

module_bindings(Module, Requested, Answers, Results, Submitted) ->
    #{
        id := ModuleId,
        number := Number,
        title := Title,
        estimated_minutes := Minutes,
        sections := Sections,
        quiz := Questions
    } = Module,
    Total = length(Sections),
    Index = clamp(Requested, Total - 1),
    Section = lists:nth(Index + 1, Sections),
    #{
        module_id => ModuleId,
        number => Number,
        title => Title,
        estimated_minutes => Minutes,
        section => section_bindings(Section),
        section_index => Index,
        section_number => Index + 1,
        total_sections => Total,
        prev_url => section_url(ModuleId, Index - 1, Total - 1),
        next_url => section_url(ModuleId, Index + 1, Total - 1),
        questions => [question_bindings(Q, Answers, Results, Submitted) || Q <- Questions],
        submitted => Submitted,
        score => score_bindings(Results)
    }.

section_bindings(Section) ->
    #{title := Title, content := Content} = Section,
    Examples = maps:get(code_examples, Section, []),
    #{
        title => Title,
        content => Content,
        examples => [example_bindings(E) || E <- Examples]
    }.

example_bindings(Example) ->
    #{title := Title, code := Code, explanation := Explanation} = Example,
    Vulnerable = maps:get(vulnerable, Example, false),
    Output = maps:get(output, Example, ~""),
    #{
        title => Title,
        code => Code,
        explanation => Explanation,
        output => Output,
        has_output => Output =/= ~"",
        border_class => vuln_border_class(Vulnerable),
        header_class => vuln_header_class(Vulnerable),
        text_class => vuln_text_class(Vulnerable),
        label => vuln_label(Vulnerable)
    }.

question_bindings(Question, Answers, Results, Submitted) ->
    #{id := QuestionId, prompt := Prompt} = Question,
    Options = maps:get(options, Question, []),
    Selected = maps:get(QuestionId, Answers, undefined),
    Result = maps:get(QuestionId, Results, undefined),
    #{
        id => QuestionId,
        prompt => Prompt,
        options => [option_bindings(O, Selected, Submitted, Result) || O <- Options],
        show_explanation => Submitted andalso Result =/= undefined,
        explanation => explanation(Result)
    }.

option_bindings(#{id := OptionId, text := Text}, Selected, Submitted, Result) ->
    Chosen = Selected =:= OptionId,
    Class = [option_base_class(Chosen), option_result_class(Submitted, Result, Chosen)],
    #{
        id => OptionId,
        text => Text,
        checked => Chosen,
        class => iolist_to_binary(Class)
    }.

score_bindings(Results) ->
    #{correct := Correct, total := Total} = esc_quiz_grader:score(Results),
    Perfect = Correct =:= Total,
    #{
        correct => Correct,
        total => Total,
        banner_class => score_banner_class(Perfect),
        text_class => score_text_class(Perfect),
        suffix => score_suffix(Perfect)
    }.

explanation(#{explanation := Explanation}) -> Explanation;
explanation(_) -> ~"".

vuln_border_class(true) -> ~"border-red-200 bg-red-50";
vuln_border_class(false) -> ~"border-green-200 bg-green-50".

vuln_header_class(true) -> ~"border-red-200 bg-red-100";
vuln_header_class(false) -> ~"border-green-200 bg-green-100".

vuln_text_class(true) -> ~"text-red-700";
vuln_text_class(false) -> ~"text-green-700".

vuln_label(true) -> ~"&#x26A0; Vulnerable";
vuln_label(false) -> ~"&#x2713; Safe".

option_base_class(true) -> ~"border-indigo-300 bg-indigo-50";
option_base_class(false) -> ~"border-gray-100 hover:bg-gray-50".

option_result_class(true, #{correct := true}, true) -> ~" border-green-300 bg-green-50";
option_result_class(true, #{correct := false}, true) -> ~" border-red-300 bg-red-50";
option_result_class(_, _, _) -> ~"".

score_banner_class(true) -> ~"mb-6 p-4 rounded-lg bg-green-50 border border-green-200";
score_banner_class(false) -> ~"mb-6 p-4 rounded-lg bg-yellow-50 border border-yellow-200".

score_text_class(true) -> ~"font-semibold text-green-700";
score_text_class(false) -> ~"font-semibold text-yellow-700".

score_suffix(true) -> ~" - Perfect!";
score_suffix(false) -> ~"".

section_url(_ModuleId, Index, _Max) when Index < 0 ->
    undefined;
section_url(_ModuleId, Index, Max) when Index > Max ->
    undefined;
section_url(ModuleId, Index, _Max) ->
    iolist_to_binary([~"/modules/", ModuleId, ~"?section=", integer_to_binary(Index)]).

clamp(Index, _Max) when Index < 0 -> 0;
clamp(Index, Max) when Index > Max -> Max;
clamp(Index, _Max) -> Index.

section_index(Value) ->
    try
        binary_to_integer(Value)
    catch
        error:badarg -> 0
    end.

quiz_answers(Params) ->
    maps:from_list([
        {QuestionId, Answer}
     || {Key, Answer} <- maps:to_list(Params),
        {question, QuestionId} <- [answer_key(Key)]
    ]).

answer_key(<<"q_", QuestionId/binary>>) -> {question, QuestionId};
answer_key(_) -> other.
