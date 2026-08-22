.PHONY: all compile serve clean test check

all: compile

compile:
	@rebar3 compile

serve: compile
	@rebar3 nova serve

test:
	@rebar3 ct

check:
	@rebar3 fmt --check
	@rebar3 xref
	@rebar3 dialyzer
	@rebar3 ct

clean:
	@rebar3 clean
