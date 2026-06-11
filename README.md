# KaJota Concierge Agent

> Shopping concierge agent built on **Gemini** + **Google Cloud Agent Development Kit (ADK)** + **two MCP servers** — MongoDB Atlas for merchant data, Anthropic's Fetch MCP for the public web. Greets you with a personalised briefing the moment you open the screen, before you type anything.
>
> **Submission for the Google Cloud Rapid Agent Hackathon 2026** (deadline 2026-06-11, 2:00 PM PT).
>
> Live deployed agent: <https://kajota-concierge-agent.onrender.com>
> Full submission writeup: [`docs/SUBMISSION.md`](./docs/SUBMISSION.md)

---

## What it does

| | |
|---|---|
| **Reads live merchant data** | The agent issues `find` / `aggregate` / `insert-one` against MongoDB Atlas in real time, via the official `mongodb-mcp-server`. No RAG indexer to keep in sync. |
| **Reaches the public web** | A second MCP server — Anthropic's `mcp-server-fetch` — gives the agent a `fetch` tool for competitor prices and public product / review pages. Two MCP partners, composed under one ADK reasoning loop. |
| **Acts before you ask** | Open the Concierge screen and `POST /proactive` fires automatically. The agent picks its own MongoDB queries (recent purchase, wishlist, recommendation by category) and renders a personalised greeting + product cards without a single user keystroke. |
| **Structured reply, free-form prose** | Every product / order / wishlist turn returns plain-text prose AND a trailing `[CARDS]…[/CARDS]` JSON block the mobile UI parses into branded product cards. One reply, two surfaces. |

## Architecture

```
┌────────────────────────────────────────────────────────────┐
│  Mobile (Expo / React Native)                              │
│   • Reactive chat:  POST /chat                             │
│   • Proactive turn: POST /proactive  (called on mount)     │
└───────────────────────────┬────────────────────────────────┘
                            │ HTTPS
┌───────────────────────────▼────────────────────────────────┐
│  Render Web Service (Docker)                               │
│    FastAPI: kajota_concierge.server                        │
│      ↓                                                     │
│    ADK Runner ──▶ root_agent (Gemini 2.5 Pro on Vertex AI) │
│                     │                                      │
│                     ├─tools─▶ McpToolset (stdio, Node)     │
│                     │             └─▶ mongodb-mcp-server   │
│                     │                       │              │
│                     │                       ▼              │
│                     │              MongoDB Atlas           │
│                     │                                      │
│                     └─tools─▶ McpToolset (stdio, Python)   │
│                                   └─▶ mcp-server-fetch     │
│                                             │              │
│                                             ▼              │
│                                        Public web          │
└────────────────────────────────────────────────────────────┘
```

## Repo layout

```
kajota-concierge-agent/
├── agent/                          # Python ADK service (deploys to Render)
│   ├── kajota_concierge/
│   │   ├── agent.py                # Agent definition + both MCP toolsets
│   │   ├── server.py               # FastAPI wrapper: /chat, /proactive, /healthz
│   │   └── seed.py                 # MongoDB seed script for the demo
│   ├── Dockerfile                  # python:3.11-slim + Node 22 (for MongoDB MCP)
│   └── pyproject.toml
├── src/
│   ├── screens/
│   │   └── ConciergeScreen.tsx     # Chat UI + product cards + tool trace
│   ├── services/
│   │   └── conciergeAgent.ts       # Client for /chat + /proactive
│   ├── types/index.ts              # Shared wire-format types
│   └── constants/colors.ts         # Brand tokens
├── App.tsx                         # Single-screen Expo app
├── render.yaml                     # One-click deploy to Render
├── docs/SUBMISSION.md              # Devpost submission text
└── README.md                       # You are here
```

## Running it

### Backend agent (locally)

```sh
cd agent

# Create venv + install (mcp-server-fetch is a transitive dep)
python -m venv .venv
source .venv/bin/activate
pip install -e .

# Set env: GCP project, service account, MongoDB URI
cp .env.example ../.env.rapid-agent   # if you have the example
# Edit .env.rapid-agent with: GCP_PROJECT_ID, MONGODB_URI, GEMINI_MODEL

# Seed the demo MongoDB collections (one-shot)
python kajota_concierge/seed.py

# Start the FastAPI server
python -m kajota_concierge.server
# → http://localhost:8080/chat
# → http://localhost:8080/proactive
# → http://localhost:8080/healthz
```

### Backend agent (deployed)

The included [`render.yaml`](./render.yaml) deploys the Docker image to Render's free tier in one click. Mount the GCP service-account JSON as a Render Secret File at `/etc/secrets/gcp-service-account.json` and supply `MONGODB_URI` via the dashboard.

The live deployment for this submission lives at <https://kajota-concierge-agent.onrender.com>.

### Mobile app

```sh
# From repo root
npm install
# postinstall runs patch-package automatically (expo-dev-menu fix for Xcode 26)

# iOS dev build
npx expo run:ios

# Android dev build
npx expo run:android
```

The mobile app reads `extra.conciergeAgentBaseUrl` from `app.json` — points at the deployed agent by default. Override it to hit a local backend.

## Track requirements — every box ticked

| Requirement | Where |
|---|---|
| **Gemini 3** | `agent/kajota_concierge/agent.py` — `GEMINI_MODEL` env var. Currently `gemini-2.5-pro` because the Gemini-3 preview allowlist hadn't landed by the deadline; one-line flip back when it does. |
| **Google Cloud ADK** | `agent/kajota_concierge/agent.py` — `Agent(model=..., tools=[mongodb_mcp, fetch_mcp], instruction=...)` running in Vertex AI mode. |
| **Model Context Protocol** | `McpToolset(StdioConnectionParams(...))` registered twice, once per partner. |
| **Partner integration via MCP** | **MongoDB Atlas** via `mongodb-mcp-server@latest` (Node) **+** the public web via Anthropic's `mcp-server-fetch` (Python). |

## Demo flow

1. Open the Concierge screen — `POST /proactive` fires automatically. The agent runs three MongoDB `find` calls (most recent purchase, full wishlist, category-matched recommendation) and returns a personalised greeting + 3-4 product cards. No user input.
2. Tap any starter chip — *"What did I last buy?"*, *"What's on my wishlist?"*, *"Add Supreme to my wishlist"*. Live MongoDB queries through the MCP, cards rendered inline.
3. Ask a public-web question — *"Fetch https://example.com and quote the first line"*. The agent calls the Fetch MCP, quotes the page verbatim, and the trace chip shows *"Used 1 MCP tool call (fetch)"*.
4. Tap any **"Used N MCP tool calls (mongodb / fetch / both)"** chip to expand the per-tool trace: tool name, args, and a preview of the MCP response.

See [`docs/SUBMISSION.md`](./docs/SUBMISSION.md) for the full Devpost writeup, architecture, challenges, and what we'd build next.

## License

MIT — see [`LICENSE`](./LICENSE).
