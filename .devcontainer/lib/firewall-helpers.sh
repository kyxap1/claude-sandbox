#!/bin/bash
# Sourced by init-firewall.sh — do not execute directly.

parse_domains_conf() {
    local conf_path="$1"
    if [ ! -f "$conf_path" ]; then
        echo "ERROR: Domain config not found at $conf_path" >&2
        return 1
    fi

    while IFS= read -r line; do
        line=$(echo "$line" | sed 's/#.*//' | xargs)
        [ -z "$line" ] && continue
        echo "$line"
    done < "$conf_path"
}

validate_ipv4() {
    local ip="$1"
    [[ "$ip" =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]] || return 1

    local IFS='.'
    read -ra octets <<< "$ip"
    for octet in "${octets[@]}"; do
        (( octet > 255 )) && return 1
    done
    return 0
}

validate_cidr() {
    local cidr="$1"
    [[ "$cidr" =~ ^([0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3})/([0-9]{1,2})$ ]] || return 1

    local ip="${BASH_REMATCH[1]}"
    local mask="${BASH_REMATCH[2]}"

    validate_ipv4 "$ip" || return 1
    (( mask > 32 )) && return 1
    return 0
}
