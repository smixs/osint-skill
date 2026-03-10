# Platform-Specific Extraction Guide

## LinkedIn

**Extract:** headline, positions (title, company, duration, description), education, summary, skills, location, pronouns, follower/connection count.

**Finding profiles - URL patterns to try:**
- /in/firstnamelastname
- /in/firstname-lastname
- /in/flastname
- /in/lastname (if unique enough)

**Search patterns:**
- Brave: `site:linkedin.com "First Last" company`
- Parallel: `"First Last" LinkedIn profile company city`

**Key signals:**
- Gaps between positions = career breaks
- "Co-founder" vs "Founder" vs "Partner" = different ownership levels
- Location changes between roles = relocation history
- Short tenures (<1yr) = fired, bad fit, or stepping stone

## Instagram

**Extract:** bio, follower/following ratio, post count/frequency, captions, hashtags, engagement, highlights count.

**Engagement rate:** (avg likes + comments) / followers * 100
- >6% = close friends/niche, 3-6% = good, 1-3% = average, <1% = bots

**Style signals:**
- Minimal captions = private personality
- Film photography hashtags = aesthetic sensibility
- No selfies = introverted
- High highlights count + low posts = active stories user

## Facebook

**Extract (via Bright Data only):** name, bio/intro, follower count, location, workplace, education, linked Instagram, website, recent public posts.

**URL patterns:**
- facebook.com/{username}
- facebook.com/share/{id} (mobile share links - resolve to profile)
- facebook.com/profile.php?id={numeric_id}

## Telegram

**Extract:** profile bio/title (t.me/{user}), channel posts (t.me/s/{channel}).

**Writing analysis goldmine:**
- Posts usually unedited = authentic voice
- Posting times = timezone/work patterns
- Emoji patterns = personality markers
- Topic clusters = real vs performative interests
- Forwarded from = what they read/follow

## YouTube

**Extract:** channel name, handle, subscriber count, video count, upload frequency, about/description, top videos by views, playlist structure.

**Finding channels:**
- Brave: `site:youtube.com "<Name>" channel`
- Exa: `exa.sh search "<Name> youtube"`
- Check LinkedIn/Instagram bios for YouTube links

**Key signals:**
- Upload frequency = discipline, commitment to topic
- Subscriber/view ratio = audience quality
- Comment engagement = community building skills
- Video titles style = marketing/clickbait vs informative
- Playlist structure = how they organize knowledge
- Collaborations = social graph in their niche

**Transcript extraction = HIGHEST PRIORITY.**
See `references/content-extraction.md`. 3-5 transcripts minimum when channel found.

## Podcasts / Audio

**Finding appearances:**
- Brave: `"<Name>" podcast interview guest`
- Exa: `exa.sh search "<Name> podcast episode"`

**Key signals:**
- Personal questions from host → origin story, failures, mentors
- Cross-reference claims in podcast vs LinkedIn (people exaggerate on podcasts too, but differently)
- Guest on niche podcasts = real expertise; guest on general podcasts = self-promotion

## TikTok

**Extract:** username, bio, follower/following count, total likes, video count, top videos by views, hashtags used, engagement rate.

**Finding accounts:**
- Brave: `site:tiktok.com "@username" OR "Name"`
- Apify: `clockworks/tiktok-user-search-scraper` with keywords
- Check Instagram/YouTube bios for TikTok links

**URL patterns:**
- tiktok.com/@username
- tiktok.com/@username/video/{id}

**Key signals:**
- Short-form video = unfiltered personality (harder to fake than LinkedIn)
- Duets/stitches = who they interact with (social graph)
- Sound choices = cultural references, generation markers
- Comment replies = engagement style, how they handle criticism
- Posting frequency = discipline, content strategy vs impulse

**Style analysis:**
- Face-to-camera = confident, extroverted
- Voiceover only = introverted or analytical
- Trending sounds = follower mentality
- Original audio = thought leader / creator
- High production = professional content, possible team

## Google Maps / Business Listings

**Extract:** business name, address, phone, website, hours, reviews, rating, owner responses.

**OSINT value:**
- Owner responses to reviews = writing style, conflict resolution patterns
- Business address = physical location confirmation
- Multiple businesses at same address = related entities
- Review timeline = business lifecycle

## Industry Sources (Russian market)
- AdIndex.ru - ad industry news, appointments, interviews
- Sostav.ru - marketing industry portal
- GlobMSK.ru - Moscow business directory with bios
- Kommersant.ru - business newspaper, rankings
- Forbes.ru - profiles, lists
- ConferenceCast.tv - speaker profiles with video
