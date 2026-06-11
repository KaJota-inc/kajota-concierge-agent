#!/usr/bin/env bash
#
# KaJota Concierge Agent — CLI demo recording script (v2)
#
# Streams formatted output to /tmp/demo-stream.log so a screen-recorded
# Termius window tailing the file shows everything live. Six beats:
#
#   1. Banner                — model + both partners + endpoints
#   2. /proactive            — agentic, 3 sequential MongoDB find calls
#   3. /chat "What did I last buy?"
#                            — single find demo
#   4. /chat "What should I get next?"
#                            — aggregate + find = multi-step reasoning
#   5. /chat "Add Supreme to my wishlist"
#                            — WRITE operation (find + insert-one)
#   6. /chat fetch Wikipedia — second MCP partner exercised on real page
#
# Run from a terminal that has jq + curl. Output writes to a log; you
# point `tail -f /tmp/demo-stream.log` at it from your recorded window.

set -u

LOG="${LOG:-/tmp/demo-stream.log}"
AGENT="${AGENT:-https://kajota-concierge-agent.onrender.com}"
USER_ID="${USER_ID:-demo-user-1}"
PAUSE_AFTER_BEAT="${PAUSE_AFTER_BEAT:-6}"

# Reset the log so consecutive runs don't bleed together.
: > "${LOG}"

say() { echo "$@" | tee -a "${LOG}"; }
hdr() {
  say
  say
  say "▶  $1"
  [ -n "${2:-}" ] && say "    $2"
  say
}
title_card() {
  say
  say "   ╔══════════════════════════════════════════════════════════════════╗"
  say "   ║                                                                  ║"
  say "   ║   KaJota Concierge Agent — Rapid Agent Hackathon 2026            ║"
  say "   ║                                                                  ║"
  say "   ║   Gemini 2.5 Pro · Google Cloud ADK · MongoDB MCP + Fetch MCP    ║"
  say "   ║                                                                  ║"
  say "   ╚══════════════════════════════════════════════════════════════════╝"
  say
}
closing_card() {
  say
  say
  say "   ───────────────────────────────────────────────────────────────────"
  say "   ✓  Two MCP servers, one ADK agent."
  say "   ✓  Reads + writes live MongoDB.  Reaches the public web."
  say "   ✓  Acts before you ask.  Now: same agent, mobile surface  ──▶"
  say "   ───────────────────────────────────────────────────────────────────"
  say "   github.com/KaJota-inc/kajota-concierge-agent"
  say "   kajota-concierge-agent.onrender.com"
  say
}

# ─── 0. Title ─────────────────────────────────────────────────────────
title_card
sleep 5

# ─── 1. Banner ────────────────────────────────────────────────────────
hdr "1.  Banner" "GET ${AGENT}/"
curl -s -m 30 "${AGENT}/" | jq . | tee -a "${LOG}"
sleep "${PAUSE_AFTER_BEAT}"

# ─── 2. /proactive — agentic initiative ──────────────────────────────
hdr "2.  POST /proactive — agentic, no user input" \
    "Watch: 3 sequential MongoDB find calls + a structured [CARDS] payload."
curl -s -m 180 -X POST "${AGENT}/proactive" \
  -H 'Content-Type: application/json' \
  -d "{\"userId\":\"${USER_ID}\"}" \
  | jq '{
      response: .response,
      tool_calls: [.events[].parts[].tool_call?.name | select(.)],
      cards_present: (.response | test("\\[CARDS\\]"))
    }' | tee -a "${LOG}"
sleep "${PAUSE_AFTER_BEAT}"

# ─── 3. /chat — single MongoDB find ──────────────────────────────────
hdr "3.  POST /chat — \"What did I last buy?\"" \
    "Single MongoDB \`find\` on the purchases collection."
curl -s -m 120 -X POST "${AGENT}/chat" \
  -H 'Content-Type: application/json' \
  -d "{\"message\":\"What did I last buy?\",\"userId\":\"${USER_ID}\"}" \
  | jq '{
      response: .response,
      tool_calls: [.events[].parts[].tool_call? | select(.) | {name: .name, args: .args}]
    }' | tee -a "${LOG}"
sleep "${PAUSE_AFTER_BEAT}"

# ─── 4. /chat — multi-step reasoning ─────────────────────────────────
hdr "4.  POST /chat — \"What should I get next?\"" \
    "Multi-step: \`aggregate\` purchase history -> \`find\` matching products."
curl -s -m 180 -X POST "${AGENT}/chat" \
  -H 'Content-Type: application/json' \
  -d "{\"message\":\"What should I get next? Use my purchase history.\",\"userId\":\"${USER_ID}\"}" \
  | jq '{
      response: .response,
      tool_calls: [.events[].parts[].tool_call? | select(.) | {name: .name, args: .args}]
    }' | tee -a "${LOG}"
sleep "${PAUSE_AFTER_BEAT}"

# ─── 5. /chat — WRITE operation ──────────────────────────────────────
hdr "5.  POST /chat — \"Add Supreme to my wishlist\"" \
    "WRITE operation: \`find\` lookup then \`insert-one\` into wishlist."
curl -s -m 180 -X POST "${AGENT}/chat" \
  -H 'Content-Type: application/json' \
  -d "{\"message\":\"Add the Supreme Box Logo Hoodie to my wishlist with a target price of 25000 NGNT.\",\"userId\":\"${USER_ID}\"}" \
  | jq '{
      response: .response,
      tool_calls: [.events[].parts[].tool_call? | select(.) | {name: .name, args: .args}]
    }' | tee -a "${LOG}"
sleep "${PAUSE_AFTER_BEAT}"

# ─── 6. /chat — Fetch MCP (second partner) ───────────────────────────
hdr "6.  POST /chat — second MCP partner" \
    "Anthropic's Fetch MCP server. Public-web access in one tool call."
curl -s -m 120 -X POST "${AGENT}/chat" \
  -H 'Content-Type: application/json' \
  -d "{\"message\":\"Use the fetch tool to retrieve https://example.com and quote the first sentence verbatim.\",\"userId\":\"${USER_ID}\"}" \
  | jq '{
      response: .response,
      tool_calls: [.events[].parts[].tool_call? | select(.) | {name: .name, args: .args}]
    }' | tee -a "${LOG}"
sleep "${PAUSE_AFTER_BEAT}"

# ─── Closing card ────────────────────────────────────────────────────
closing_card
