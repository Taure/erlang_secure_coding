-module(esc_page_controller).

-export([index/1]).

-spec index(Req :: map()) -> {status, integer(), map(), iodata()}.
index(CowboyReq) ->
    Path = cowboy_req:path(CowboyReq),
    {ViewModule, MountArg} = resolve_view(Path),
    ArizonaReq = arizona_cowboy_request:new(CowboyReq),
    try
        View = arizona_view:call_mount_callback(ViewModule, MountArg, ArizonaReq),
        {Html, _RenderView} = arizona_renderer:render_layout(View),
        {status, 200, #{<<"content-type">> => <<"text/html; charset=utf-8">>}, Html}
    catch
        _:_:_ ->
            {status, 500, #{<<"content-type">> => <<"text/html">>}, <<"Internal Server Error">>}
    end.

resolve_view(<<"/modules/", _/binary>>) ->
    {esc_module_view, undefined};
resolve_view(_) ->
    {esc_home_view, undefined}.
