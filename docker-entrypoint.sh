#!/usr/bin/env bash
# ----------------------------------------------------------------------------
# docker-entrypoint.sh
# ----------------------------------------------------------------------------
# Main entrypoint executed when the container starts.  It initialises the image
# by running any executable scripts located in /docker-entrypoint.d and then
# either executes the Claude Code CLI (default) or an alternative command that
# was provided as arguments to `docker run`.
#
# Code-style: 2-space indentation, UNIX line endings, `set -e` for error abort.
# ----------------------------------------------------------------------------

set -euo pipefail

# Align UID/GID with host (optional)
if [[ -n "${APP_UID:-}" && -n "${APP_GID:-}" ]]; then
  CURRENT_UID="$(id -u "$APP_USER")"
  CURRENT_GID="$(id -g "$APP_USER")"

  if [[ "$APP_GID" != "$CURRENT_GID" ]]; then
    echo "[entrypoint] updating $APP_USER GID: $CURRENT_GID -> $APP_GID"
    groupmod -g "$APP_GID" "$APP_USER"
  fi

  if [[ "$APP_UID" != "$CURRENT_UID" ]]; then
    echo "[entrypoint] updating $APP_USER UID: $CURRENT_UID -> $APP_UID"
    usermod -u "$APP_UID" -g "$APP_GID" "$APP_USER"
  fi
fi

# Run one-time initialisation scripts (if any)
if [ -d /docker-entrypoint.d ]; then
  for script in /docker-entrypoint.d/*.sh; do
    [ -e "$script" ] || break
    if [ -x "$script" ]; then
      echo "[entrypoint] executing $script"
      "$script"
    else
      echo "[entrypoint] ignoring $script (not executable)"
    fi
  done
fi

# Change to the mounted application directory, creating it if missing.
mkdir -p /app
cd /app

# If the first argument looks like an option or is empty, assume the user wants
# to run the Claude Code CLI.  Otherwise execute the provided command verbatim.

DEFAULT_CMD="claude"

if [ $# -eq 0 ] || [[ "$1" == -* ]]; then
  echo "[entrypoint] executing $DEFAULT_CMD $*"
  exec gosu "$APP_USER" "$DEFAULT_CMD" "$@"
else
  echo "[entrypoint] executing custom command: $*"
  exec "$@"
fi
