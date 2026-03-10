#!/bin/bash
# Universal Apify Actor Runner — bash wrapper for run_actor.js
# Handles env loading consistently with other OSINT scripts.
#
# Usage: run-actor.sh <actor_id> <json_input> [--output file] [--format csv|json]
#
# Examples:
#   run-actor.sh "apify/instagram-profile-scraper" '{"usernames":["handle"]}'
#   run-actor.sh "compass/crawler-google-places" '{"searchStringsArray":["cafes"]}' --output /tmp/cafes.csv
#
# Env: APIFY_API_TOKEN or APIFY_TOKEN (either works)

set -euo pipefail

SKILL_DIR="$(cd "$(dirname "$0")/.." && pwd)"
WORKSPACE="$(cd "$SKILL_DIR/../.." && pwd)"

# Load token from env or file (consistent with apify.sh)
if [ -z "${APIFY_API_TOKEN:-}" ] && [ -z "${APIFY_TOKEN:-}" ]; then
  if [ -f "$WORKSPACE/scripts/apify-api-token.txt" ]; then
    export APIFY_API_TOKEN=$(head -1 "$WORKSPACE/scripts/apify-api-token.txt")
  fi
fi
# Ensure at least one is set; run_actor.js accepts both
export APIFY_TOKEN="${APIFY_TOKEN:-${APIFY_API_TOKEN:-}}"

if [ -z "$APIFY_TOKEN" ]; then
  echo "ERROR: No Apify token found." >&2
  echo "Set APIFY_API_TOKEN or APIFY_TOKEN env var," >&2
  echo "or put token in $WORKSPACE/scripts/apify-api-token.txt" >&2
  echo "Get one at: https://console.apify.com/account/integrations" >&2
  exit 1
fi

ACTOR="${1:?Usage: run-actor.sh <actor_id> <json_input> [--output file] [--format csv|json]}"
INPUT="${2:?Missing JSON input}"
shift 2

# Check Node.js version (need 18+ for global fetch)
NODE_VERSION=$(node -v 2>/dev/null | sed 's/v//' | cut -d. -f1)
if [ -z "$NODE_VERSION" ] || [ "$NODE_VERSION" -lt 18 ]; then
  echo "ERROR: Node.js 18+ required (found: $(node -v 2>/dev/null || echo 'none'))" >&2
  exit 1
fi

exec node "$SKILL_DIR/scripts/run_actor.js" \
  --actor "$ACTOR" \
  --input "$INPUT" \
  "$@"
