# OSINT Skill for Claude Code

> **Early Beta** — работает, но API могут меняться, акторы Apify ротируются, а edge cases ещё не все обкатаны.

Систематический сбор разведданных по физическим лицам. От имени или хендла — до scored-досье с психопрофилем, картой карьеры и точками входа.

## Что умеет

- **Фазовый pipeline** (0→1→1.5→2→3→4→5→6): от быстрого поиска до deep research
- **Swarm Mode**: координирует 3-5 параллельных sub-агентов на Sonnet для скорости
- **55+ Apify акторов** встроены: Instagram (12), Facebook (14), TikTok (14), YouTube (5), Google Maps (4), LinkedIn, и другие
- **Psychoprofile**: MBTI/Big Five на основе контент-анализа (YouTube, Telegram, блоги)
- **Confidence Scoring**: каждый факт получает грейд A/B/C/D по количеству независимых подтверждений
- **Internal Intelligence**: проверяет Telegram историю, email, vault контакты ДО внешнего поиска
- **Research Escalation**: 4 уровня от бесплатного до $0.50, от секунд до минут
- **Budget tracking**: ≤$0.50 без спроса, выше — спрашивает

## Установка

```bash
# Скопировать в директорию skills вашего проекта
cp -r osint/ <your-project>/skills/osint/
```

Или для Claude Code:
```bash
cp -r osint/ ~/.claude/skills/osint/
```

## Зависимости

### Обязательные

| Инструмент | Зачем | Установка |
|-----------|-------|-----------|
| **curl** | HTTP-запросы к API | Предустановлен на macOS/Linux |
| **python3** | Парсинг JSON-ответов, MCP-клиент | Предустановлен на macOS/Linux |
| **jq** | Обработка JSON (используется в некоторых скриптах) | `brew install jq` / `apt install jq` |

### Для Apify акторов (55+ платформ)

| Инструмент | Зачем | Установка |
|-----------|-------|-----------|
| **Node.js 18+** | Запуск `run_actor.js` (встроенный Apify runner) | [nodejs.org](https://nodejs.org) |

### Опциональные

| Инструмент | Зачем | Установка |
|-----------|-------|-----------|
| **mcpc** | Динамический поиск акторов в Apify Store | `npm install -g @apify/mcpc` |

## API-ключи и сервисы

Skill работает по принципу graceful degradation — чем больше ключей, тем глубже копает. Минимум нужен **хотя бы один** поисковый API.

### Бесплатные / Free Tier

| Сервис | Env переменная | Что даёт | Где получить |
|--------|---------------|----------|-------------|
| **Brave Search** | _(встроен в Claude Code)_ | 2000 запросов/мес, базовый поиск | Встроен, ничего не нужно |
| **Jina AI** | `JINA_API_KEY` | Чтение URL → markdown, поиск, deepsearch | [jina.ai/api-key](https://jina.ai/api-key) |
| **Apify** | `APIFY_API_TOKEN` | Instagram, TikTok, YouTube, LinkedIn scraping. Free tier ~$5/мес | [console.apify.com/account/integrations](https://console.apify.com/account/integrations) |

### Платные (рекомендуются)

| Сервис | Env переменная | Что даёт | Стоимость | Где получить |
|--------|---------------|----------|-----------|-------------|
| **Perplexity API** | `PERPLEXITY_API_KEY` | Sonar (быстрые AI-ответы), Deep Research | ~$5/мес | [perplexity.ai/settings/api](https://www.perplexity.ai/settings/api) |
| **Exa AI** | `EXA_API_KEY` | Семантический поиск, people/company research | ~$5/мес | [dashboard.exa.ai](https://dashboard.exa.ai) |
| **Tavily** | `TAVILY_API_KEY` | Agent-optimized поиск, $0.005/запрос basic | ~$5/мес | [app.tavily.com](https://app.tavily.com/home) |
| **Parallel AI** | `PARALLEL_API_KEY` | AI-поиск с reasoning и citations | Free tier | [platform.parallel.ai](https://platform.parallel.ai) |

### Продвинутые

| Сервис | Env переменная | Что даёт | Стоимость | Где получить |
|--------|---------------|----------|-----------|-------------|
| **Bright Data** | `BRIGHTDATA_MCP_URL` | Обход CAPTCHA, authwall, Cloudflare. Facebook. Yandex поиск | ~$10/мес+ | [brightdata.com/products/web-scraper/mcp](https://brightdata.com/products/web-scraper/mcp) |

### Настройка ключей

Два способа:

**1. Environment variables (рекомендуется):**
```bash
export PERPLEXITY_API_KEY="pplx-..."
export EXA_API_KEY="exa-..."
export APIFY_API_TOKEN="apify_api_..."
export JINA_API_KEY="jina_..."
export TAVILY_API_KEY="tvly-..."
export PARALLEL_API_KEY="..."
export BRIGHTDATA_MCP_URL="https://mcp.brightdata.com/..."
```

**2. File fallback** (для скриптов, которые это поддерживают):
```
<workspace>/scripts/apify-api-token.txt
<workspace>/scripts/jina-api-key.txt
<workspace>/scripts/parallel-api-key.txt
<workspace>/scripts/brightdata-mcp-url.txt
```

### Самодиагностика

```bash
bash scripts/diagnose.sh
```

Покажет какие API доступны, какие инструменты установлены, и какие возможности активны.

## Как работает

### Фазы исследования

```
Phase 0: Tooling Self-Check     → diagnose.sh, проверка окружения
Phase 1: Seed Collection        → быстрый поиск по всем движкам параллельно
Phase 1.5: Internal Intelligence → Telegram, email, vault (ДО внешних источников)
Phase 2: Platform Extraction    → LinkedIn, Instagram, Facebook, TikTok, YouTube...
Phase 3: Cross-Reference        → факты сверяются, грейды A/B/C/D
Phase 4: Psychoprofile          → MBTI, Big Five, стиль коммуникации
Phase 5: Completeness Check     → 9 обязательных проверок + Depth Score 1-10
Phase 6: Dossier Output         → форматированное досье по шаблону
```

### Research Escalation (от дешёвого к дорогому)

```
Level 1: Quick Answers     → Perplexity Sonar, Brave, Tavily, Exa (~$0.00)
Level 2: Source Verification → Jina read, Parallel extract (~$0.01)
Level 3: Social Media       → Apify scrapers, Bright Data (~$0.01-0.10)
Level 4: Deep Research       → Perplexity Deep, Exa Deep, Jina DeepSearch (~$0.05-0.50)
```

### Встроенные скрипты

| Скрипт | Назначение |
|--------|-----------|
| `diagnose.sh` | Самодиагностика всех инструментов и API |
| `perplexity.sh` | search / sonar / deep research |
| `tavily.sh` | search / deep / extract |
| `exa.sh` | search / company / people / crawl / deep |
| `first-volley.sh` | Параллельный поиск по всем движкам |
| `merge-volley.sh` | Дедупликация и группировка результатов |
| `apify.sh` | LinkedIn / Instagram / любой актор / store search |
| `run-actor.sh` | Universal Apify runner (55+ акторов, polling, CSV/JSON export) |
| `run_actor.js` | Node.js движок для run-actor.sh |
| `jina.sh` | read URL / search / deepsearch |
| `parallel.sh` | search / extract |
| `brightdata.sh` | scrape / search / search-geo / search-yandex |
| `mcp-client.py` | Lightweight MCP клиент для Bright Data |

## Структура

```
osint/
├── SKILL.md                          # Главный файл skill'а (452 строки)
├── references/
│   ├── tools.md                      # Каталог 55+ Apify акторов + все инструменты
│   ├── platforms.md                  # Platform-specific extraction guide
│   ├── content-extraction.md         # YouTube/podcast/blog extraction
│   └── psychoprofile.md              # MBTI/Big Five methodology
├── assets/
│   └── dossier-template.md           # Шаблон выходного досье
└── scripts/
    ├── diagnose.sh                   # Self-check
    ├── run-actor.sh                  # Universal Apify runner (bash wrapper)
    ├── run_actor.js                  # Apify runner engine (Node.js, embedded)
    ├── package.json                  # ESM support for run_actor.js
    ├── apify.sh                      # Apify shortcuts
    ├── perplexity.sh                 # Perplexity API
    ├── tavily.sh                     # Tavily API
    ├── exa.sh                        # Exa AI API
    ├── jina.sh                       # Jina AI API
    ├── parallel.sh                   # Parallel AI API
    ├── brightdata.sh                 # Bright Data MCP
    ├── mcp-client.py                 # MCP client (Python, stdlib only)
    ├── first-volley.sh               # Parallel first search
    └── merge-volley.sh               # Result merging
```

## Known Issues (Beta)

- **Shell injection**: пользовательский ввод интерполируется в JSON без экранирования через `jq`. Не запускайте с недоверенным вводом.
- **macOS**: `first-volley.sh` использует `tail --pid` (Linux-only). На macOS параллельные поиски работают, но timeout-логика может не срабатывать.
- **Apify акторы**: ID акторов могут меняться или удаляться. Если актор не найден — используйте `apify.sh store-search` для поиска альтернатив.
- **Perplexity/Tavily/Exa**: ключи загружаются ТОЛЬКО из env vars (нет file fallback в отличие от Apify/Jina/Parallel).

## Credits

- **Apify Actor Runner** (`run_actor.js`) embedded from [apify/agent-skills](https://github.com/apify/agent-skills) (MIT License)
- Actor catalog based on [apify-ultimate-scraper](https://github.com/apify/agent-skills/tree/main/skills/apify-ultimate-scraper) v1.3.0

## License

MIT
