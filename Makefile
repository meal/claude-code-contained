# ---------------------------------------------------------------------------
# Claude Code CLI – Makefile helper
# ---------------------------------------------------------------------------
#
# Provides a tiny convenience layer on top of the Docker image so that common
# tasks can be triggered with a single, memorable command.
# ---------------------------------------------------------------------------

# Name of the container image to pull / run.  Override with
#   make IMAGE_NAME=myorg/claude-code-cli:dev …
IMAGE_NAME ?= ghcr.io/meal/claude-code-cli:latest
# Forward important environment variables into the container (if present)
ENV_VARS := \
  $(if $(ANTHROPIC_API_KEY),-e ANTHROPIC_API_KEY=$(ANTHROPIC_API_KEY)) \
  -e APP_UID=$(shell id -u) -e APP_GID=$(shell id -g)

# Detect current directory (passed as volume)
PWD_ABS := $(shell pwd)

.PHONY: build shell claude clean install-wrapper

build:
	docker build -t $(IMAGE_NAME) .

# Drop into an interactive Bash shell inside the container
shell: build
	docker run --rm -it \
		-v $(PWD_ABS):/app \
		$(ENV_VARS) \
		$(IMAGE_NAME) bash

# Run the Claude Code CLI with optional ARGS variable, e.g.:
#   make claude ARGS="--help"
claude: build
	docker run --rm -it \
		-v $(PWD_ABS):/app \
		$(ENV_VARS) \
		$(IMAGE_NAME) $(ARGS)

clean:
	docker rmi -f $(IMAGE_NAME) || true

# Install the host-side wrapper (~/\.local/bin/claude & code)
install-wrapper:
	mkdir -p $(HOME)/.local/bin
	install -m 0755 bin/claude $(HOME)/.local/bin/claude
	ln -sf $(HOME)/.local/bin/claude $(HOME)/.local/bin/code
	@echo "Wrapper installed to $(HOME)/.local/bin. Make sure this directory is in your PATH."
