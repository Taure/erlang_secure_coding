.PHONY: all compile serve assets clean test check

all: compile

compile:
	@rebar3 compile
	@$(MAKE) assets

assets:
	@mkdir -p priv/static/assets/js
	@cp _build/default/lib/arizona_core/priv/static/assets/js/*.min.js priv/static/assets/js/ 2>/dev/null || true

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
	@rm -rf priv/static/assets/js/arizona*.min.js
