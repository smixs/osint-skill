#!/bin/bash
# Bright Data MCP wrapper for OSINT skill
# Requires: BRIGHTDATA_MCP_URL env var (full MCP endpoint with token)
# Usage: ./brightdata.sh <action> <arg>
#
# Uses lightweight Python MCP client (Streamable HTTP/SSE transport)

set -euo pipefail

SKILL_DIR="$(cd "$(dirname "$0")/.." && pwd)"
WORKSPACE="$(cd "$SKILL_DIR/../.." && pwd)"
[ -z "${BRIGHTDATA_MCP_URL:-}" ] && [ -f "$WORKSPACE/scripts/brightdata-mcp-url.txt" ] && export BRIGHTDATA_MCP_URL=$(head -1 "$WORKSPACE/scripts/brightdata-mcp-url.txt")

MCP_URL="${BRIGHTDATA_MCP_URL:?ERROR: BRIGHTDATA_MCP_URL not set. Get MCP endpoint at https://brightdata.com/products/web-scraper/mcp}"

SKILL_DIR="$(cd "$(dirname "$0")/.." && pwd)"

# Python MCP client function
mcp_call() {
  local TOOL="$1"
  local ARGS="$2"
  python3 "$SKILL_DIR/scripts/mcp-client.py" "$MCP_URL" "$TOOL" "$ARGS"
}

case "${1:-help}" in
  tools)
    python3 "$SKILL_DIR/scripts/mcp-client.py" "$MCP_URL" --list-tools
    ;;
  scrape)
    URL="$2"
    mcp_call "scrape_as_markdown" "{\"url\":\"$URL\"}"
    ;;
  scrape-batch)
    shift
    URLS_JSON=$(printf '"%s",' "$@" | sed 's/,$//')
    mcp_call "scrape_as_markdown_batch" "{\"urls\":[$URLS_JSON]}"
    ;;
  search)
    QUERY="${*:2}"
    mcp_call "web_data_search_engine" "{\"query\":\"$QUERY\"}"
    ;;
  search-geo)
    GEO="$2"
    QUERY="${*:3}"
    mcp_call "web_data_search_engine" "{\"query\":\"$QUERY\",\"country\":\"$GEO\"}"
    ;;
  search-yandex)
    QUERY="${*:2}"
    mcp_call "web_data_search_engine" "{\"query\":\"$QUERY\",\"engine\":\"yandex\"}"
    ;;
  *)
    echo "Usage: brightdata.sh {tools|scrape|scrape-batch|search|search-geo|search-yandex} <args>"
    echo ""
    echo "  tools                     - list available MCP tools"
    echo "  scrape <url>              - any URL → markdown (bypasses CAPTCHA/authwall)"
    echo "  scrape-batch <url1> <url2> - batch scrape up to 10 URLs"
    echo "  search <query>            - Google search via Bright Data"
    echo "  search-geo <cc> <query>   - geo-targeted search (e.g., search-geo ru \"query\")"
    echo "  search-yandex <query>     - Yandex search"
    echo ""
    echo "Env: BRIGHTDATA_MCP_URL (required)"
    ;;
esac
