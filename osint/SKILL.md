---
name: osint
description: >
  Conduct deep OSINT research on individuals. Build full digital footprint, psychoprofile
  (MBTI/Big Five), career history, social graph with confidence scores. Recursive
  self-evaluation until completeness threshold is met. Includes internal intelligence
  (Telegram history, email, vault contacts) before going external.
  Use when: "osint", "досье", "research person", "find everything about", "пробей",
  "разведка", "due diligence", "background check", "digital footprint",
  "найди всё про", "собери информацию", "кто это", "профиль человека".
  NOT for: company/product research without a named person, competitive analysis,
  market research, content generation, or general web scraping tasks.
---

# OSINT Skill v3.2

Systematic intelligence gathering on individuals. From a name or handle to a scored
dossier with psychoprofile, career map, and entry points.

## Phase Router

Determine entry point from context:

- New name/handle/URL, "пробей", "find out about" → Phase 0 (full cycle)
- "Add LinkedIn/Instagram data" to existing dossier → Phase 2 (extraction)
- "Build psychoprofile" from existing data → Phase 4
- "Rate completeness" of existing dossier → Phase 5
- "Reformat" or "present" findings → Phase 6

Default (full research request): Phase 0 → 1 → 1.5 → 2 → 3 → 4 → 5 → 6.

## Environment

All API keys via environment variables. Never hardcode tokens.

- `PERPLEXITY_API_KEY` — Perplexity Sonar (fast answers + deep research)
- `EXA_API_KEY` — Exa AI (semantic search, company/people research, deep research)
- `TAVILY_API_KEY` — Tavily (agent-optimized search + extract, $0.005/req basic)
- `APIFY_API_TOKEN` — Apify scraping (LinkedIn, Instagram, Facebook)
- `JINA_API_KEY` — Jina reader/search/deepsearch
- `PARALLEL_API_KEY` — Parallel AI search
- `BRIGHTDATA_MCP_URL` — Bright Data MCP endpoint (full URL with token)
- `MCPORTER_CONFIG` — mcporter config path

## Scripts

Run from skill dir: `bash scripts/<name>.sh`.
Each validates env vars, exits with descriptive error + URL to get the key.

**Search & Research:**
- `diagnose.sh` — run FIRST. Capability map of all tools.
- `perplexity.sh` — `search <query>` | `sonar <query>` (AI answer) | `deep <query>` (deep research)
- `tavily.sh` — `search <query>` (basic $0.005) | `deep <query>` (advanced) | `extract <url>`
- `exa.sh` — `search <query>` | `company <name>` | `people <name>` | `crawl <url>` | `deep <prompt>`
- `first-volley.sh "Name" "context"` — parallel search, all engines at once.
- `merge-volley.sh <outdir>` — deduplicate and merge first-volley results.

**Scraping:**
- `apify.sh` — `linkedin <url>` | `instagram <handle>` | `run` | `results` | `store-search`
- `run-actor.sh` — **universal Apify runner (55+ actors).** Embedded from [apify/agent-skills](https://github.com/apify/agent-skills).
  Quick answer: `bash scripts/run-actor.sh "actor/id" '{"input":"json"}'`
  Export: `bash scripts/run-actor.sh "actor/id" '{"input":"json"}' --output /tmp/out.csv`
- `jina.sh` — `read <url>` | `search <query>` | `deepsearch <query>`
- `parallel.sh` — `search <query>` | `extract <url>`
- `brightdata.sh` — `scrape <url>` | `scrape-batch` | `search` | `search-geo <cc>` | `search-yandex`

## Research Escalation Flow

**Принцип: от дешёвого к дорогому, от быстрого к глубокому.**

### Level 1: Quick Answers (секунды, ~$0.00)
Начни ВСЕГДА с этого. Получи быстрый контекст прежде чем копать.
Запускай ВСЕ параллельно:
```bash
# Perplexity Sonar — AI ответ с цитатами
bash skills/osint/scripts/perplexity.sh sonar "Who is <Name>, <context>"
# Brave Search — классический поиск
web_search "<Name> <company> <role>"
# Tavily — agent-optimized search с AI answer
bash skills/osint/scripts/tavily.sh search "<Name> <context>"
# Exa — семантический поиск + company/people research
bash skills/osint/scripts/exa.sh search "<Name> <context>"
bash skills/osint/scripts/exa.sh people "<Name>"
```
→ Получаешь: быстрые факты, ссылки, контекст.
→ Решение: достаточно? → Phase 6. Нужно больше? → Level 2.

### Level 2: Source Verification (секунды-минуты, ~$0.01)
Проверяй источники из Level 1 через fetch:
```bash
# Читай найденные URL
web_fetch "<url_from_perplexity>"
bash skills/osint/scripts/jina.sh read "<url>"
bash skills/osint/scripts/parallel.sh extract "<url>"
```
→ Получаешь: подтверждённые факты, cross-reference.
→ Совпадает? → дополняй досье. Нужно глубже? → Level 3.

### Level 3: Social Media Deep Dive (~$0.01-0.10)
Подключай scraping для соцсетей:
```bash
# LinkedIn
bash skills/osint/scripts/apify.sh linkedin "<url>"
# Instagram
bash skills/osint/scripts/apify.sh instagram "<handle>"
# Facebook, заблокированные сайты
bash skills/osint/scripts/brightdata.sh scrape "<url>"
```
→ Получаешь: структурированные профили, фото, связи.

### Level 4: Deep Research (~$0.05-0.50)
Если нужно копать ещё глубже — формируй развёрнутый промпт и отправляй в deep research.
Запускай ВСЕ параллельно (30-60 сек каждый):
```bash
# Perplexity Deep Research
bash skills/osint/scripts/perplexity.sh deep "<detailed research prompt about Name>"
# Exa Deep Research
bash skills/osint/scripts/exa.sh deep "<detailed prompt>"
# Parallel AI Deep Search
bash skills/osint/scripts/parallel.sh search "<detailed query>"
# Jina DeepSearch
bash skills/osint/scripts/jina.sh deepsearch "<query>"
```

**Правило:** Level 4 промпт должен быть РАЗВЁРНУТЫМ — включай всё что уже знаешь
из Level 1-3, чтобы deep research не повторял базовые факты, а копал дальше.

## Swarm Mode (DEFAULT)

OSINT research runs as a **swarm of parallel sub-agents on Sonnet**.
The main agent is the coordinator — it does NOT scrape itself.

### How it works:
1. Main agent runs Phase 0 (tooling check) and Phase 1 (seed collection) to get initial context
2. Main agent spawns 3-5 sub-agents via `sessions_spawn` with `model: sonnet`, `mode: run`
3. Each sub-agent gets a focused task + all known data from Phase 1
4. Sub-agents return results → main agent merges into dossier

### Task split pattern:
- **Agent 1: YouTube/Content** — extract transcripts via Apify (NOT yt-dlp, NOT BrightData — YouTube blocks them). 3-5 videos, speech style, topics. Use `streamers/youtube-channel-scraper` for channel data
- **Agent 2: Facebook deep** — BrightData scrape: profile, posts, about, photos, friends (use m.facebook.com for more data). For public Pages: `apify/facebook-pages-scraper` + `apify/facebook-page-contact-information`
- **Agent 3: Social platforms** — Instagram (Apify + tagged/comments scrapers), DOU, company websites, LinkedIn (BrightData). Contact enrichment: `vdrmota/contact-info-scraper` on found websites
- **Agent 4: TikTok + Regional** — TikTok profile/videos (`clockworks/tiktok-profile-scraper`), local registries, press, university records, Yandex search, Google Maps (`compass/crawler-google-places` if business owner)
- **Agent 5: Deep research** — Perplexity deep, Exa deep, Parallel deep (if needed)

### Rules:
- Always pass ALL known data to each sub-agent (names, URLs, emails, phones, context)
- Each sub-agent saves results to `/tmp/osint-<subject>-<task>.md`
- Main agent waits for all results, then runs Phase 3-6 (cross-reference, psychoprofile, dossier)
- Budget: each sub-agent ≤$0.15, total swarm ≤$0.50
- YouTube transcripts: use **Apify** actors, NOT BrightData or yt-dlp (both blocked by YouTube)

### Why swarm:
- 5 agents × 5 min = 10 min total (vs 30+ min sequential)
- Sonnet is 5x cheaper than Opus
- Parallel scraping avoids rate limit stacking on single IP

---

## Phase 0: Tooling Self-Check

1. Execute `bash skills/osint/scripts/diagnose.sh`.
2. Log available vs missing tools.
3. Check internal tools: `tg.py` (Telegram history), `himalaya` (email), vault contacts.
4. If Bright Data unavailable → Facebook and LinkedIn deep scrape limited. Inform user.
5. If Apify unavailable → Instagram and LinkedIn structured data limited.
6. Proceed with available toolset.

## Phase 1: Seed Collection

**Start with Level 1 (quick answers) ALWAYS before heavy scraping.**

1. Parse user input. Extract identifiers: names, handles, URLs, companies, locations.
2. **Perplexity fast pass:**
   ```bash
   bash skills/osint/scripts/perplexity.sh search "Who is <Name>, <context>"
   ```
3. **Brave + Parallel in parallel:**
   ```bash
   web_search "<Name> <company>"
   bash skills/osint/scripts/first-volley.sh "Full Name" "context"
   ```
4. **Review Perplexity citations** — fetch and verify top sources:
   ```bash
   web_fetch "<citation_url_1>"
   web_fetch "<citation_url_2>"
   ```
5. Parse & merge: `bash skills/osint/scripts/merge-volley.sh /tmp/osint-<timestamp>`.
6. Collect all identifiers into seed list. Deduplicate.
7. Flag name collisions (common names → verify with company/location cross-reference).
8. **Decision point:** enough context? → skip to Phase 4. Need social media? → Phase 2. Need deep dive? → Level 4 (deep research).

**Rate limiting:** wait 1s between Brave queries, 2s between Jina calls.
Do NOT hammer APIs in tight loops — stagger parallel launches.

## Phase 1.5: Internal Intelligence

**Before going external, check what we already know.** This phase mines local sources
that may contain gold — prior conversations, emails, vault contacts.

### Telegram History
If `tg.py` is available (check Phase 0):
```bash
# Search by name/handle in Telegram
python3 skills/telegram/scripts/tg.py search "Name" 20
# If we have their username/id — read conversation history
python3 skills/telegram/scripts/tg.py history <username_or_id> 50
```

**What to extract from Telegram history:**
- Communication style (formal/informal, language, emoji patterns)
- Topics discussed — what they care about, what they ask for
- Response patterns — reply speed, active hours → timezone
- Shared links/files — projects they work on
- How they address Shima — relationship dynamics
- Mentioned colleagues, partners, competitors → social graph seeds
- Pricing discussions, deal terms (if business contact)

⚠️ **Telegram history is Grade A intelligence** — unfiltered, real-time, authentic.
Weight it higher than curated LinkedIn/Instagram profiles.
⚠️ **Privacy:** internal intelligence stays in the dossier. Never quote DMs in public outputs.

### Email History
If `himalaya` is available:
```bash
# Search emails by name or domain
~/.local/bin/himalaya search "from:name@domain.com OR to:name@domain.com" -f INBOX
# Or by name
~/.local/bin/himalaya search "Name Surname" -f INBOX
~/.local/bin/himalaya search "Name Surname" -f Sent
```

**What to extract from email:**
- Formal communication style vs Telegram style (contrast = insight)
- Business proposals, invoices → financial relationship
- CC'd people → organizational map
- Signature block → title, phone, company, social links (often richer than LinkedIn)

### Vault / CRM Check
```bash
# Check if we already have a card
grep -rl "Name" vault/crm/ vault/aimasters/ vault/tdi/ 2>/dev/null
# Check MOC indexes
grep -i "name" vault/MOC/*.md vault/tdi/_index.md vault/aimasters/_index.md 2>/dev/null
```

**If vault card exists:** read it, note last_accessed, existing tags, prior interactions.
Don't duplicate — enrich the existing card after research completes.

### Node Camera/Location (if paired device available)
If meeting in person and node is available, `nodes camera_snap` can capture context.
Only with explicit user permission.

### Internal Intelligence Summary
After Phase 1.5, you should know:
- Do we have prior relationship? (cold/warm/hot contact)
- What language do they prefer?
- What's their communication style?
- Any existing business context?
- Social graph seeds from conversations

This context shapes Phase 2 priorities — if we already know their career from emails,
focus external research on psychoprofile and social media instead.

## Phase 2: Platform Extraction

Read `references/platforms.md` ONLY when needing URL patterns or extraction signals.

Tool priority (primary → fallback). **If primary fails, switch immediately. Never retry same tool.**

- LinkedIn: `apify.sh linkedin` → `brightdata.sh scrape` → `jina.sh read`
- Instagram: `apify.sh instagram` → `brightdata.sh scrape`
- Instagram deep: `run-actor.sh "apify/instagram-tagged-scraper"` (who tags them), `apify/instagram-comment-scraper` (sentiment)
- Facebook personal: `brightdata.sh scrape` → none (only Bright Data works)
- Facebook pages/groups: `run-actor.sh "apify/facebook-pages-scraper"` → `brightdata.sh scrape`
- TikTok: `run-actor.sh "clockworks/tiktok-profile-scraper"` → `clockworks/tiktok-scraper` (comprehensive)
- TikTok discovery: `run-actor.sh "clockworks/tiktok-user-search-scraper"` (find by keywords)
- YouTube: `run-actor.sh "streamers/youtube-channel-scraper"` → `jina.sh read` → `brightdata.sh scrape`
- Telegram channels: `web_fetch t.me/s/{channel}` → `jina.sh read`
- Twitter/X: `python3 scripts/twitter.py tweet <url>` → `jina.sh read`
- Google Maps (businesses): `run-actor.sh "compass/crawler-google-places"`
- Contact enrichment: `run-actor.sh "vdrmota/contact-info-scraper"` (extract emails/phones from any URL)
- Any site: `jina.sh read` → `brightdata.sh scrape`

**run-actor.sh** = universal Apify runner (embedded, 55+ actors). See `references/tools.md` for full actor catalog.

Read `references/tools.md` ONLY when troubleshooting a failed tool.

### ⚠️ Content Platform Rule (CRITICAL)

When you find YouTube, podcast, blog, or conference talks — read `references/content-extraction.md` **immediately** and extract 3-5 pieces of content on the spot.

Do NOT just note the URL. Extract transcripts/text NOW.
A 20-minute YouTube video reveals more about a person than their entire LinkedIn.
Content platforms are the #1 source for psychoprofile — skipping them = shallow dossier.

### OpSec-Aware Targets

If initial searches return unusually little for someone who should have a footprint:

1. **Wayback Machine:** `web_fetch "https://web.archive.org/web/2024*/target-url"` — deleted profiles, old bios
2. **Google Cache:** `web_search "cache:domain.com/path"` — recently removed pages
3. **Yandex Cache:** `brightdata.sh search-yandex "Name"` — Yandex indexes CIS deeper and caches longer
4. **Username variations:** try transliteration (Иванов → ivanov, ivanoff), birth year suffixes, company abbreviations
5. **Reverse image search:** if photo found, check for other profiles using same avatar
6. **Conference archives:** speaker bios often survive after profiles are deleted

## Phase 3: Cross-Reference & Confidence Scoring

### Step 1: Fact Table
List every claim as a row: fact | source 1 | source 2 | grade.

### Step 2: Cross-check key facts
For each critical fact (employer, role, location, education):
- Compare LinkedIn title vs Telegram signature vs email signature vs company website
- If 2+ match → Grade A
- If only 1 source → Grade B
- If inferred (timezone from messages, geotag) → Grade C
- If single unverified mention → Grade D

### Step 3: Resolve contradictions
If LinkedIn says "CEO" but company site says "Co-founder" — flag explicitly. Include both with sources. Do NOT silently pick one.

### Step 4: Name collision check
If common name — verify at least 2 facts (company + city, or photo + company) link to same person. If unsure, split into separate entities.

### Confidence grades:

- **A (confirmed)**: 2+ independent sources, or official/verified profile, or direct Telegram/email conversation
- **B (probable)**: 1 credible source (LinkedIn, official media, company site)
- **C (inferred)**: indirect evidence (photo geotag, timezone from message patterns, connections)
- **D (unverified)**: single mention, could be wrong

Internal intelligence (Phase 1.5) counts as an independent source.

## Phase 4: Psychoprofile

Read `references/psychoprofile.md` ONLY at this phase.

1. Collect text samples: posts, bios, interviews, channel content, **Telegram messages** (highest signal).
2. Assess MBTI per dimension with cited behavioral evidence and confidence (high/medium/low).
3. Quantify writing style: sentence length, emoji density, self-reference rate.
4. **Compare formal (LinkedIn/email) vs informal (Telegram/Instagram) voice** — the delta reveals the real person.
5. Deduce values from actions, not self-reported claims.
6. Zodiac ONLY if DOB confirmed (Grade A or B).

## Phase 5: Completeness Evaluation (Recursive)

### Axis 1: Data Coverage (pass/fail per dimension)

9 mandatory checks. If any fail, flag as critical gap:

1. Subject correctly identified? (not a namesake)
2. Current role/company confirmed?
3. At least 2 social platforms found?
4. At least 1 contact method (email/phone/messenger)?
5. Career history has 2+ verifiable positions?
6. Location (current) established?
7. At least 1 photo found?
8. No unresolved contradictions between sources?
9. Internal intelligence checked? (Telegram/email/vault — even if empty)

### Axis 2: Depth Score (8 weighted criteria)

| Dimension | Weight | What to score (1-10) |
|-----------|--------|---------------------|
| Identity | 0.15 | Full name, DOB, location, education, photo |
| Career | 0.20 | Completeness of work history, current role clarity |
| Digital footprint | 0.15 | Number of platforms found, account activity level |
| Psychoprofile | 0.15 | MBTI confidence, writing style quantified, values deduced |
| Internal intel | 0.10 | Telegram/email history depth, vault data |
| Personal life | 0.05 | Family, hobbies, lifestyle, pets |
| Cross-reference | 0.10 | How many facts are A-grade, contradiction count |
| Actionability | 0.10 | Entry points identified, approach strategy clear |

Weighted sum (1-10) = **Depth Score**.

### Axis 3: Source Diversity

Count unique source types used (max 12):
LinkedIn, Instagram, Facebook, Telegram DM, Telegram channel, VK, Twitter/X,
company website, press/media articles, conference profiles, government/business registries,
email correspondence.

- 8+ source types = Excellent
- 5-7 = Good
- 2-4 = Shallow
- 1 = Insufficient

### Gap Analysis

| Depth Score | Coverage | Diagnosis | Action |
|------------|----------|-----------|--------|
| 8+ | All pass | Strong dossier | Proceed to Phase 6 |
| 8+ | Some fail | Deep but blind spots | Target failed checks, 1 more cycle |
| <7 | All pass | Wide but shallow | Deepen via interviews/articles/deepsearch |
| <7 | Some fail | Restart needed | Different search angle, new tool combination |

### Stopping Criteria

**(a)** Depth Score ≥ 8.0 AND all coverage checks pass → exit to Phase 6
**(b)** 3 cycles completed → deliver best available with honest assessment
**(c)** Two cycles with delta < 0.5 → plateau reached, deliver with note

### Calibration Benchmarks

- **9-10**: full career timeline, 5+ platforms, confirmed DOB, psychoprofile with high confidence, family/hobbies known, multiple entry points, Telegram history analyzed. Equivalent to a professional PI report.
- **7-8**: career outline, 3+ platforms, most facts B-grade or above, psychoprofile with medium confidence. Solid due diligence.
- **5-6**: basic bio, 1-2 platforms, some gaps. Quick background check level.
- **<5**: minimal data found. Name + current role at best. Flag as insufficient.

## Phase 6: Dossier Output

Read `assets/dossier-template.md` before rendering. Follow the template structure exactly.
No markdown tables in output (Telegram cannot render). Bullet lists only.
Report Depth Score, source count, source types, and total API spend.

If internal intelligence was used, add a separate **"из переписки"** section
(marked as internal/confidential, not for sharing outside).

## Budget

- ≤$0.50 per target: spend without asking.
- >$0.50: ask user before proceeding.
- Track cumulative spend per research session.

## Troubleshooting

- **All tools return empty**: target has minimal digital presence. Try Bright Data Yandex search (better for CIS region), search by company + role instead of name.
- **Wrong person keeps appearing**: add company name, city, or role to all queries. Use quotes around full name.
- **LinkedIn blocked**: use `brightdata.sh scrape` as primary instead of Apify.
- **Apify actor dead/changed**: check `apify.sh store-search "linkedin scraper"` for alternatives. Actors on Apify are volatile — always have a Bright Data fallback.
- **Depth Score stuck at 6-7**: likely missing press/media articles or internal intel. Search industry publications (AdIndex, Sostav, Forbes, Kommersant for Russian market). Try `jina.sh deepsearch`. Check Telegram history.
- **No social media found**: person may use pseudonyms. Search by email, phone, or company employee page. Search Apify store: `bash scripts/apify.sh store-search "people search"`. If `mcpc` installed: `APIFY_TOKEN=$APIFY_API_TOKEN mcpc --json mcp.apify.com --header "Authorization: Bearer $APIFY_TOKEN" tools-call search-actors keywords:="people search" limit:=10`. Check Telegram contacts by phone.
- **TikTok scraper fails**: try `clockworks/free-tiktok-scraper` (free tier) as fallback. TikTok usernames often differ from other platforms — search by real name via `clockworks/tiktok-user-search-scraper`.
- **Need emails from website**: use `vdrmota/contact-info-scraper` — it crawls the site and extracts all contact info.
- **Rate limited (429)**: back off 5s, then 15s. Switch to fallback tool. Never retry immediately.

## Anti-Patterns

1. Never start with a single tool. Launch all available in parallel.
2. Never retry a failed tool more than once. Switch to fallback.
3. Never guess DOB, family, or zodiac.
4. Never attribute data without cross-referencing against namesakes.
5. Never include unsourced facts.
6. Never reveal OSINT methods in public messages.
7. Never exceed 3 recursive cycles. Diminishing returns.
8. Never rate Depth Score 9+ without justification.
9. Never skip psychoprofile. Without it, dossier = Wikipedia article.
10. Never skip Phase 1.5 (internal intel). Telegram history is often the richest source.
11. Never quote DMs verbatim in shareable outputs. Summarize and cite.
12. Never hammer APIs without rate limiting. Stagger requests.
