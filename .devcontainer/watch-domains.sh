#!/bin/sh
set -eu

WATCH_DIR="/workspace/.claude"
TARGET_FILE="allowed-domains.extra.conf"

mkdir -p "$WATCH_DIR"

echo "Watching $WATCH_DIR/$TARGET_FILE for changes..."

inotifywait -m -e close_write,moved_to --format '%f' "$WATCH_DIR" |
while read -r MODIFIED_FILE
do
    if [ "$MODIFIED_FILE" = "$TARGET_FILE" ]; then
        echo "$TARGET_FILE changed. Reloading firewall..."
        sudo /usr/local/bin/init-firewall.sh >&2
    fi
done
