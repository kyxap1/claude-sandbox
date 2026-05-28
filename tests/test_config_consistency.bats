#!/usr/bin/env bats

setup() {
    REPO_ROOT="$BATS_TEST_DIRNAME/.."
    DEVCONTAINER_JSON="$REPO_ROOT/.devcontainer/devcontainer.json"
    COMPOSE_YAML="$REPO_ROOT/compose.yaml"
    DOTENV="$REPO_ROOT/.env"
    DOMAINS_CONF="$REPO_ROOT/.devcontainer/allowed-domains.conf"
    DOCKERFILE="$REPO_ROOT/.devcontainer/Dockerfile"
    FIREWALL_SCRIPT="$REPO_ROOT/.devcontainer/init-firewall.sh"
}

# --- .env variables are used in devcontainer.json build args ---

@test ".env: every build variable has a matching ARG in Dockerfile" {
    while IFS='=' read -r key _; do
        [[ -z "$key" || "$key" =~ ^# ]] && continue
        grep -q "^ARG ${key}" "$DOCKERFILE" || continue
        grep -q "^ARG ${key}" "$DOCKERFILE"
    done < "$DOTENV"
}

@test ".env: every build variable is wired through compose.yaml" {
    while IFS='=' read -r key _; do
        [[ -z "$key" || "$key" =~ ^# ]] && continue
        grep -q "^ARG ${key}" "$DOCKERFILE" || continue
        grep -q "${key}:" "$COMPOSE_YAML" || { echo ".env has build ARG $key but compose.yaml does not pass it"; return 1; }
    done < "$DOTENV"
}

# --- allowed-domains.conf ---

@test "allowed-domains.conf exists" {
    [ -f "$DOMAINS_CONF" ]
}

@test "allowed-domains.conf contains api.anthropic.com" {
    grep -q "^api.anthropic.com" "$DOMAINS_CONF"
}

@test "Dockerfile bakes allowed-domains.conf into /etc/" {
    grep -q 'allowed-domains.conf /etc/allowed-domains.conf' "$DOCKERFILE"
}

@test "firewall reads built-in config from /etc/allowed-domains.conf" {
    grep -q '/etc/allowed-domains.conf' "$FIREWALL_SCRIPT"
}

@test "firewall supports extra domains from .claude/" {
    grep -q '/workspace/.claude/allowed-domains.extra.conf' "$FIREWALL_SCRIPT"
}

@test "firewall checks extra config file existence before reading" {
    grep -q '\[ -f "$EXTRA_CONF" \]' "$FIREWALL_SCRIPT"
}

# --- Dockerfile consistency ---

@test "Dockerfile sets SHELL to /bin/bash" {
    grep -q 'ENV SHELL=/bin/bash' "$DOCKERFILE"
}

@test "Dockerfile creates /commandhistory directory" {
    grep -q 'mkdir /commandhistory' "$DOCKERFILE"
}

@test "Dockerfile sets HISTFILE to /commandhistory/.bash_history" {
    grep -q 'HISTFILE=/commandhistory/.bash_history' "$DOCKERFILE"
}

@test "Dockerfile installs claude-code via npm" {
    grep -q '@anthropic-ai/claude-code' "$DOCKERFILE"
}

# --- managed-settings.json ---

@test "managed-settings.json exists" {
    [ -f "$REPO_ROOT/.devcontainer/managed-settings.json" ]
}

@test "managed-settings.json is valid JSON" {
    run jq empty "$REPO_ROOT/.devcontainer/managed-settings.json"
    [ "$status" -eq 0 ]
}

@test "managed-settings.json has skipDangerousModePermissionPrompt" {
    run jq -e '.skipDangerousModePermissionPrompt' "$REPO_ROOT/.devcontainer/managed-settings.json"
    [ "$status" -eq 0 ]
    [ "$output" = "true" ]
}

@test "Dockerfile copies managed-settings.json into /etc/claude-code/" {
    grep -q 'managed-settings.json /etc/claude-code/managed-settings.json' "$DOCKERFILE"
}

# --- watch-domains ---

@test "watch-domains.sh exists" {
    [ -f "$REPO_ROOT/.devcontainer/watch-domains.sh" ]
}

@test "watch-domains.sh uses inotifywait" {
    grep -q 'inotifywait' "$REPO_ROOT/.devcontainer/watch-domains.sh"
}

@test "watch-domains.sh watches allowed-domains.extra.conf" {
    grep -q 'allowed-domains.extra.conf' "$REPO_ROOT/.devcontainer/watch-domains.sh"
}

@test "watch-domains.sh reloads firewall on change" {
    grep -q 'init-firewall.sh' "$REPO_ROOT/.devcontainer/watch-domains.sh"
}

@test "entrypoint starts watch-domains in background" {
    grep -q 'watch-domains.sh &' "$REPO_ROOT/.devcontainer/entrypoint.sh"
}

@test "Dockerfile installs inotify-tools" {
    grep -q 'inotify-tools' "$DOCKERFILE"
}

# --- ulogd / NFLOG logging ---

@test "ulogd.conf exists" {
    [ -f "$REPO_ROOT/.devcontainer/ulogd.conf" ]
}

@test "ulogd.conf listens on NFLOG group 1" {
    grep -q 'group=1' "$REPO_ROOT/.devcontainer/ulogd.conf"
}

@test "ulogd.conf outputs to stderr" {
    grep -q '/dev/stderr' "$REPO_ROOT/.devcontainer/ulogd.conf"
}

@test "Dockerfile copies ulogd.conf into /etc/" {
    grep -q 'ulogd.conf /etc/ulogd-blocked.conf' "$DOCKERFILE"
}

@test "Dockerfile installs ulogd2" {
    grep -q 'ulogd2' "$DOCKERFILE"
}

@test "firewall uses NFLOG target" {
    grep -q 'NFLOG' "$FIREWALL_SCRIPT"
}

@test "firewall NFLOG uses group 1" {
    grep -q '\-\-nflog-group 1' "$FIREWALL_SCRIPT"
}

@test "entrypoint starts ulogd" {
    grep -q 'ulogd' "$REPO_ROOT/.devcontainer/entrypoint.sh"
}

@test "sudoers allows ulogd" {
    grep -q 'ulogd' "$DOCKERFILE"
}

# --- entrypoint firewall toggle ---

@test "entrypoint checks FIREWALL variable" {
    grep -q 'FIREWALL' "$REPO_ROOT/.devcontainer/entrypoint.sh"
}

@test "entrypoint defaults FIREWALL to true" {
    grep -q '${FIREWALL:-true}' "$REPO_ROOT/.devcontainer/entrypoint.sh"
}

@test "compose.yaml declares FIREWALL env" {
    grep -q 'FIREWALL' "$COMPOSE_YAML"
}

@test "compose.yaml has SYS_NICE capability" {
    grep -q 'SYS_NICE' "$COMPOSE_YAML"
}

# --- .env versions are valid ---

@test ".env: NODE_VERSION is set and non-empty" {
    run grep -E '^NODE_VERSION=.+' "$DOTENV"
    [ "$status" -eq 0 ]
}

@test ".env: CLAUDE_CODE_VERSION is set and non-empty" {
    run grep -E '^CLAUDE_CODE_VERSION=.+' "$DOTENV"
    [ "$status" -eq 0 ]
}

@test ".env: GIT_DELTA_VERSION is set and non-empty" {
    run grep -E '^GIT_DELTA_VERSION=.+' "$DOTENV"
    [ "$status" -eq 0 ]
}

@test ".env: KUBECTL_VERSION is set and non-empty" {
    run grep -E '^KUBECTL_VERSION=.+' "$DOTENV"
    [ "$status" -eq 0 ]
}

@test ".env: WIZCLI_VERSION is set and non-empty" {
    run grep -E '^WIZCLI_VERSION=.+' "$DOTENV"
    [ "$status" -eq 0 ]
}

# --- new tools ---

@test "Dockerfile installs openssh-client" {
    grep -q 'openssh-client' "$DOCKERFILE"
}

@test "Dockerfile installs kubectl" {
    grep -q 'kubectl' "$DOCKERFILE"
}

@test "Dockerfile installs wizcli" {
    grep -q 'wizcli' "$DOCKERFILE"
}

# --- plugin seed ---

@test "seed-plugins.sh exists and is executable" {
    [ -x "$REPO_ROOT/.devcontainer/seed-plugins.sh" ]
}

@test "entrypoint calls seed-plugins.sh" {
    grep -q 'seed-plugins.sh' "$REPO_ROOT/.devcontainer/entrypoint.sh"
}

@test "seed-plugins.sh reads CLAUDE_CODE_PLUGIN_SEED_DIR" {
    grep -q 'CLAUDE_CODE_PLUGIN_SEED_DIR' "$REPO_ROOT/.devcontainer/seed-plugins.sh"
}

@test "Dockerfile creates the plugin cache dir" {
    grep -q '/home/node/.claude-plugins' "$DOCKERFILE"
}

@test "all launch methods set CLAUDE_CODE_PLUGIN_SEED_DIR" {
    grep -q 'CLAUDE_CODE_PLUGIN_SEED_DIR' "$COMPOSE_YAML" \
        && grep -q 'CLAUDE_CODE_PLUGIN_SEED_DIR' "$DEVCONTAINER_JSON" \
        && grep -q 'CLAUDE_CODE_PLUGIN_SEED_DIR' "$REPO_ROOT/claude-sandbox"
}

@test "all launch methods set CLAUDE_CODE_PLUGIN_CACHE_DIR" {
    grep -q 'CLAUDE_CODE_PLUGIN_CACHE_DIR' "$COMPOSE_YAML" \
        && grep -q 'CLAUDE_CODE_PLUGIN_CACHE_DIR' "$DEVCONTAINER_JSON" \
        && grep -q 'CLAUDE_CODE_PLUGIN_CACHE_DIR' "$REPO_ROOT/claude-sandbox"
}

@test "all launch methods mount host plugins as a read-only seed" {
    grep -q '/opt/claude-seed:ro' "$COMPOSE_YAML" \
        && grep -q '/opt/claude-seed:ro' "$REPO_ROOT/claude-sandbox" \
        && grep '/opt/claude-seed' "$DEVCONTAINER_JSON" | grep -q 'readonly'
}

# --- devcontainer.json / compose.yaml parity ---

@test "devcontainer.json has SYS_NICE capability" {
    grep -q 'SYS_NICE' "$DEVCONTAINER_JSON"
}

@test "devcontainer.json has SYSLOG capability" {
    grep -q 'SYSLOG' "$DEVCONTAINER_JSON"
}

@test "devcontainer.json has privileged mode" {
    grep -q 'privileged' "$DEVCONTAINER_JSON"
}

# --- SSH key mount ---

@test "claude-sandbox mounts SSH key only if it exists" {
    grep -q '\[\[ -f ~/.ssh/id_rsa \]\]' "$REPO_ROOT/claude-sandbox"
}
