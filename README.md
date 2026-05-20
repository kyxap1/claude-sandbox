# Claude Code Devcontainer

Running Claude Code directly on the host (`brew install claude-code`) gives it access to your secrets, keys, and credentials.

This image runs Claude in an isolated Docker container with an egress firewall — so it can only reach explicitly allowed domains.

## Prerequisites

- Docker

## Usage

```bash
./claude-sandbox
```

Add to your `~/.bashrc` or `~/.zshrc` for a convenient alias:

```bash
alias claude='/path/to/claude-sandbox'
```

Then use it like the regular CLI: `claude`, `claude -p "fix the bug"`, etc.

Mount additional directories with `-v`:

```bash
claude -v ~/other-repo
claude -v ~/repo-a -v ~/repo-b
```

Mounted directories are available inside the container at `/mnt/<dirname>`.

## Firewall

The container blocks all outbound traffic except allowed domains and GitHub IP ranges (fetched dynamically). Verification runs automatically at container start.

To disable the firewall:

```bash
SANDBOX_FIREWALL=false ./claude-sandbox
```

Or in `compose.yaml`:

```yaml
environment:
  SANDBOX_FIREWALL: "false"
```

Built-in domains are baked into the image from [`.devcontainer/allowed-domains.conf`](.devcontainer/allowed-domains.conf).

To add project-specific domains, create `.claude/allowed-domains.extra.conf` in your project root:

```
my-api.example.com
internal-registry.company.net
```

The built-in domains are always applied; extras are additive.

Changes to `allowed-domains.extra.conf` are picked up automatically — no container restart needed. A background watcher monitors the file via `inotifywait` and reloads firewall rules on change.

## Permissions

Claude runs in `--dangerously-skip-permissions` mode by default — the firewall is the safety net.

## Persistent State

- `~/.claude/` (host) — auth, global settings, plugins (shared across projects)
- `.commandhistory/` (workspace) — shell history

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
  _firewall-helpers.sh    # shared functions for firewall script
  entrypoint.sh           # firewall + watcher + claude (TTY) or sleep (daemon)
  init-firewall.sh        # egress firewall (DROP all, allow specific domains)
  watch-domains.sh        # inotifywait watcher, reloads firewall on config change
  allowed-domains.conf    # default allowed domains (baked into image)
  managed-settings.json   # Claude Code managed settings (baked into image)
compose.yaml              # primary entry point
.env                      # pinned versions (single source of truth)
```

### Updating Versions

Edit `.env`:

```
NODE_VERSION=24-bookworm-slim
CLAUDE_CODE_VERSION=2.1.145
GIT_DELTA_VERSION=0.18.2
```

Then rebuild:

```bash
docker compose up -d --build
```
