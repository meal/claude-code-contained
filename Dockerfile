# syntax=docker/dockerfile:1.4

# ----------------------------------------------------------------------------
# Claude Code CLI – Docker image
# ----------------------------------------------------------------------------
#
# This image provides the Claude Code CLI inside a Debian based container.  A
# source directory must be mounted to /app when the container is executed, e.g.:
#
#   docker run --rm -it -v $(pwd):/app claude-code-cli <cli-args>
#
# The entrypoint will automatically drop privileges to a non-root user and
# execute the Claude Code CLI in the mounted directory unless an alternative
# command is supplied.
# ----------------------------------------------------------------------------

FROM debian:bookworm-slim AS base

# Metadata
LABEL maintainer="@meal"
LABEL org.opencontainers.image.title="claude-code-cli"
LABEL org.opencontainers.image.description="Dockerised Claude Code CLI"
LABEL org.opencontainers.image.licenses="Apache-2.0"

# ----------
# Build-time dependencies
# ----------
RUN --mount=type=cache,target=/var/cache/apt \
    apt-get update -qq && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
      ca-certificates curl git gosu make python3 python3-pip tini && \
    rm -rf /var/lib/apt/lists/*

# Use Tini as PID 1 for proper signal handling (docker run --init alternative)
ENTRYPOINT ["/usr/bin/tini", "--", "/usr/local/bin/docker-entrypoint.sh"]

# ----------
# Node.js – via NodeSource (current LTS)
# ----------
ARG NODE_MAJOR=20
RUN curl -fsSL https://deb.nodesource.com/setup_${NODE_MAJOR}.x | bash - && \
    apt-get install -y --no-install-recommends nodejs && \
    npm set prefix /usr/local && \
    npm cache clean --force && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Build argument allows pinning a specific CLI version (defaults to latest)
ARG CLAUDE_VERSION=latest
ENV CLAUDE_VERSION=${CLAUDE_VERSION}

# ----------
# Create non-root user to execute the CLI
# ----------
ENV APP_USER=appuser \
    APP_UID=1000 \
    APP_GID=1000 \
    APP_HOME=/home/appuser

RUN adduser --disabled-password --gecos "" --uid "$APP_UID" --home "$APP_HOME" "$APP_USER"

# ----------
# Install Claude Code CLI (global)
# ----------
RUN if [ "$CLAUDE_VERSION" = "latest" ]; then \
      npm install -g @anthropic-ai/claude-code; \
    else \
      npm install -g @anthropic-ai/claude-code@"$CLAUDE_VERSION"; \
    fi

# ----------
# Persist npm cache across container instances (run-time)
# ----------
VOLUME /root/.npm

# Configure npm for additional network resilience
ENV NPM_CONFIG_FETCH_RETRIES=5 \
    NPM_CONFIG_FETCH_RETRY_FACTOR=2 \
    NPM_CONFIG_FETCH_RETRY_MINTIMEOUT=10000

# ----------
# Container health check – verifies CLI is functional
# ----------
HEALTHCHECK --interval=30s --timeout=10s --start-period=30s --retries=3 CMD claude --version || exit 1

# ----------
# Copy entrypoint scripts
# ----------
COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
COPY docker-entrypoint.d /docker-entrypoint.d

RUN chmod +x /usr/local/bin/docker-entrypoint.sh && \
    chmod -R +x /docker-entrypoint.d

# ----------
# Working directory & entrypoint
# ----------

WORKDIR /app

CMD []

# ----------------------------------------------------------------------------
# End of Dockerfile
# ----------------------------------------------------------------------------
