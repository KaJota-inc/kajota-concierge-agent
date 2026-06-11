#!/usr/bin/env bash
#
# KaJota Concierge Agent — CLI demo recording script
#
# Run this in a terminal you're screen-recording. It pauses between
# steps with `read -r` so you control pace — hit Enter when ready for
# the next step. Each curl pretty-prints with `jq` so the events and
# CARDS block read cleanly on camera.

set -u

AGENT="https://kajota-concierge-agent.onrender.com"
USER_ID="demo-user-1"

pause() {
  echo
  read -rp "── press Enter for the next step ──"
  clear
}

clear
cat <<'EOF'

   ╔══════════════════════════════════════════════════════════════════╗
   ║                                                                  ║
   ║           KaJota Concierge Agent — CLI demo                      ║
   ║                                                                  ║
   ║   Gemini 2.5 Pro · Google Cloud ADK · MongoDB MCP + Fetch MCP    ║
   ║                                                                  ║
   ╚══════════════════════════════════════════════════════════════════╝

EOF

pause

# ─── 1. Banner: confirm what's deployed ───────────────────────────────
echo "▶  1.  Banner — what's running"
echo "    GET ${AGENT}/"
echo
curl -s "${AGENT}/" | jq .

pause

# ─── 2. /proactive — agentic initiative ──────────────────────────────
echo "▶  2.  POST /proactive — agent picks its own queries, no user input"
echo "    Watch the events array: 3 MongoDB \`find\` tool calls in sequence"
echo "    (purchases → wishlist → products), then a CARDS block."
echo
curl -s -X POST "${AGENT}/proactive" \
  -H 'Content-Type: application/json' \
  -d "{\"userId\":\"${USER_ID}\"}" \
  | jq '{
      response: .response,
      tool_calls: [.events[].parts[].tool_call?.name | select(.)],
      cards_present: (.response | test("\\[CARDS\\]"))
    }'

pause

# ─── 3. /chat with MongoDB — one find, one card ──────────────────────
echo "▶  3.  POST /chat  —  \"What did I last buy?\""
echo "    Triggers a single MongoDB \`find\` on the purchases collection."
echo
curl -s -X POST "${AGENT}/chat" \
  -H 'Content-Type: application/json' \
  -d "{\"message\":\"What did I last buy?\",\"userId\":\"${USER_ID}\"}" \
  | jq '{
      response: .response,
      tool_calls: [.events[].parts[].tool_call? | select(.) | {name: .name, args: .args}]
    }'

pause

# ─── 4. /chat with Fetch MCP — public web ────────────────────────────
echo "▶  4.  POST /chat  —  Fetch MCP exercise"
echo "    Agent calls the SECOND MCP server: \`mcp-server-fetch\` for the public web."
echo
curl -s -X POST "${AGENT}/chat" \
  -H 'Content-Type: application/json' \
  -d "{\"message\":\"Use the fetch tool to retrieve https://example.com and quote the first sentence verbatim.\",\"userId\":\"${USER_ID}\"}" \
  | jq '{
      response: .response,
      tool_calls: [.events[].parts[].tool_call? | select(.) | {name: .name, args: .args}]
    }'

pause

cat <<'EOF'

   ╔══════════════════════════════════════════════════════════════════╗
   ║                                                                  ║
   ║              Two MCP servers, one ADK agent.                     ║
   ║                                                                  ║
   ║         github.com/KaJota-inc/kajota-concierge-agent             ║
   ║                                                                  ║
   ╚══════════════════════════════════════════════════════════════════╝

EOF
