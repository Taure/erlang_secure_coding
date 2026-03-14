# --- Builder Stage ---
ARG ERLANG_VERSION=28.0.4
ARG REBAR_VERSION=3.25.0

FROM erlang:${ERLANG_VERSION} AS builder

RUN apt-get update && apt-get install -y git && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Cache dependency layer
COPY rebar.config rebar.lock* ./
RUN rebar3 compile || true

# Copy source and build release
COPY . .
RUN rebar3 as prod release

# --- Runtime Stage ---
FROM debian:trixie-slim

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        libssl3 libncurses6 libstdc++6 && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY --from=builder /app/_build/prod/rel/erlang_secure_coding ./

# Arizona static assets
RUN mkdir -p lib/arizona_core-*/priv/static 2>/dev/null || true

ENV HOME=/app
EXPOSE 8080

CMD ["bin/erlang_secure_coding", "foreground"]
