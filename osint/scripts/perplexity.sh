#!/bin/bash
# Perplexity API — search + sonar + deep research
# Usage: perplexity.sh search "query"       # Search API (ranked results)
#        perplexity.sh sonar "query"        # Sonar (AI answer + citations)
#        perplexity.sh deep "query"         # Deep Research
set -euo pipefail

API_KEY="${PERPLEXITY_API_KEY:?Set PERPLEXITY_API_KEY}"
CMD="${1:?Usage: perplexity.sh search|sonar|deep <query>}"
QUERY="${2:?Missing query}"

case "$CMD" in
  search)
    # Search API — ranked web results
    curl -s "https://api.perplexity.ai/search" \
      -H "Authorization: Bearer $API_KEY" \
      -H "Content-Type: application/json" \
      -d "{\"query\": [\"$QUERY\"]}" | python3 -c "
import json, sys
d = json.load(sys.stdin)
if 'results' in d:
    for r in d['results'][:10]:
        print(f'🔗 {r.get(\"title\",\"\")}')
        print(f'   {r.get(\"url\",\"\")}')
        print(f'   {r.get(\"snippet\",\"\")[:200]}')
        print()
elif 'error' in d:
    print(f'ERROR: {json.dumps(d[\"error\"])}', file=sys.stderr)
else:
    print(json.dumps(d, indent=2)[:2000])
"
    ;;
  sonar)
    # Sonar API — AI answer with citations
    curl -s "https://api.perplexity.ai/chat/completions" \
      -H "Authorization: Bearer $API_KEY" \
      -H "Content-Type: application/json" \
      -d "{
        \"model\": \"sonar\",
        \"messages\": [{\"role\": \"user\", \"content\": \"$QUERY\"}]
      }" | python3 -c "
import json, sys
d = json.load(sys.stdin)
if 'choices' in d:
    msg = d['choices'][0]['message']
    print(msg.get('content', ''))
    cits = d.get('citations', msg.get('citations', []))
    if cits:
        print('\n--- Sources ---')
        for i, c in enumerate(cits[:10], 1):
            print(f'{i}. {c if isinstance(c, str) else c.get(\"url\", c)}')
elif 'error' in d:
    print(f'ERROR: {json.dumps(d[\"error\"])}', file=sys.stderr)
else:
    print(json.dumps(d, indent=2)[:2000])
"
    ;;
  deep)
    # Deep Research via sonar-deep-research
    curl -s "https://api.perplexity.ai/chat/completions" \
      -H "Authorization: Bearer $API_KEY" \
      -H "Content-Type: application/json" \
      -d "{
        \"model\": \"sonar-deep-research\",
        \"messages\": [{\"role\": \"user\", \"content\": \"$QUERY\"}]
      }" | python3 -c "
import json, sys
d = json.load(sys.stdin)
if 'choices' in d:
    msg = d['choices'][0]['message']
    print(msg.get('content', ''))
    cits = d.get('citations', msg.get('citations', []))
    if cits:
        print('\n--- Sources ---')
        for i, c in enumerate(cits[:15], 1):
            print(f'{i}. {c if isinstance(c, str) else c.get(\"url\", c)}')
elif 'error' in d:
    print(f'ERROR: {json.dumps(d[\"error\"])}', file=sys.stderr)
else:
    print(json.dumps(d, indent=2)[:2000])
"
    ;;
  *)
    echo "Unknown command: $CMD (use search|sonar|deep)" >&2; exit 1
    ;;
esac
