# Claude Code Devcontainer

Running Claude Code directly on the host (`brew install claude-code`) gives it access to your secrets, keys, and credentials.

This image runs Claude in an isolated Docker container with an egress firewall — so it can only reach explicitly allowed domains.

## Prerequisites

- Docker

## Usage

```bash
docker run --rm -it --cap-add NET_ADMIN --cap-add NET_RAW -v "$PWD":/workspace kyxap/claude-sandbox
```

## Firewall

The container blocks all outbound traffic except allowed domains and GitHub IP ranges (fetched dynamically). Verification runs automatically at container start.

Built-in domains are baked into the image from [`.devcontainer/allowed-domains.conf`](.devcontainer/allowed-domains.conf).

To add project-specific domains, create `.claude/allowed-domains.extra.conf` in your project root:

```
my-api.example.com
internal-registry.company.net
```

The built-in domains are always applied; extras are additive.

## Permissions

Claude runs in `--dangerously-skip-permissions` mode by default — the firewall is the safety net.

## Persistent State

Auth tokens, settings, and shell history persist in the workspace bind mount:

- `.claude/` — Claude Code config and auth
- `.commandhistory/` — shell history

Both are gitignored.

## Development

### Docker Compose

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

### File Layout

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

### Updating Versions

Edit `.env`:

```
NODE_VERSION=24-bookworm-slim
CLAUDE_CODE_VERSION=2.1.142
GIT_DELTA_VERSION=0.18.2
```

Then rebuild:

```bash
docker compose up -d --build
```
