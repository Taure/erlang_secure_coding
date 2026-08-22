-module(erlang_secure_coding_router).
-behaviour(nova_router).

-export([routes/1]).

routes(_Environment) ->
    [
        #{
            prefix => "",
            security => false,
            routes => [
                {"/", fun esc_page_controller:index/1, #{methods => [get]}},
                {"/modules/:module_id", fun esc_page_controller:show_module/1, #{methods => [get]}},
                {"/modules/:module_id/quiz", fun esc_page_controller:submit_quiz/1, #{
                    methods => [post]
                }},
                {"/assets/[...]", "static/assets"}
            ]
        }
    ].
