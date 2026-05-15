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

@test ".env: every variable has a matching ARG in Dockerfile" {
    while IFS='=' read -r key _; do
        [[ -z "$key" || "$key" =~ ^# ]] && continue
        run grep -q "^ARG ${key}=" "$DOCKERFILE"
        [ "$status" -eq 0 ] || fail ".env has $key but Dockerfile has no ARG $key with default"
    done < "$DOTENV"
}

@test ".env: every variable is referenced in compose.yaml build args" {
    while IFS='=' read -r key _; do
        [[ -z "$key" || "$key" =~ ^# ]] && continue
        run grep -q "${key}:" "$COMPOSE_YAML"
        [ "$status" -eq 0 ] || fail ".env has $key but compose.yaml build args does not list it"
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
    grep -q 'COPY allowed-domains.conf /etc/allowed-domains.conf' "$DOCKERFILE"
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
