#!/bin/bash
set -euo pipefail

sudo /usr/local/bin/init-firewall.sh >&2

if [ -t 0 ]; then
    exec claude --dangerously-skip-permissions "$@"
else
    exec sleep infinity
fi
