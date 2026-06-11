# KaJota Concierge — Agent (Python)

The backend half of the [KaJota Concierge Agent](../README.md) — Gemini on Google's Agent Development Kit (ADK), composing two MCP servers (MongoDB Atlas + Anthropic's Fetch MCP) under one reasoning loop.

Submitted to the **Google Cloud Rapid Agent Hackathon 2026** (Jun 11, 2026).

## Track requirements — all met

| Requirement | How |
|---|---|
| **Gemini 3** | `agent.py` reads `GEMINI_MODEL`. Currently pinned to `gemini-2.5-pro` because the `gemini-3.1-pro-preview` Vertex AI allowlist hadn't landed by the deadline. One env-var flip when it does. |
| **Google Cloud ADK** | `google-adk` Python package. `Agent(model=..., tools=[mongodb_mcp, fetch_mcp], instruction=...)` in Vertex AI mode. |
| **Model Context Protocol** | `McpToolset(StdioConnectionParams(...))` registered twice — once per partner. |
| **Partner integration via MCP** | **MongoDB Atlas** via `mongodb-mcp-server@latest` (Node, launched via `npx`) for live merchant data + **public web** via `mcp-server-fetch` (Python module) for competitor / spec / review pages. |

## HTTP surface

```
GET  /              banner: model + partners + endpoints + docs path
GET  /healthz       readiness check
GET  /docs          OpenAPI / Swagger UI

POST /chat          reactive turn — user message in, ChatResponse out
POST /proactive     agentic turn — no user message, agent picks its own
                    tool sequence and returns ChatResponse
```

Both `/chat` and `/proactive` share the same `ChatResponse` shape:

```jsonc
{
  "sessionId": "1d56...",
  "response": "Your last purchase was a New Era 9FIFTY...\n\n[CARDS]\n[...]\n[/CARDS]",
  "events": [
    { "author": "kajota_concierge", "parts": [{ "tool_call": { "name": "find", "args": {...} } }] },
    { "author": "kajota_concierge", "parts": [{ "tool_response": { "name": "find", "preview": "..." } }] },
    { "author": "kajota_concierge", "final": true, "parts": [{ "text": "..." }] }
  ]
}
```

The trailing `[CARDS]...[/CARDS]` JSON block is parsed off the response text by the mobile client and rendered as branded product cards inline. Same payload, two surfaces.

## Architecture

```
┌────────────────────────────────────────────────────────────┐
│  Mobile (KaJota Concierge — Expo)                          │
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

## Local run

```sh
# venv + install
python -m venv .venv
source .venv/bin/activate
pip install -e .

# env (copy and fill)
cat > .env <<'EOF'
GCP_PROJECT_ID=<your-gcp-project>
GCP_REGION=global
GOOGLE_APPLICATION_CREDENTIALS=/abs/path/to/service-account.json
GEMINI_MODEL=gemini-2.5-pro
MONGODB_URI=mongodb+srv://<user>:<pass>@<cluster>.mongodb.net/
PARTNER=mongodb
EOF

# Seed MongoDB collections for the demo (one-shot)
python kajota_concierge/seed.py

# Start the server
python -m kajota_concierge.server
# → http://localhost:8080
```

## Demo prompts

Once the server is up and the demo seed is loaded, these prompts each exercise a different code path:

| Prompt | What it hits |
|---|---|
| (open the mobile Concierge screen) | `POST /proactive` → 3 sequential MongoDB `find` calls + greeting + cards |
| *"What did I last buy?"* | MongoDB `find` on `purchases`, sorted by `orderedAt: -1`, limit 1 |
| *"What's on my wishlist?"* | MongoDB `find` on `wishlist` filtered by `userId` |
| *"What should I get next?"* | MongoDB `aggregate` over purchases + `find` on `products` by category |
| *"Add Supreme to my wishlist"* | MongoDB `find` on `products` then `insert-one` on `wishlist` |
| *"Fetch <URL> and quote the first line"* | Fetch MCP — `python -m mcp_server_fetch` retrieves + converts to Markdown |

## Deploy

The included `Dockerfile` + repo-root `render.yaml` deploy this service to Render in one click. The container ships both runtimes (Python for the agent + Node for the MongoDB MCP `npx` launch) and pre-pulls the MongoDB MCP package at build time so the first user request doesn't pay a 30 MB cold-start tax.
