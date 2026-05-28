#!/bin/bash
set -euo pipefail

if [[ "${FIREWALL:-true}" == "true" ]]; then
    sudo /usr/local/bin/init-firewall.sh >&2
    sudo /usr/sbin/ulogd -c /etc/ulogd-blocked.conf &
    /usr/local/bin/watch-domains.sh &
fi

/usr/local/bin/seed-plugins.sh

if [ -t 0 ]; then
    exec claude --dangerously-skip-permissions "$@"
else
    exec sleep infinity
fi
