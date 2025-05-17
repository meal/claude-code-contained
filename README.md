# Claude Code CLI – Containerised Development Environment

Ready-to-use, reproducible Claude Code CLI that runs **entirely inside a Docker
container**.  No Node, Python or global tools need to be installed on your
workstation – only Docker.

## Key Features

1. **Ready-to-use CLI** – image ships with the latest `@anthropic-ai/claude-code`
   already installed.  Start coding straight away, zero local setup.
2. **Works everywhere** – Linux, macOS, Windows… if it can run Docker it can
   run this image.
3. **Project isolation** – the CLI is executed inside the container while your
   source code is mounted at run-time.  Nothing is installed globally on the
   host.
4. **Makefile interface** – common tasks such as build, test and shell access
   are wrapped in a dead-simple `Makefile` (see below).
5. **Extensible architecture** – drop additional `*.sh` files into
   `docker-entrypoint.d/` and they will be executed automatically when the
   container starts.
6. **Secure container** – includes a health-check so orchestrators such as
   Docker Compose or Kubernetes can verify the CLI is healthy.
7. **Correct permissions** – the entrypoint re-executes the CLI as a non-root
   user that matches the UID/GID specified through environment variables
   (defaults to `1000:1000`).  This prevents root-owned files from appearing in
   your working directory.
8. **Performance optimised** – the image declares `/root/.npm` as a volume so
   the npm cache is persisted between runs, dramatically speeding-up CLI
   upgrades.
   The cache is also referenced in the `compose.yaml` volume configuration.
9. **Authentication support** – export `ANTHROPIC_API_KEY` (or mount a file via
   Docker secrets) and the CLI will pick it up automatically.
10. **Network resilience** – npm is configured for multiple retries with an
    exponential back-off, making the initial installation much more robust on
    flaky connections.

11. **Proper PID 1** – the container now starts under [`tini`](https://github.com/krallin/tini)
    for correct signal handling and zombie reaping (equivalent to
    `docker run --init`).

## Quick start

### Option 0 – Use the pre-built image (no build step!)

```bash
# 1. Pull the image – this is a one-time operation updated with each release
docker pull ghcr.io/meal/claude-code-cli:latest

# 2. Run Claude Code CLI on the current directory
#    (add your ANTHROPIC_API_KEY via env or Docker secrets)
docker run --rm -it \
  -v "$PWD":/app \
  -e ANTHROPIC_API_KEY \
  -e APP_UID=$(id -u) -e APP_GID=$(id -g) \
  ghcr.io/meal/claude-code-cli:latest
```

The image is published for `linux/amd64` and `linux/arm64` so it runs on both
modern Mac/Apple-Silicon and x86-64 machines out of the box.


### Option 1 – Docker Compose (recommended)

1. Add your API key to the environment (or put it in a `.env` file):

   ```bash
   export ANTHROPIC_API_KEY="sk-…"
   ```

2. Start an interactive Claude Code session:

   ```bash
   docker compose run --rm claude
   ```

3. Need a shell inside the container?

   ```bash
   docker compose run --rm claude bash
   ```

### Option 2 – Plain Docker + Makefile

```bash
# Build (only once or after changes)
make build

# Run Claude Code CLI (pass extra args via ARGS)
make claude ARGS="--help"
# Open an interactive shell
make shell
```

## Native-like CLI alias (`claude` / `code`)

If you don’t want to type `docker run …` or `docker compose …` each time, a
tiny wrapper script is included under `bin/`.  Installing it puts two
executables, `claude` and `code`, into `~/.local/bin` so they behave exactly
like a normal CLI tool while still running inside Docker under the hood.

```bash
# One-time installation
make install-wrapper   # copies bin/claude & bin/code into ~/.local/bin

# Ensure ~/.local/bin is on your PATH (bash/zsh example)
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc  # or ~/.zshrc
source ~/.bashrc

# Now just use it!
claude --help
code --version   # same command, two names
```

The wrapper automatically:

• Mounts the current directory into the container (`-v "$PWD":/app`).
• Forwards `ANTHROPIC_API_KEY` if present and stores it securely for next time.
• Aligns UID/GID so generated files aren’t root-owned.
• Uses the published multi-arch image by default – override with `IMAGE` env.

### Persist your API key once

The very first time you can either export the key or call `--set-key`:

```bash
# Option A – via env (automatically stored for future runs)
ANTHROPIC_API_KEY="sk-…" claude --version

# Option B – explicit
claude --set-key sk-…
```

After that the wrapper will read the key from
`~/.config/claude-code/api_key` (0600 permissions) automatically – no more
re-entering or exporting.

Feel free to inspect `bin/claude` to see the simple `docker run` it executes.

Both options mount the **current working directory** into `/app` inside the
container, so the CLI works on your real source files while remaining isolated
from your host.

## CLI helpers

### Makefile targets (optional)

| Target    | Description                                                        |
|-----------|--------------------------------------------------------------------|
| `build`   | Build or rebuild the image locally                                  |
| `claude`  | Same as `docker run … claude` – accepts extra CLI args via `ARGS`  |
| `shell`   | Interactive Bash shell inside the container                        |
| `clean`   | Remove the local image cache                                       |

### docker compose service

The `compose.yaml` file defines a single `claude` service with sensible defaults
(volumes, health-check, UID/GID mapping).  Use it with any Compose
implementation:

```bash
# build and run interactively
docker compose run --rm claude

# upgrade the CLI version baked into the image
docker compose build --build-arg CLAUDE_VERSION=0.8.0
```

## Image details

* **Base image:** `debian:bookworm-slim`
* **Entry point:** `docker-entrypoint.sh` (drops privileges & executes CLI)
* **Volume:** `/root/.npm` – persisted npm cache
* **Health-check:** runs `claude --version` every 30 seconds
* **Pre-built tags:** `ghcr.io/meal/claude-code-cli:latest` (multi-arch)

## Extending / customising

Need extra packages?  Write a new script in `docker-entrypoint.d/` or create
your own `Dockerfile` that starts with:

```dockerfile
# pin to the exact version you want
FROM ghcr.io/meal/claude-code-cli:latest
# …add layers here…
```

## Troubleshooting

• **Files owned by root** – pass `APP_UID` / `APP_GID` environment variables in
  your Compose override or Docker command so they match your host user (this is
  automatic when using the provided Makefile / compose file).
• **Slow first start** – the very first run downloads the CLI. Subsequent runs
  will be instant thanks to the cached npm volume.

---

Made with ❤️ &nbsp;by
[`@meal`](https://github.com/meal).
