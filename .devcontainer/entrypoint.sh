#!/bin/bash
set -euo pipefail

sudo /usr/local/bin/init-firewall.sh

if [ -t 0 ]; then
    exec claude --continue
else
    exec sleep infinity
fi
