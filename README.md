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
FIREWALL=false ./claude-sandbox
```

Or in `compose.yaml`:

```yaml
environment:
  FIREWALL: "false"
```

To see detailed firewall init logs (domain resolution, IP ranges, etc.):

```bash
FIREWALL_VERBOSE=true ./claude-sandbox
```

Built-in domains are baked into the image from [`.devcontainer/allowed-domains.conf`](.devcontainer/allowed-domains.conf).

To add project-specific domains, create `.claude/allowed-domains.extra.conf` in your project root:

```
my-api.example.com
internal-registry.company.net
```

The built-in domains are always applied; extras are additive.

Changes to `allowed-domains.extra.conf` are picked up automatically — no container restart needed. A background watcher monitors the file via `inotifywait` and reloads firewall rules on change.

### Blocked connection logging

Blocked outbound connections are logged to stderr via NFLOG + ulogd2:

```
May 20 23:05:02 6f020ee1fac6 BLOCKED: IN= OUT=eth0 SRC=172.17.0.3 DST=93.184.215.14 PROTO=TCP SPT=41068 DPT=443 UID=1000
```

## Permissions

Claude runs in `--dangerously-skip-permissions` mode by default — the firewall is the safety net.

## Autonomous Mode

The container supports fully autonomous, non-interactive operation via `CLAUDE.md`. Claude executes tasks without asking questions — git, kubectl, package installs, multi-file changes are all pre-approved.

Plugins installed on the host (`~/.claude/plugins/`) are mounted read-only as a seed (`CLAUDE_CODE_PLUGIN_SEED_DIR`) and loaded into the container's own writable cache at start (`seed-plugins.sh`), so the host's plugin registry is never modified.

## SSH Key

If `~/.ssh/id_rsa` exists on the host, it is mounted read-only into the container for git clone over SSH. No action needed if the file is absent — the mount is conditional.

## Kubeconfig

If `~/.kube/config` exists on the host, it is mounted read-only into the container so the Kubernetes MCP server (and `kubectl`) can find a cluster. The mount is conditional — without the file, the Kubernetes MCP server fails to start.

To let the firewall reach your cluster's API server, add its host (or IP/CIDR) to `.claude/allowed-domains.extra.conf`. Note that exec-based auth helpers referenced by your kubeconfig (e.g. `aws`, `gcloud`) are not present in the container.

## Persistent State

- `~/.claude/` (host) — auth, global settings, plugins (shared across projects)
- `.commandhistory/` (workspace) — shell history

## Development

### Local image builds

By default `./claude-sandbox` runs the published image (`--pull always`), so local changes to the `Dockerfile` or baked-in config are ignored. To build the image locally from this repo and run that instead:

```bash
BUILD=true ./claude-sandbox
```

This builds via `compose.yaml` (versions from `.env`), then runs with `--pull never`. Runtime-only changes — launcher mounts and env vars — take effect without `BUILD`.

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
  Dockerfile              # image: node + claude-code + firewall tools + kubectl + wizcli
  devcontainer.json       # fallback for VS Code / Codespaces users
  _firewall-helpers.sh    # shared functions for firewall script
  entrypoint.sh           # firewall + watcher + plugin seed + claude (TTY) or sleep (daemon)
  init-firewall.sh        # egress firewall (DROP all, allow specific domains)
  seed-plugins.sh         # register host plugin seed into the container cache on start
  watch-domains.sh        # inotifywait watcher, reloads firewall on config change
  allowed-domains.conf    # default allowed domains (baked into image)
  ulogd.conf              # NFLOG → stderr logging config (baked into image)
  managed-settings.json   # Claude Code managed settings (baked into image)
compose.yaml              # primary entry point
.env                      # pinned versions (single source of truth)
```

### Updating Versions

Edit `.env`:

```
NODE_VERSION=24-bookworm-slim
CLAUDE_CODE_VERSION=2.1.205
GIT_DELTA_VERSION=0.18.2
KUBECTL_VERSION=1.32.4
WIZCLI_VERSION=0.109.14
```

When updating `KUBECTL_VERSION` or `WIZCLI_VERSION`, update the corresponding sha256 checksums in the Dockerfile.

Then rebuild:

```bash
docker compose build
```

### Tests

```bash
./tests/bats/bin/bats tests/
```
