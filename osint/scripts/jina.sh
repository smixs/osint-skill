#!/bin/bash
# Jina AI wrapper for OSINT skill
# Requires: JINA_API_KEY env var (or scripts/jina-api-key.txt in workspace)
# Usage: ./jina.sh <action> <arg>

set -euo pipefail

SKILL_DIR="$(cd "$(dirname "$0")/.." && pwd)"
WORKSPACE="$(cd "$SKILL_DIR/../.." && pwd)"

# Load key from file if env not set
if [ -z "${JINA_API_KEY:-}" ] && [ -f "$WORKSPACE/scripts/jina-api-key.txt" ]; then
  JINA_API_KEY=$(head -1 "$WORKSPACE/scripts/jina-api-key.txt")
fi

TOKEN="${JINA_API_KEY:?ERROR: JINA_API_KEY not set. Get one at https://jina.ai/api-key}"

case "${1:-help}" in
  read)
    # URL → clean markdown
    URL="$2"
    curl -s "https://r.jina.ai/$URL" \
      -H "Authorization: Bearer $TOKEN" \
      -H "Accept: application/json"
    ;;
  search)
    # Query → markdown results (10 pages)
    QUERY="${*:2}"
    curl -s "https://s.jina.ai/$QUERY" \
      -H "Authorization: Bearer $TOKEN" \
      -H "Accept: application/json"
    ;;
  deepsearch)
    # Deep research with reasoning
    QUERY="${*:2}"
    curl -s "https://deepsearch.jina.ai" \
      -H "Authorization: Bearer $TOKEN" \
      -H "Content-Type: application/json" \
      -H "Accept: application/json" \
      -d "{\"query\":\"$QUERY\"}"
    ;;
  *)
    echo "Usage: jina.sh {read|search|deepsearch} <arg>"
    echo ""
    echo "  read <url>       - any URL → clean markdown"
    echo "  search <query>   - web search → markdown (10 results)"
    echo "  deepsearch <q>   - deep research with AI reasoning"
    echo ""
    echo "Env: JINA_API_KEY (or scripts/jina-api-key.txt)"
    ;;
esac
