#!/bin/bash
# Pre-populate Claude's plugin registry from the read-only seed dir BEFORE Claude
# starts. Claude's built-in seed sync (CLAUDE_CODE_PLUGIN_SEED_DIR) runs too late in
# startup to install plugins on a fresh cache, so we register the seed marketplaces
# here first. Runs as node — no elevated permissions.
set -euo pipefail

SEED="${CLAUDE_CODE_PLUGIN_SEED_DIR:-}"
CACHE="${CLAUDE_CODE_PLUGIN_CACHE_DIR:-$HOME/.claude/plugins}"

if [ -n "$SEED" ] && [ -f "$SEED/known_marketplaces.json" ]; then
    mkdir -p "$CACHE"
    # The seed's installLocation paths come from another host; rewrite them to the
    # seed mount so first-run plugin loading resolves marketplaces immediately.
    sed "s#\"installLocation\": \"[^\"]*/marketplaces/#\"installLocation\": \"$SEED/marketplaces/#" \
        "$SEED/known_marketplaces.json" > "$CACHE/known_marketplaces.json"
fi
