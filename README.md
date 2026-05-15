# Claude Code Devcontainer

Isolated environment for running Claude Code inside Docker with egress firewall.
Claude runs in `--dangerously-skip-permissions` mode by default — the firewall is the safety net.

## Prerequisites

- Docker

## Usage

Interactive mode (launches Claude directly):

```bash
docker compose run --rm -it --build claude
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
  entrypoint.sh           # firewall + claude (TTY) or sleep (daemon)
  init-firewall.sh        # egress firewall (DROP all, allow specific domains)
  lib/firewall-helpers.sh # shared functions for firewall script
  allowed-domains.conf    # default allowed domains (baked into image)
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

The container blocks all outbound traffic except allowed domains and GitHub IP ranges (fetched dynamically). Verification runs automatically at container start.

Built-in domains are baked into the image from `.devcontainer/allowed-domains.conf`. To add project-specific domains, create `.claude/allowed-domains.extra.conf` — it is merged with the built-in list at startup. Apply changes:

```bash
docker compose restart claude
```

## Using the image in another project

```bash
docker run --rm -it \
  --cap-add NET_ADMIN --cap-add NET_RAW \
  -v "$PWD":/workspace \
  kyxap/claude-sandbox
```

To add extra allowed domains, create `.claude/allowed-domains.extra.conf` in the project root:

```
my-api.example.com
internal-registry.company.net
```

The built-in domains are always applied; extras are additive.

## CI

GitHub Actions workflow (`.github/workflows/ci.yml`) runs on every push and PR to `master`:

- **test** — runs bats unit tests
- **build-and-push** — builds the Docker image and pushes to `kyxap/claude-sandbox` on Docker Hub (only on push to `master` or version tag)

Image tags: `latest` on master push, semver from git tag (e.g., `v1.2.3` → `1.2.3`).

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
