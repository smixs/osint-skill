# Content Extraction Guide

When you find a content platform (YouTube, podcast, blog, conference talks) -
**extract everything immediately.** Don't just note the URL and move on.

## Principle

Content platforms are the richest source for psychoprofile and real personality.
LinkedIn is a resume. Instagram is a highlight reel. YouTube/podcasts are unfiltered.

A person talking for 20 minutes on camera reveals more than 100 LinkedIn posts.

## YouTube

### Discovery
```bash
# Search for channel
web_search "site:youtube.com <Name> <context>"
bash skills/osint/scripts/exa.sh search "<Name> youtube channel"
```

### Channel metadata
```bash
# Fetch channel page - subscriber count, video count, about
web_fetch "https://www.youtube.com/@<handle>"
# Or channel page
bash skills/osint/scripts/jina.sh read "https://www.youtube.com/@<handle>/about"
```

### Transcript extraction (CRITICAL)
Pick 3-5 most viewed or most recent videos. Extract transcripts:
```bash
# Fetch video page - title, description, comments
web_fetch "https://www.youtube.com/watch?v=<id>"
# Get auto-generated transcript via Jina
bash skills/osint/scripts/jina.sh read "https://www.youtube.com/watch?v=<id>"
```

If transcripts unavailable via fetch, try:
```bash
bash skills/osint/scripts/brightdata.sh scrape "https://www.youtube.com/watch?v=<id>"
```

### What to extract from YouTube:
- **Topics** - what they talk about = what they care about
- **Speaking style** - formal/casual, speed, filler words, humor
- **Vocabulary** - jargon level, code-switching between languages
- **Self-presentation** - humble/confident/arrogant, claims vs evidence
- **Recurring themes** - across videos, what keeps coming back
- **Guest interactions** - how they treat guests, who they invite
- **Comment section** - audience demographics, sentiment
- **Upload frequency** - consistency = discipline trait
- **Video titles** - clickbait vs informative = marketing approach
- **Playlists** - how they organize knowledge = thinking structure

### Budget: 3-5 video transcripts via Jina = ~$0.02-0.05

## Podcasts / Audio Appearances

Search for podcast appearances:
```bash
web_search "<Name> podcast interview"
bash skills/osint/scripts/exa.sh search "<Name> podcast episode guest"
```

Podcast interviews are gold - the host asks personal questions.
Look for: origin story, career pivots, failures mentioned, mentors named.

## Blog / Personal Website

```bash
web_fetch "<personal-site>"
bash skills/osint/scripts/jina.sh read "<blog-url>"
# Crawl multiple pages
bash skills/osint/scripts/exa.sh crawl "<blog-url>"
```

Extract: writing style, topics, frequency, tone evolution over time.

## Conference Talks / Speaker Bios

```bash
web_search "<Name> speaker conference talk"
web_search "site:youtube.com <Name> conference keynote"
```

Speaker bios at conferences are often more honest than LinkedIn -
written for specific audience, include unique details.

## Rule: Immediate Deep Extraction

When you discover ANY content platform during Phase 1-2:

1. **STOP** current task
2. **Extract** 3-5 pieces of content immediately
3. **Analyze** for psychoprofile signals
4. **Resume** original task with enriched data

Do NOT bookmark for later. Later = never.
The insight from 3 YouTube transcripts outweighs 10 LinkedIn connections.
