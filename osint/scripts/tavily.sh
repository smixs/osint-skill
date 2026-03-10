#!/bin/bash
# Tavily — AI-optimized search for agents
# Usage: tavily.sh search "query"           # fast search ($0.005)
#        tavily.sh extract "url"            # extract content from URL
#        tavily.sh deep "query"             # deep search (comprehensive)
set -euo pipefail

API_KEY="${TAVILY_API_KEY:?Set TAVILY_API_KEY — https://app.tavily.com/home}"
CMD="${1:?Usage: tavily.sh search|extract|deep <query>}"
QUERY="${2:?Missing query}"

case "$CMD" in
  search)
    curl -s "https://api.tavily.com/search" \
      -H "Content-Type: application/json" \
      -d "{
        \"api_key\": \"$API_KEY\",
        \"query\": \"$QUERY\",
        \"search_depth\": \"basic\",
        \"max_results\": 10,
        \"include_answer\": true
      }" | python3 -c "
import json, sys
d = json.load(sys.stdin)
if 'answer' in d and d['answer']:
    print(f'💡 {d[\"answer\"]}\n')
for r in d.get('results', [])[:10]:
    print(f'🔗 {r.get(\"title\",\"\")}')
    print(f'   {r.get(\"url\",\"\")}')
    print(f'   {r.get(\"content\",\"\")[:200]}')
    score = r.get('score','')
    if score: print(f'   relevance: {score:.2f}')
    print()
"
    ;;
  deep)
    curl -s "https://api.tavily.com/search" \
      -H "Content-Type: application/json" \
      -d "{
        \"api_key\": \"$API_KEY\",
        \"query\": \"$QUERY\",
        \"search_depth\": \"advanced\",
        \"max_results\": 10,
        \"include_answer\": true,
        \"include_raw_content\": false
      }" | python3 -c "
import json, sys
d = json.load(sys.stdin)
if 'answer' in d and d['answer']:
    print(f'💡 {d[\"answer\"]}\n')
for r in d.get('results', [])[:10]:
    print(f'🔗 {r.get(\"title\",\"\")}')
    print(f'   {r.get(\"url\",\"\")}')
    print(f'   {r.get(\"content\",\"\")[:300]}')
    score = r.get('score','')
    if score: print(f'   relevance: {score:.2f}')
    print()
"
    ;;
  extract)
    curl -s "https://api.tavily.com/extract" \
      -H "Content-Type: application/json" \
      -d "{
        \"api_key\": \"$API_KEY\",
        \"urls\": [\"$QUERY\"]
      }" | python3 -c "
import json, sys
d = json.load(sys.stdin)
for r in d.get('results', []):
    print(f'📄 {r.get(\"url\",\"\")}')
    print(r.get('raw_content', r.get('content',''))[:3000])
"
    ;;
  *)
    echo "Unknown: $CMD (use search|extract|deep)" >&2; exit 1
    ;;
esac
