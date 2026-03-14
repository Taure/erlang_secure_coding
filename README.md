# Erlang Secure Coding

Interactive web-based curriculum teaching developers how to write secure Erlang/OTP applications. Covers BEAM VM-specific attack vectors that exist despite Erlang's built-in safety properties.

## Topics

The curriculum covers 12 modules, each with lessons, code examples, and quizzes:

1. **Introduction to Erlang Security** — BEAM VM security model
2. **Atom Exhaustion** — Creating atoms from untrusted input
3. **Serialisation/Deserialization** — Unsafe `binary_to_term/1`
4. **Command Injection** — `os:cmd/1` with untrusted input
5. **Sensitive Data** — Process state visibility and crash dumps
6. **Memory Exhaustion** — Resource starvation attacks
7. **Distribution** — Erlang distribution protocol risks
8. **NIF & Port Safety** — Native interface and external port security
9. **Code Loading** — Runtime code loading without verification
10. **Scheduling & Types** — Scheduler starvation, type safety
11. **Introspection** — Observer and reflection-based disclosure
12. **Web Security** — Web vulnerabilities in Nova applications

Each module includes:
- Side-by-side vulnerable vs. safe code examples
- Shell output demonstrations
- Multiple choice quizzes with immediate grading

## Stack

- [Nova](https://github.com/novaframework/nova) — Erlang web framework
- [Arizona](https://github.com/Taure/arizona_core) — Real-time LiveView framework
- Tailwind CSS

## Development

```shell
rebar3 nova serve
```

The app runs at `http://localhost:8080`.

## Deployment

Deployed on Fly.io:

```shell
fly deploy
```

## Adding Modules

Curriculum content is fully declarative. To add a new module:

1. Create a module function in `src/curriculum/esc_curriculum.erl`
2. Register it in the `modules()` list

No changes to controllers, views, or routing needed.

## License

Apache 2.0
