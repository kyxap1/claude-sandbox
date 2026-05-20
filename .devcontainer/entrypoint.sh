#!/bin/bash
set -euo pipefail

if [[ "${SANDBOX_FIREWALL:-true}" == "true" ]]; then
    sudo /usr/local/bin/init-firewall.sh >&2
    /usr/local/bin/watch-domains.sh &
fi

if [ -t 0 ]; then
    exec claude --dangerously-skip-permissions "$@"
else
    exec sleep infinity
fi
