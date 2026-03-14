-module(esc_module_view).
-behaviour(arizona_view).
-compile({parse_transform, arizona_parse_transform}).

-export([mount/2, layout/1, render/1, handle_event/3]).
-export([
    render_module_content/1,
    render_nav_buttons/1,
    render_next_button/1,
    render_complete_badge/1,
    render_quiz/1,
    render_score_banner/1,
    render_submit_button/1
]).

-export([
    vuln_border_class/1,
    vuln_header_class/1,
    vuln_text_class/1,
    vuln_label/1,
    not_found_html/0,
    output_html/1,
    render_questions_html/5,
    render_question_html/5,
    render_options_html/5,
    render_option_html/5,
    explanation_html/4
]).

mount(_Arg, Req) ->
    Path = arizona_request:get_path(Req),
    ModuleId = extract_module_id(Path),
    case esc_curriculum:get_module(ModuleId) of
        {ok, Module} ->
            Bindings = #{
                id => ~"module-view",
                module => Module,
                current_section => 0,
                quiz_answers => #{},
                quiz_results => #{},
                quiz_submitted => false,
                show_explanations => #{}
            },
            Layout = {esc_home_view, layout, main_content, #{active_url => Path}},
            arizona_view:new(esc_module_view, Bindings, Layout);
        error ->
            Bindings = #{
                id => ~"module-view",
                module => not_found,
                current_section => 0,
                quiz_answers => #{},
                quiz_results => #{},
                quiz_submitted => false,
                show_explanations => #{}
            },
            Layout = {esc_home_view, layout, main_content, #{active_url => Path}},
            arizona_view:new(esc_module_view, Bindings, Layout)
    end.

layout(Bindings) ->
    esc_home_view:layout(Bindings).

handle_event(~"next_section", _Params, View) ->
    State = arizona_view:get_state(View),
    Current = arizona_stateful:get_binding(current_section, State),
    Module = arizona_stateful:get_binding(module, State),
    #{sections := Sections} = Module,
    Max = length(Sections) - 1,
    Next = min(Current + 1, Max),
    NewState = arizona_stateful:put_binding(current_section, Next, State),
    {[], arizona_view:update_state(NewState, View)};
handle_event(~"prev_section", _Params, View) ->
    State = arizona_view:get_state(View),
    Current = arizona_stateful:get_binding(current_section, State),
    Prev = max(Current - 1, 0),
    NewState = arizona_stateful:put_binding(current_section, Prev, State),
    {[], arizona_view:update_state(NewState, View)};
handle_event(~"select_answer", #{~"question_id" := QId, ~"answer_id" := AId}, View) ->
    State = arizona_view:get_state(View),
    Answers = arizona_stateful:get_binding(quiz_answers, State),
    NewAnswers = Answers#{QId => AId},
    NewState = arizona_stateful:put_binding(quiz_answers, NewAnswers, State),
    {[], arizona_view:update_state(NewState, View)};
handle_event(~"submit_quiz", _Params, View) ->
    State = arizona_view:get_state(View),
    Module = arizona_stateful:get_binding(module, State),
    Answers = arizona_stateful:get_binding(quiz_answers, State),
    #{id := ModuleId} = Module,
    Results = esc_quiz_grader:grade_quiz(ModuleId, Answers),
    NewState = arizona_stateful:merge_bindings(
        #{quiz_results => Results, quiz_submitted => true},
        State
    ),
    {[], arizona_view:update_state(NewState, View)};
handle_event(~"show_explanation", #{~"question_id" := QId}, View) ->
    State = arizona_view:get_state(View),
    Shown = arizona_stateful:get_binding(show_explanations, State),
    NewShown = Shown#{QId => true},
    NewState = arizona_stateful:put_binding(show_explanations, NewShown, State),
    {[], arizona_view:update_state(NewState, View)}.

render(Bindings) ->
    Module = arizona_template:get_binding(module, Bindings),
    ContentBindings =
        case Module of
            not_found ->
                #{};
            _ ->
                #{sections := Sections} = Module,
                CurrentIdx = arizona_template:get_binding(current_section, Bindings),
                #{
                    module => Module,
                    section => lists:nth(CurrentIdx + 1, Sections),
                    current_section => CurrentIdx,
                    total_sections => length(Sections),
                    quiz_answers => arizona_template:get_binding(quiz_answers, Bindings),
                    quiz_results => arizona_template:get_binding(quiz_results, Bindings),
                    quiz_submitted => arizona_template:get_binding(quiz_submitted, Bindings),
                    show_explanations => arizona_template:get_binding(show_explanations, Bindings)
                }
        end,
    arizona_template:from_html(
        ~""""
    <div id="{arizona_template:get_binding(id, Bindings)}">
        {case Module of
            not_found -> esc_module_view:not_found_html();
            _ -> arizona_template:render_stateless(esc_module_view, render_module_content,
                     ContentBindings#{id => arizona_template:get_binding(id, Bindings)})
        end}
    </div>
    """"
    ).

render_module_content(Bindings) ->
    Module = arizona_template:get_binding(module, Bindings),
    #{title := Title, number := Num, estimated_minutes := Mins} = Module,
    Section = arizona_template:get_binding(section, Bindings),
    #{title := STitle} = Section,
    SContent = maps:get(content, Section),
    CodeExamples = maps:get(code_examples, Section, []),
    arizona_template:from_html(
        ~""""
    <div id="{arizona_template:get_binding(id, Bindings)}">
        <div class="mb-6">
            <a href="/" class="text-indigo-600 hover:underline text-sm">&larr; Back to curriculum</a>
        </div>
        <div class="mb-8">
            <div class="flex items-center gap-3 mb-2">
                <span class="bg-indigo-100 text-indigo-700 text-sm font-semibold px-2.5 py-0.5 rounded">Module {integer_to_binary(Num)}</span>
                <span class="text-gray-400 text-sm">{integer_to_binary(Mins)} min</span>
            </div>
            <h1 class="text-3xl font-bold text-gray-900">{Title}</h1>
        </div>

        <div class="bg-white rounded-lg shadow-sm border border-gray-200 p-8 mb-8">
            <h2 class="text-2xl font-semibold text-gray-900 mb-4">{STitle}</h2>
            <div class="prose prose-gray max-w-none mb-6">{SContent}</div>
            {arizona_template:render_list(fun(Example) ->
                #{title := ETitle, code := Code, explanation := Expl} = Example,
                IsVuln = maps:get(vulnerable, Example, false),
                Output = maps:get(output, Example, ~""),
                arizona_template:from_html(~"""
                <div class="my-6 rounded-lg border {esc_module_view:vuln_border_class(IsVuln)}">
                    <div class="px-4 py-2 border-b {esc_module_view:vuln_header_class(IsVuln)} flex items-center gap-2">
                        <span class="text-sm font-medium {esc_module_view:vuln_text_class(IsVuln)}">
                            {esc_module_view:vuln_label(IsVuln)}
                        </span>
                        <span class="text-sm text-gray-600">{ETitle}</span>
                    </div>
                    <pre class="p-4 overflow-x-auto"><code class="language-erlang text-sm">{Code}</code></pre>
                    {esc_module_view:output_html(Output)}
                    <div class="px-4 py-3 border-t {esc_module_view:vuln_border_class(IsVuln)}">
                        <p class="text-sm text-gray-700">{Expl}</p>
                    </div>
                </div>
                """) end,
                CodeExamples
            )}
        </div>

        {arizona_template:render_stateless(esc_module_view, render_nav_buttons, #{
            current_section => arizona_template:get_binding(current_section, Bindings),
            total_sections => arizona_template:get_binding(total_sections, Bindings)
        })}

        {arizona_template:render_stateless(esc_module_view, render_quiz, #{
            quiz => maps:get(quiz, Module),
            quiz_answers => arizona_template:get_binding(quiz_answers, Bindings),
            quiz_results => arizona_template:get_binding(quiz_results, Bindings),
            quiz_submitted => arizona_template:get_binding(quiz_submitted, Bindings),
            show_explanations => arizona_template:get_binding(show_explanations, Bindings)
        })}
    </div>
    """"
    ).

render_nav_buttons(Bindings) ->
    CurrentIdx = arizona_template:get_binding(current_section, Bindings),
    TotalSections = arizona_template:get_binding(total_sections, Bindings),
    PrevClass =
        case CurrentIdx of
            0 -> ~"px-4 py-2 bg-gray-200 text-gray-700 rounded opacity-50 cursor-not-allowed";
            _ -> ~"px-4 py-2 bg-gray-200 text-gray-700 rounded hover:bg-gray-300"
        end,
    arizona_template:from_html(
        ~""""
    <div class="flex items-center justify-between mb-8">
        <button onclick="arizona.pushEvent('prev_section')" class="{PrevClass}">
            &larr; Previous
        </button>
        <span class="text-gray-500 text-sm">
            Section {integer_to_binary(CurrentIdx + 1)} of {integer_to_binary(TotalSections)}
        </span>
        {case CurrentIdx < TotalSections - 1 of
            true -> arizona_template:render_stateless(esc_module_view, render_next_button, #{});
            false -> arizona_template:render_stateless(esc_module_view, render_complete_badge, #{})
        end}
    </div>
    """"
    ).

render_next_button(_Bindings) ->
    arizona_template:from_html(
        ~""""
    <button onclick="arizona.pushEvent('next_section')" class="px-4 py-2 bg-indigo-600 text-white rounded hover:bg-indigo-700">
        Next &rarr;
    </button>
    """"
    ).

render_complete_badge(_Bindings) ->
    arizona_template:from_html(
        ~""""
    <span class="px-4 py-2 bg-green-100 text-green-700 rounded text-sm font-medium">
        All sections complete!
    </span>
    """"
    ).

render_quiz(Bindings) ->
    Quiz = arizona_template:get_binding(quiz, Bindings),
    QuizSubmitted = arizona_template:get_binding(quiz_submitted, Bindings),
    QuizAnswers = arizona_template:get_binding(quiz_answers, Bindings),
    QuizResults = arizona_template:get_binding(quiz_results, Bindings),
    ShowExplanations = arizona_template:get_binding(show_explanations, Bindings),
    QuestionsHtml = esc_module_view:render_questions_html(
        Quiz, QuizAnswers, QuizResults, QuizSubmitted, ShowExplanations
    ),
    arizona_template:from_html(
        ~""""
    <div class="bg-white rounded-lg shadow-sm border border-gray-200 p-8">
        <h2 class="text-2xl font-semibold text-gray-900 mb-2">Knowledge Check</h2>
        <p class="text-gray-600 mb-6">Test your understanding of this module's concepts.</p>

        {case QuizSubmitted of
            true -> arizona_template:render_stateless(esc_module_view, render_score_banner, #{
                quiz_results => QuizResults
            });
            false -> ~""
        end}

        {QuestionsHtml}

        {case QuizSubmitted of
            false -> arizona_template:render_stateless(esc_module_view, render_submit_button, #{});
            true -> ~""
        end}
    </div>
    """"
    ).

render_score_banner(Bindings) ->
    QuizResults = arizona_template:get_binding(quiz_results, Bindings),
    #{correct := C, total := T} = esc_quiz_grader:score(QuizResults),
    BannerClass =
        case C =:= T of
            true -> ~"mb-6 p-4 rounded-lg bg-green-50 border border-green-200";
            false -> ~"mb-6 p-4 rounded-lg bg-yellow-50 border border-yellow-200"
        end,
    TextClass =
        case C =:= T of
            true -> ~"font-semibold text-green-700";
            false -> ~"font-semibold text-yellow-700"
        end,
    Suffix =
        case C =:= T of
            true -> ~" &mdash; Perfect!";
            false -> ~""
        end,
    arizona_template:from_html(
        ~""""
    <div class="{BannerClass}">
        <p class="{TextClass}">
            Score: {integer_to_binary(C)} / {integer_to_binary(T)}{Suffix}
        </p>
    </div>
    """"
    ).

render_submit_button(_Bindings) ->
    arizona_template:from_html(
        ~""""
    <button
        onclick="arizona.pushEvent('submit_quiz')"
        class="mt-6 px-6 py-3 bg-indigo-600 text-white rounded-lg hover:bg-indigo-700 font-medium"
    >
        Submit Answers
    </button>
    """"
    ).

%% Pure HTML rendering functions — no parse transform, just iolists

not_found_html() ->
    [
        ~"<div class=\"text-center py-16\">",
        ~"<h1 class=\"text-2xl font-bold text-gray-900 mb-4\">Module Not Found</h1>",
        ~"<a href=\"/\" class=\"text-indigo-600 hover:underline\">Back to curriculum</a>",
        ~"</div>"
    ].

vuln_border_class(true) -> ~"border-red-200 bg-red-50";
vuln_border_class(false) -> ~"border-green-200 bg-green-50".

vuln_header_class(true) -> ~"border-red-200 bg-red-100";
vuln_header_class(false) -> ~"border-green-200 bg-green-100".

vuln_text_class(true) -> ~"text-red-700";
vuln_text_class(false) -> ~"text-green-700".

vuln_label(true) -> ~"&#x26A0; Vulnerable";
vuln_label(false) -> ~"&#x2713; Safe".

output_html(~"") ->
    ~"";
output_html(Output) ->
    [
        ~"<div class=\"px-4 py-2 border-t border-gray-200 bg-gray-50\">",
        ~"<span class=\"text-xs text-gray-500 font-medium\">Output:</span>",
        ~"<pre class=\"text-sm text-gray-700 mt-1\">",
        Output,
        ~"</pre>",
        ~"</div>"
    ].

render_questions_html(Questions, Answers, Results, Submitted, ShowExplanations) ->
    lists:map(
        fun(Q) ->
            render_question_html(Q, Answers, Results, Submitted, ShowExplanations)
        end,
        Questions
    ).

render_question_html(
    #{id := QId, prompt := Prompt, options := Options},
    Answers,
    Results,
    Submitted,
    ShowExplanations
) ->
    SelectedAnswer = maps:get(QId, Answers, undefined),
    Result = maps:get(QId, Results, undefined),
    ShowExpl = maps:get(QId, ShowExplanations, false),
    OptionsHtml = render_options_html(Options, QId, SelectedAnswer, Submitted, Result),
    ExplHtml = explanation_html(Submitted, Result, ShowExpl, QId),
    [
        ~"<div class=\"mb-6 p-4 rounded-lg border border-gray-200\">",
        ~"<p class=\"font-medium text-gray-900 mb-3\">",
        Prompt,
        ~"</p>",
        ~"<div class=\"space-y-2\">",
        OptionsHtml,
        ~"</div>",
        ExplHtml,
        ~"</div>"
    ].

render_options_html(Options, QId, SelectedAnswer, Submitted, Result) ->
    lists:map(
        fun(Option) ->
            render_option_html(Option, QId, SelectedAnswer, Submitted, Result)
        end,
        Options
    ).

render_option_html(#{id := OId, text := OText}, QId, SelectedAnswer, Submitted, Result) ->
    IsSelected = SelectedAnswer =:= OId,
    BaseClass =
        case IsSelected of
            true -> ~"border-indigo-300 bg-indigo-50";
            false -> ~"border-gray-100 hover:bg-gray-50"
        end,
    ResultClass =
        case {Submitted, Result, IsSelected} of
            {true, #{correct := true}, true} -> ~" border-green-300 bg-green-50";
            {true, #{correct := false}, true} -> ~" border-red-300 bg-red-50";
            _ -> ~""
        end,
    Checked =
        case IsSelected of
            true -> ~" checked";
            false -> ~""
        end,
    Disabled =
        case Submitted of
            true -> ~" disabled";
            false -> ~""
        end,
    [
        ~"<label class=\"flex items-center gap-3 p-3 rounded-lg cursor-pointer border transition-all ",
        BaseClass,
        ResultClass,
        ~"\">",
        ~"<input type=\"radio\" name=\"q_",
        QId,
        ~"\" value=\"",
        OId,
        ~"\"",
        Checked,
        Disabled,
        ~" onclick=\"arizona.pushEvent('select_answer', {question_id: '",
        QId,
        ~"', answer_id: '",
        OId,
        ~"'})\" class=\"text-indigo-600\" />",
        ~"<span class=\"text-gray-700\">",
        OText,
        ~"</span>",
        ~"</label>"
    ].

explanation_html(true, #{explanation := Expl}, true, _QId) ->
    [
        ~"<div class=\"mt-3 p-3 bg-blue-50 border border-blue-200 rounded-lg\">",
        ~"<p class=\"text-sm text-blue-800\">",
        Expl,
        ~"</p>",
        ~"</div>"
    ];
explanation_html(true, Result, false, QId) when Result =/= undefined ->
    [
        ~"<button onclick=\"arizona.pushEvent('show_explanation', {question_id: '",
        QId,
        ~"'})\" class=\"mt-3 text-sm text-indigo-600 hover:underline\">",
        ~"Show explanation</button>"
    ];
explanation_html(_, _, _, _) ->
    ~"".

extract_module_id(Path) ->
    case binary:split(Path, <<"/">>, [global]) of
        [<<>>, <<"modules">>, Id | _] -> Id;
        _ -> undefined
    end.
