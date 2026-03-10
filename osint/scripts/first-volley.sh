#!/bin/bash
# OSINT First Volley - parallel search across all engines
# Launches all search tools simultaneously for maximum coverage
# Usage: ./first-volley.sh "Full Name" ["context keywords"]
#
# Requires: JINA_API_KEY, PARALLEL_API_KEY (optional: BRIGHTDATA_MCP_URL)
# Results saved to /tmp/osint-volley-<timestamp>/

set -euo pipefail

NAME="${1:?Usage: first-volley.sh \"Full Name\" [\"context\"]}"
CONTEXT="${2:-}"
QUERY="$NAME $CONTEXT"
TIMESTAMP=$(date +%s)
OUTDIR="/tmp/osint-$TIMESTAMP"
mkdir -p "$OUTDIR"

SKILL_DIR="$(cd "$(dirname "$0")/.." && pwd)"
WORKSPACE="$(cd "$SKILL_DIR/../.." && pwd)"

# Load keys from files if env not set
[ -z "${JINA_API_KEY:-}" ] && [ -f "$WORKSPACE/scripts/jina-api-key.txt" ] && export JINA_API_KEY=$(head -1 "$WORKSPACE/scripts/jina-api-key.txt")
[ -z "${PARALLEL_API_KEY:-}" ] && [ -f "$WORKSPACE/scripts/parallel-api-key.txt" ] && export PARALLEL_API_KEY=$(head -1 "$WORKSPACE/scripts/parallel-api-key.txt")
[ -z "${BRIGHTDATA_MCP_URL:-}" ] && [ -f "$WORKSPACE/scripts/brightdata-mcp-url.txt" ] && export BRIGHTDATA_MCP_URL=$(head -1 "$WORKSPACE/scripts/brightdata-mcp-url.txt")

echo "🔍 First Volley: $QUERY"
echo "   Output: $OUTDIR/"
echo ""

PIDS=()

# Launch all searches in parallel with staggered starts
echo "Launching parallel searches..."

# Jina search - general
if [ -n "${JINA_API_KEY:-}" ]; then
  bash "$SKILL_DIR/scripts/jina.sh" search "$QUERY" > "$OUTDIR/jina-general.json" 2>/dev/null &
  PIDS+=($!)
  echo "  → Jina general search (PID $!)"
  sleep 0.5
fi

# Parallel AI search - general
if [ -n "${PARALLEL_API_KEY:-}" ]; then
  bash "$SKILL_DIR/scripts/parallel.sh" search "$QUERY" > "$OUTDIR/parallel-general.json" 2>/dev/null &
  PIDS+=($!)
  echo "  → Parallel AI general search (PID $!)"
  sleep 0.5
fi

# Jina search - social media specific
if [ -n "${JINA_API_KEY:-}" ]; then
  bash "$SKILL_DIR/scripts/jina.sh" search "$NAME instagram linkedin facebook telegram" > "$OUTDIR/jina-social.json" 2>/dev/null &
  PIDS+=($!)
  echo "  → Jina social search (PID $!)"
  sleep 0.5
fi

# Parallel AI - social media specific
if [ -n "${PARALLEL_API_KEY:-}" ]; then
  bash "$SKILL_DIR/scripts/parallel.sh" search "$NAME instagram linkedin telegram facebook profile" > "$OUTDIR/parallel-social.json" 2>/dev/null &
  PIDS+=($!)
  echo "  → Parallel social search (PID $!)"
  sleep 0.5
fi

# Bright Data Yandex (good for CIS targets)
if [ -n "${BRIGHTDATA_MCP_URL:-}" ] && command -v mcporter &>/dev/null; then
  bash "$SKILL_DIR/scripts/brightdata.sh" search-yandex "$QUERY" > "$OUTDIR/yandex.json" 2>/dev/null &
  PIDS+=($!)
  echo "  → Yandex search (PID $!)"
fi

echo ""
echo "Waiting for ${#PIDS[@]} searches..."

# Wait with timeout (60s max)
for pid in "${PIDS[@]}"; do
  timeout 60 tail --pid="$pid" -f /dev/null 2>/dev/null || true
done
wait 2>/dev/null || true

echo ""
echo "✅ All searches complete. Results in $OUTDIR/"
ls -lh "$OUTDIR/" 2>/dev/null | grep -v "^total"
echo ""
echo "Run: bash $SKILL_DIR/scripts/merge-volley.sh $OUTDIR"
