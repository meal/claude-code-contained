#!/usr/bin/env bash
# Ensure that the Claude Code CLI is installed.
# This script is executed on every container start but exits early if the CLI
# binary is already present.  Having the logic here means users can build from
# this image and swap out the CLI version by simply baking a new layer or by
# defining CLAUDE_VERSION.

set -euo pipefail

CLI_BIN="$(command -v claude-code || true)"

if [ -n "$CLI_BIN" ]; then
  echo "[init] Claude Code CLI already present ($CLI_BIN)"
  exit 0
fi

echo "[init] Installing Claude Code CLI (npm)"

# Users can specify a version via env var.  Fallback to latest.
if [ -n "${CLAUDE_VERSION:-}" ]; then
  npm install -g "@anthropic-ai/claude-code@${CLAUDE_VERSION}"
else
  npm install -g @anthropic-ai/claude-code
fi

echo "[init] Installation finished"
