#!/usr/bin/env bash
#
# KaJota Concierge Agent — CLI demo recording script (v3)
#
# Streams 8 narrated CLI beats to /tmp/demo-stream.log. A screen-recorded
# terminal that's tailing the log will display the demo live. Beats:
#
#   1. Banner                       — model + both partners + endpoints
#   2. POST /proactive              — agentic init, 3 MongoDB find calls
#   3. POST /chat "What did I last buy?"
#                                   — single find
#   4. POST /chat "What should I get next?"
#                                   — multi-step reasoning (aggregate + find)
#   5. POST /chat "What's on my wishlist?"
#                                   — find on wishlist
#   6. POST /chat "Add Supreme to my wishlist"
#                                   — WRITE op: find + insert-one (and the
#                                     agent reasons about duplicates)
#   7. POST /chat "Where is my Keychron K2 order?"
#                                   — pattern match on itemName (regex find)
#   8. POST /chat fetch             — second MCP partner, public web
#
# Configurable via env:
#   LOG=/tmp/demo-stream.log
#   AGENT=https://kajota-concierge-agent.onrender.com
#   USER_ID=demo-user-1
#   PAUSE_AFTER_BEAT=5

set -u

LOG="${LOG:-/tmp/demo-stream.log}"
AGENT="${AGENT:-https://kajota-concierge-agent.onrender.com}"
USER_ID="${USER_ID:-demo-user-1}"
PAUSE_AFTER_BEAT="${PAUSE_AFTER_BEAT:-5}"

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
  say "   ✓  Reads + writes live MongoDB.    Reaches the public web."
  say "   ✓  Acts before you ask.            Now: same agent, mobile  ──▶"
  say "   ───────────────────────────────────────────────────────────────────"
  say "   github.com/KaJota-inc/kajota-concierge-agent"
  say "   kajota-concierge-agent.onrender.com"
  say
}

run_chat() {
  local msg="$1"
  curl -s -m 180 -X POST "${AGENT}/chat" \
    -H 'Content-Type: application/json' \
    -d "{\"message\":\"${msg}\",\"userId\":\"${USER_ID}\"}" \
    | jq '{
        response: .response,
        tool_calls: [.events[].parts[].tool_call? | select(.) | {name: .name, args: .args}]
      }' \
    | tee -a "${LOG}"
}

# ─── 0. Title ─────────────────────────────────────────────────────────
title_card
sleep 4

# ─── 1. Banner ────────────────────────────────────────────────────────
hdr "1.  Banner" "GET ${AGENT}/"
curl -s -m 30 "${AGENT}/" | jq . | tee -a "${LOG}"
sleep "${PAUSE_AFTER_BEAT}"

# ─── 2. /proactive — agentic ─────────────────────────────────────────
hdr "2.  POST /proactive — agentic, no user input" \
    "Watch: 3 sequential MongoDB find calls (recent purchase, wishlist, by-category recs)."
curl -s -m 180 -X POST "${AGENT}/proactive" \
  -H 'Content-Type: application/json' \
  -d "{\"userId\":\"${USER_ID}\"}" \
  | jq '{
      response: .response,
      tool_calls: [.events[].parts[].tool_call?.name | select(.)],
      cards_present: (.response | test("\\[CARDS\\]"))
    }' | tee -a "${LOG}"
sleep "${PAUSE_AFTER_BEAT}"

# ─── 3. Single find ───────────────────────────────────────────────────
hdr "3.  POST /chat — \"What did I last buy?\"" \
    "Single MongoDB \`find\` on the purchases collection."
run_chat "What did I last buy?"
sleep "${PAUSE_AFTER_BEAT}"

# ─── 4. Aggregate + find ─────────────────────────────────────────────
hdr "4.  POST /chat — \"What should I get next?\"" \
    "Multi-step: \`aggregate\` purchase history -> \`find\` matching products."
run_chat "What should I get next? Use my purchase history."
sleep "${PAUSE_AFTER_BEAT}"

# ─── 5. Wishlist read ────────────────────────────────────────────────
hdr "5.  POST /chat — \"What's on my wishlist?\"" \
    "Single find on the wishlist collection — surfaces target vs current prices."
run_chat "What's on my wishlist? Show all items with current price and target."
sleep "${PAUSE_AFTER_BEAT}"

# ─── 6. WRITE op (with reasoning) ────────────────────────────────────
hdr "6.  POST /chat — \"Add Supreme to my wishlist\"" \
    "WRITE demo: agent checks for duplicates BEFORE inserting (real agentic reasoning, not blind execution)."
run_chat "Add the Supreme Box Logo Hoodie to my wishlist with a target price of 25000 NGNT."
sleep "${PAUSE_AFTER_BEAT}"

# ─── 7. Pattern-match find ───────────────────────────────────────────
hdr "7.  POST /chat — \"Where is my Keychron K2 order?\"" \
    "Pattern find — agent maps user's natural reference to itemName regex."
run_chat "Where is my Keychron K2 order? When will it arrive?"
sleep "${PAUSE_AFTER_BEAT}"

# ─── 8. Fetch MCP (second partner) ───────────────────────────────────
hdr "8.  POST /chat — second MCP partner exercised" \
    "Anthropic's Fetch MCP server. Public-web access from inside the agent."
run_chat "Use the fetch tool to retrieve https://example.com and quote the first sentence verbatim."
sleep "${PAUSE_AFTER_BEAT}"

# ─── Closing card ────────────────────────────────────────────────────
closing_card
