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
                {"/modules/:module_id", fun esc_page_controller:index/1, #{methods => [get]}},
                {"/live", esc_live_handler, #{protocol => ws}},
                {"/assets/[...]", "static/assets"}
            ]
        }
    ].
