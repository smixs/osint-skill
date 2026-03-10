#!/bin/bash
# Merge and deduplicate first-volley results
# Usage: ./merge-volley.sh /tmp/osint-<timestamp>
#
# Extracts URLs and titles from all result files, deduplicates, groups by platform.

set -euo pipefail

OUTDIR="${1:?Usage: merge-volley.sh /tmp/osint-<timestamp>}"

if [ ! -d "$OUTDIR" ]; then
  echo "Error: $OUTDIR not found"
  exit 1
fi

echo "=== MERGE: $OUTDIR ==="
echo ""

# Extract all URLs from JSON results
ALL_URLS=$(cat "$OUTDIR"/*.json 2>/dev/null | grep -oE 'https?://[^"]+' | sort -u)

if [ -z "$ALL_URLS" ]; then
  echo "⚠️  No URLs found in results. Check raw files:"
  ls -la "$OUTDIR/"
  exit 0
fi

TOTAL=$(echo "$ALL_URLS" | wc -l)
echo "📊 Total unique URLs: $TOTAL"
echo ""

# Group by platform
echo "🔗 LinkedIn:"
echo "$ALL_URLS" | grep -i "linkedin.com" | head -10 || echo "  (none)"
echo ""

echo "📸 Instagram:"
echo "$ALL_URLS" | grep -i "instagram.com" | head -10 || echo "  (none)"
echo ""

echo "📘 Facebook:"
echo "$ALL_URLS" | grep -i "facebook.com" | head -10 || echo "  (none)"
echo ""

echo "✈️ Telegram:"
echo "$ALL_URLS" | grep -i "t.me" | head -10 || echo "  (none)"
echo ""

echo "🐦 Twitter/X:"
echo "$ALL_URLS" | grep -iE "(twitter.com|x.com)" | head -10 || echo "  (none)"
echo ""

echo "📺 VK:"
echo "$ALL_URLS" | grep -i "vk.com" | head -10 || echo "  (none)"
echo ""

echo "📰 Media/Other:"
echo "$ALL_URLS" | grep -viE "(linkedin|instagram|facebook|t\.me|twitter|x\.com|vk\.com)" | head -20 || echo "  (none)"
echo ""

# Save merged output
echo "$ALL_URLS" > "$OUTDIR/merged-urls.txt"
echo "✅ Saved to $OUTDIR/merged-urls.txt"
echo "=== END MERGE ==="
