#!/usr/bin/env bats

setup() {
    source "$BATS_TEST_DIRNAME/../.devcontainer/lib/firewall-helpers.sh"
    TEST_TMPDIR=$(mktemp -d)
}

teardown() {
    rm -rf "$TEST_TMPDIR"
}

# --- parse_domains_conf ---

@test "parse_domains_conf: returns domains from valid config" {
    cat > "$TEST_TMPDIR/domains.conf" <<'EOF'
api.anthropic.com
registry.npmjs.org
EOF
    run parse_domains_conf "$TEST_TMPDIR/domains.conf"
    [ "$status" -eq 0 ]
    [ "${lines[0]}" = "api.anthropic.com" ]
    [ "${lines[1]}" = "registry.npmjs.org" ]
    [ "${#lines[@]}" -eq 2 ]
}

@test "parse_domains_conf: strips comments and blank lines" {
    cat > "$TEST_TMPDIR/domains.conf" <<'EOF'
# This is a comment
api.anthropic.com

# Another comment

registry.npmjs.org
EOF
    run parse_domains_conf "$TEST_TMPDIR/domains.conf"
    [ "$status" -eq 0 ]
    [ "${lines[0]}" = "api.anthropic.com" ]
    [ "${lines[1]}" = "registry.npmjs.org" ]
    [ "${#lines[@]}" -eq 2 ]
}

@test "parse_domains_conf: strips inline comments" {
    cat > "$TEST_TMPDIR/domains.conf" <<'EOF'
api.anthropic.com # Claude API
EOF
    run parse_domains_conf "$TEST_TMPDIR/domains.conf"
    [ "$status" -eq 0 ]
    [ "${lines[0]}" = "api.anthropic.com" ]
    [ "${#lines[@]}" -eq 1 ]
}

@test "parse_domains_conf: fails on nonexistent file" {
    run parse_domains_conf "$TEST_TMPDIR/nonexistent.conf"
    [ "$status" -eq 1 ]
    [[ "$output" == *"ERROR"* ]]
}

@test "parse_domains_conf: returns empty on file with only comments" {
    cat > "$TEST_TMPDIR/domains.conf" <<'EOF'
# Only comments
# Nothing else
EOF
    run parse_domains_conf "$TEST_TMPDIR/domains.conf"
    [ "$status" -eq 0 ]
    [ -z "$output" ]
}

# --- validate_ipv4 ---

@test "validate_ipv4: accepts valid IP" {
    run validate_ipv4 "1.2.3.4"
    [ "$status" -eq 0 ]
}

@test "validate_ipv4: accepts 0.0.0.0" {
    run validate_ipv4 "0.0.0.0"
    [ "$status" -eq 0 ]
}

@test "validate_ipv4: accepts 255.255.255.255" {
    run validate_ipv4 "255.255.255.255"
    [ "$status" -eq 0 ]
}

@test "validate_ipv4: rejects octet > 255" {
    run validate_ipv4 "999.1.1.1"
    [ "$status" -eq 1 ]
}

@test "validate_ipv4: rejects non-IP string" {
    run validate_ipv4 "not-an-ip"
    [ "$status" -eq 1 ]
}

@test "validate_ipv4: rejects empty string" {
    run validate_ipv4 ""
    [ "$status" -eq 1 ]
}

@test "validate_ipv4: rejects IP with CIDR suffix" {
    run validate_ipv4 "10.0.0.0/8"
    [ "$status" -eq 1 ]
}

# --- validate_cidr ---

@test "validate_cidr: accepts valid CIDR" {
    run validate_cidr "10.0.0.0/8"
    [ "$status" -eq 0 ]
}

@test "validate_cidr: accepts /32 single host" {
    run validate_cidr "1.2.3.4/32"
    [ "$status" -eq 0 ]
}

@test "validate_cidr: accepts /0 default route" {
    run validate_cidr "0.0.0.0/0"
    [ "$status" -eq 0 ]
}

@test "validate_cidr: rejects bare IP without mask" {
    run validate_cidr "1.2.3.4"
    [ "$status" -eq 1 ]
}

@test "validate_cidr: rejects mask > 32" {
    run validate_cidr "10.0.0.0/33"
    [ "$status" -eq 1 ]
}

@test "validate_cidr: rejects invalid IP in CIDR" {
    run validate_cidr "999.0.0.0/8"
    [ "$status" -eq 1 ]
}

@test "validate_cidr: rejects empty string" {
    run validate_cidr ""
    [ "$status" -eq 1 ]
}
