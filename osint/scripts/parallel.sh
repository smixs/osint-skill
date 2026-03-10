#!/bin/bash
# Parallel AI wrapper for OSINT skill
# Requires: PARALLEL_API_KEY env var
# Usage: ./parallel.sh <action> <arg>
#
# API docs: https://docs.parallel.ai
# Products: Search API, Extract API, Task API, Chat API, FindAll API, Monitor API

set -euo pipefail

SKILL_DIR="$(cd "$(dirname "$0")/.." && pwd)"
WORKSPACE="$(cd "$SKILL_DIR/../.." && pwd)"
[ -z "${PARALLEL_API_KEY:-}" ] && [ -f "$WORKSPACE/scripts/parallel-api-key.txt" ] && export PARALLEL_API_KEY=$(head -1 "$WORKSPACE/scripts/parallel-api-key.txt")

TOKEN="${PARALLEL_API_KEY:?ERROR: PARALLEL_API_KEY not set. Get one at https://platform.parallel.ai}"
BASE="https://api.parallel.ai/v1beta"
BETA_HEADER="parallel-beta: search-extract-2025-10-10"

case "${1:-help}" in
  search)
    QUERY="${*:2}"
    curl -s "$BASE/search" \
      -H "Content-Type: application/json" \
      -H "x-api-key: $TOKEN" \
      -H "$BETA_HEADER" \
      -d "{
        \"objective\": \"$QUERY\",
        \"search_queries\": [\"$QUERY\"],
        \"max_results\": 10,
        \"excerpts\": {\"max_chars_per_result\": 5000}
      }"
    ;;
  extract)
    URL="$2"
    curl -s "$BASE/extract" \
      -H "Content-Type: application/json" \
      -H "x-api-key: $TOKEN" \
      -H "$BETA_HEADER" \
      -d "{\"url\": \"$URL\", \"full_content\": true}"
    ;;
  task)
    # Complex research task
    TASK="${*:2}"
    curl -s "$BASE/task" \
      -H "Content-Type: application/json" \
      -H "x-api-key: $TOKEN" \
      -d "{\"task\": \"$TASK\"}"
    ;;
  *)
    echo "Usage: parallel.sh {search|extract|task} <arg>"
    echo ""
    echo "  search <query>   - AI-powered web search with LLM-optimized excerpts"
    echo "  extract <url>    - URL → clean markdown (JS-heavy, PDF)"
    echo "  task <task>       - Complex research task with structured output"
    echo ""
    echo "Env: PARALLEL_API_KEY (required)"
    echo "Docs: https://docs.parallel.ai"
    ;;
esac
