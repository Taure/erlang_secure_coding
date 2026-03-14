-module(erlang_secure_coding_app).
-behaviour(application).

-export([start/2, stop/1]).

start(_StartType, _StartArgs) ->
    esc_progress:init(),
    erlang_secure_coding_sup:start_link().

stop(_State) ->
    ok.
