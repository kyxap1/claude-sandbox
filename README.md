# Claude Code Devcontainer

Isolated environment for running Claude Code inside Docker with egress firewall.

## Prerequisites

- Docker

## Usage

Interactive mode (launches Claude directly):

```bash
docker compose run --rm -it claude
```

Daemon mode (background, then attach):

```bash
docker compose up -d --build
docker compose exec -it claude claude
```

Stop:

```bash
docker compose down
```

## File Layout

```
.devcontainer/
  Dockerfile              # image: node + claude-code + firewall tools
  devcontainer.json       # fallback for VS Code / Codespaces users
  init-firewall.sh        # egress firewall (DROP all, allow specific domains)
  lib/firewall-helpers.sh # shared functions for firewall script
  allowed-domains.conf    # domains allowed through the firewall
compose.yaml              # primary entry point
.env                      # pinned versions (single source of truth)
```

## Updating Versions

Edit `.env`:

```
NODE_VERSION=24-bookworm-slim
CLAUDE_CODE_VERSION=2.1.128
GIT_DELTA_VERSION=0.18.2
```

Then rebuild:

```bash
docker compose up -d --build
```

## Firewall

The container blocks all outbound traffic except domains listed in `.devcontainer/allowed-domains.conf` and GitHub IP ranges (fetched dynamically).

To allow a new domain, add it to `allowed-domains.conf` and restart the container:

```bash
docker compose restart claude
```

No rebuild needed — the config file is read from the bind-mounted workspace at container start.

Verification runs automatically at container start. Telemetry and autoupdater are disabled via environment variables.

## CI

GitHub Actions workflow (`.github/workflows/ci.yml`) runs on every push and PR to `master`:

- **test** — runs bats unit tests
- **build-and-push** — builds the Docker image and pushes to `kyxap/claude-sandbox` on Docker Hub (only on push to `master` or version tag)

Image tags: semver from git tag (e.g., `v1.2.3` → `1.2.3`) + short commit SHA. Immutable tags are enabled on Docker Hub.

Build args are read from `.env` automatically — update versions there, CI picks them up.

### Required secrets and variables

Add these in GitHub repo settings → Secrets and variables → Actions:

- **Variable:** `DOCKERHUB_USERNAME` — Docker Hub username
- **Secret:** `DOCKERHUB_TOKEN` — Docker Hub access token ([create one here](https://hub.docker.com/settings/security))

## Persistent State

Auth tokens, settings, and shell history persist in the workspace bind mount:

- `.claude/` — Claude Code config and auth
- `.commandhistory/` — shell history

Both are gitignored.
