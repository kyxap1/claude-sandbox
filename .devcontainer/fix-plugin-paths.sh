#!/bin/bash
# Rewrite host-specific paths in Claude plugin configs to match the container.
# Runs on every container start — idempotent, no-op if paths already correct.

CLAUDE_DIR="$HOME/.claude"

for json in "$CLAUDE_DIR/plugins/known_marketplaces.json" "$CLAUDE_DIR/plugins/installed_plugins.json"; do
    [ -f "$json" ] || continue
    host_prefix=$(grep -oP '"(\/[^"]+)\/plugins\/(cache|marketplaces)\/' "$json" | head -1 | sed 's|/plugins/.*||')
    [ -n "$host_prefix" ] && [ "$host_prefix" != "$CLAUDE_DIR" ] && sed -i "s|$host_prefix|$CLAUDE_DIR|g" "$json"
done
