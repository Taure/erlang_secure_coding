-module(esc_home_view).
-behaviour(arizona_view).
-compile({parse_transform, arizona_parse_transform}).

-export([mount/2, layout/1, render/1]).

mount(_Arg, Req) ->
    Modules = esc_curriculum:modules(),
    Path = arizona_request:get_path(Req),
    Bindings = #{id => ~"home", modules => Modules},
    Layout = {?MODULE, layout, main_content, #{active_url => Path}},
    arizona_view:new(?MODULE, Bindings, Layout).

layout(Bindings) ->
    arizona_template:from_html(
        ~""""
    <!DOCTYPE html>
    <html lang="en">
    <head>
        <meta charset="UTF-8" />
        <meta name="viewport" content="width=device-width, initial-scale=1.0" />
        <title>Erlang Secure Coding</title>
        <script src="https://cdn.tailwindcss.com"></script>
        <link rel="stylesheet" href="/assets/css/app.css" />
        <script type="module">
            import Arizona from '/assets/js/arizona.min.js';
            globalThis.arizona = new Arizona();
            arizona.connect('/live');
        </script>
    </head>
    <body class="bg-gray-50 min-h-screen">
        <nav class="bg-indigo-700 text-white px-6 py-4">
            <div class="max-w-5xl mx-auto flex items-center justify-between">
                <a href="/" class="text-xl font-bold tracking-tight">Erlang Secure Coding</a>
                <span class="text-indigo-200 text-sm">Interactive Security Curriculum</span>
            </div>
        </nav>
        <main class="max-w-5xl mx-auto px-6 py-8">
            {arizona_template:render_slot(maps:get(main_content, Bindings))}
        </main>
        <footer class="text-center text-gray-400 text-sm py-8">
            Built with Nova + Arizona
        </footer>
    </body>
    </html>
    """"
    ).

render(Bindings) ->
    arizona_template:from_html(
        ~""""
    <div id="{arizona_template:get_binding(id, Bindings)}">
        <div class="mb-8">
            <h1 class="text-3xl font-bold text-gray-900 mb-2">Security Curriculum</h1>
            <p class="text-gray-600">Learn to write secure Erlang/OTP applications through interactive lessons and quizzes.</p>
        </div>
        <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
            {arizona_template:render_list(fun(Module) ->
                #{id := MId, number := Num, title := Title,
                  description := Desc, estimated_minutes := Mins} = Module,
                arizona_template:from_html(~"""
                <a href="/modules/{MId}" class="block bg-white rounded-lg shadow-sm border border-gray-200 p-6 hover:shadow-md hover:border-indigo-300 transition-all">
                    <div class="flex items-center gap-3 mb-3">
                        <span class="bg-indigo-100 text-indigo-700 text-sm font-semibold px-2.5 py-0.5 rounded">Module {integer_to_binary(Num)}</span>
                        <span class="text-gray-400 text-sm">{integer_to_binary(Mins)} min</span>
                    </div>
                    <h2 class="text-lg font-semibold text-gray-900 mb-2">{Title}</h2>
                    <p class="text-gray-600 text-sm">{Desc}</p>
                </a>
                """) end,
                arizona_template:get_binding(modules, Bindings)
            )}
        </div>
    </div>
    """"
    ).
