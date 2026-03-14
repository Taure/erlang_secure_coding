# Contributing to Erlang Secure Coding

## Adding a New Security Module

All curriculum content lives in `src/curriculum/esc_curriculum.erl`. Each module is a private function returning a map.

### 1. Define the module function

Add a new function at the bottom of `esc_curriculum.erl`:

```erlang
your_topic_module() ->
    #{
        id => <<"your_topic">>,
        number => 13,  %% next sequential number
        title => <<"Your Topic Title">>,
        description => <<"One-line description shown on the home page.">>,
        estimated_minutes => 20,
        sections => [
            #{
                title => <<"Section Title">>,
                content => <<"<p>HTML content explaining the concept.</p>">>
            },
            #{
                title => <<"Code Examples">>,
                content => <<"<p>Demonstrate vulnerable and safe patterns.</p>">>,
                code_examples => [
                    #{
                        title => <<"Vulnerable Pattern">>,
                        code => <<"os:cmd(UserInput).">>,
                        vulnerable => true,
                        explanation => <<"Why this is dangerous.">>
                    },
                    #{
                        title => <<"Safe Alternative">>,
                        code => <<"open_port({spawn_executable, Path}, [...]).">>,
                        vulnerable => false,
                        explanation => <<"Why this is safe.">>,
                        output => <<"Optional output to display.">>
                    }
                ]
            }
        ],
        quiz => [
            #{
                id => <<"your_topic_q1">>,
                type => multiple_choice,  %% or true_false
                prompt => <<"Question text?">>,
                options => [
                    #{id => <<"a">>, text => <<"Option A">>},
                    #{id => <<"b">>, text => <<"Option B">>},
                    #{id => <<"c">>, text => <<"Option C">>},
                    #{id => <<"d">>, text => <<"Option D">>}
                ],
                correct => <<"b">>,
                explanation => <<"Why B is correct.">>
            }
        ]
    }.
```

### 2. Register the module

Add your function to the `modules/0` list:

```erlang
modules() ->
    [
        introduction_module(),
        %% ... existing modules ...
        web_security_module(),
        your_topic_module()   %% <-- add here
    ].
```

That's it — the home page and module view render automatically from this list.

### 3. Data structure reference

| Field | Type | Required | Notes |
|-------|------|----------|-------|
| `id` | `binary()` | yes | URL-safe slug, used in `/modules/:id` |
| `number` | `pos_integer()` | yes | Display order on home page |
| `title` | `binary()` | yes | Module heading |
| `description` | `binary()` | yes | Shown on home page card |
| `estimated_minutes` | `pos_integer()` | yes | Reading time estimate |
| `sections` | `[section()]` | yes | At least one section |
| `quiz` | `[quiz_question()]` | yes | At least one question |

**Section fields:**

| Field | Type | Required | Notes |
|-------|------|----------|-------|
| `title` | `binary()` | yes | Section heading |
| `content` | `binary()` | yes | HTML content |
| `code_examples` | `[code_example()]` | no | Optional code samples |

**Code example fields:**

| Field | Type | Required | Notes |
|-------|------|----------|-------|
| `title` | `binary()` | yes | Label for the code block |
| `code` | `binary()` | yes | Erlang source code |
| `vulnerable` | `boolean()` | no | Defaults to `false`. Red border if `true`, green if `false` |
| `explanation` | `binary()` | yes | Shown below the code block |
| `output` | `binary()` | no | Optional shell output |

**Quiz question fields:**

| Field | Type | Required | Notes |
|-------|------|----------|-------|
| `id` | `binary()` | yes | Unique within the module (e.g. `<<"topic_q1">>`) |
| `type` | `multiple_choice \| true_false` | yes | |
| `prompt` | `binary()` | yes | Question text |
| `options` | `[#{id, text}]` | yes | For true/false use `<<"true">>` and `<<"false">>` as ids |
| `correct` | `binary()` | yes | Must match one option id |
| `explanation` | `binary()` | yes | Shown after submission |

### 4. Content guidelines

- Use HTML in `content` fields (`<p>`, `<ul>`, `<ol>`, `<code>`, `<strong>`)
- Always include both vulnerable and safe code examples where applicable
- Quiz questions should test understanding, not memorization
- Each module should have at least 2 quiz questions
- Keep `estimated_minutes` realistic

### 5. Run checks

```bash
# Format
rebar3 fmt

# Cross-reference
rebar3 xref

# Type analysis
rebar3 dialyzer

# Run tests (validates data integrity)
rebar3 ct

# Verify formatting is clean
rebar3 fmt --check
```

The test suite in `test/esc_curriculum_SUITE.erl` automatically validates:
- All modules have required fields
- Module IDs are unique
- All sections have content
- Quiz answers reference valid options
- Quiz question IDs are unique per module

## Adding Tests

Test suites live in `test/`. The existing suites cover:
- `esc_curriculum_SUITE` — data integrity for all modules
- `esc_quiz_grader_SUITE` — grading logic

If you add new curriculum features (e.g. a new question type), add corresponding test cases.

## Deployment

The app runs on [Fly.io](https://fly.io). Deployment happens via:

```bash
fly deploy
```

The `Dockerfile` builds a production release. Configuration:
- `config/dev_sys.config.src` — local development
- `config/prod_sys.config.src` — production (Fly.io)

## CI

CI runs automatically on push and PRs via [erlang-ci](https://github.com/Taure/erlang-ci). It runs:
- `rebar3 compile`
- `rebar3 fmt --check`
- `rebar3 xref`
- `rebar3 dialyzer`
- `rebar3 ct`
- `rebar3 eunit`
