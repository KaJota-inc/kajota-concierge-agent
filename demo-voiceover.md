# KaJota Concierge — Demo voiceover script

Read these lines aloud as each beat lands on screen. Each beat header shows the rough timing — the agent calls take 15-45s each so you have time to breathe between lines. **Total target: 4-5 min.** If you need to trim, cut beats 5 and 7 first (they're nice-to-haves).

Tone: confident, fast, no fluff. Like you're walking a judge through what they're seeing.

---

## INTRO (0:00 - 0:10)

> "KaJota Concierge — a shopping agent built on Google's Agent Development Kit, Gemini 2.5 Pro, and two MCP servers."

*(let title card breathe for a second, then start beat 1)*

---

## Beat 1 — Banner (0:10 - 0:25)

> "The deployed agent reports what it's running — Gemini 2.5 Pro, MongoDB MCP for live merchant data, and Anthropic's Fetch MCP for the public web. Two endpoints — `/chat` reactive, `/proactive` agentic."

---

## Beat 2 — `/proactive` (0:25 - 1:10)

*(as the curl spins, fill the wait with the WHY)*

> "Watch this — no user input. `POST /proactive` fires when the mobile app's Concierge screen mounts. The agent picks its own queries: three sequential MongoDB `find` calls — your most recent order, your wishlist, and a category-matched recommendation. Then it returns prose plus a structured `[CARDS]` JSON block that the mobile UI renders inline. This is the *agentic* claim, on first frame, before you type a single character."

*(when response lands)*

> "Three tool calls, cards present, real data — no RAG indexer behind any of this."

---

## Beat 3 — "What did I last buy?" (1:10 - 1:35)

> "Now a regular chat turn. Single MongoDB `find` on purchases, sorted by orderedAt descending, limit one. The agent reads the response and quotes the item verbatim — no hallucination guard rails needed because the data drove the reply."

---

## Beat 4 — "What should I get next?" (1:35 - 2:15)

> "This one's more interesting — multi-step reasoning. The agent runs an `aggregate` over your purchase history to find your dominant category, then a `find` against the products collection in that category. Three tool calls, one coherent recommendation. The hard part isn't the SQL — it's the agent deciding the sequence itself."

---

## Beat 5 — "What's on my wishlist?" (2:15 - 2:40)

*(optional, can cut if pressed for time)*

> "Same agent, different collection. Find on wishlist, filtered by userId. The reply surfaces current price versus target — exactly what the mobile shopping rail renders as cards."

---

## Beat 6 — WRITE: "Add Supreme to my wishlist" (2:40 - 3:25)

*(this is the MONEY beat — slow down here)*

> "Now a write. *Add Supreme Box Logo Hoodie to my wishlist with a target price of 25000 NGNT*. Watch what the agent does — it doesn't blindly `insert-one`. It runs a `find` first, sees the item is already on the wishlist, and offers to update the target instead. That's agentic reasoning, not script-following. It made the right call without being prompted."

---

## Beat 7 — "Where is my Keychron K2 order?" (3:25 - 3:55)

*(optional)*

> "Pattern match — the user says *Keychron K2* but the document field is `itemName`. The agent maps the natural reference to a regex find and reports back the order status with the expected delivery date verbatim."

---

## Beat 8 — Fetch MCP (3:55 - 4:25)

> "Last CLI beat — the second MCP partner. Anthropic's Fetch MCP server gives the agent a `fetch` tool for the public web. Same `chat` endpoint, completely different tool surface. The agent picks the right one based on the prompt — `find` for KaJota data, `fetch` for anything public. Adding a third partner is one `McpToolset` registration and a prompt paragraph."

---

## Transition to mobile (4:25 - 4:35)

*(focus on emulator window, point at it physically or zoom in)*

> "Same agent. Same MCP servers. Different surface. The mobile app calls the exact endpoints we just ran from CLI."

---

## Beat 9 — Mobile proactive opener (4:35 - 5:15)

*(I auto-relaunch the app, the spinner shows for ~30s, then cards land)*

> "Concierge screen opens — the app fires `/proactive` immediately. No input. While it works, you see the same agentic narrative as the CLI — recent purchase, wishlist deltas, recommendation. Now look —" *(cards land)* "— same `[CARDS]` payload, rendered as branded product cards. The trailing JSON we saw in `curl` becomes this polished shopping rail in the UI. One reply, two surfaces."

---

## Beat 10 — Mobile starter chip (5:15 - 5:45)

*(I tap "What should I get next?" chip)*

> "I tap the multi-step recommendation prompt. Same `aggregate` plus `find` we ran from CLI — now rendered as cards with category subtitles."

*(when cards land)*

> "Nike Dunk Low Panda, New Balance 550 — both picked because sneakers is the user's dominant category in MongoDB."

---

## Beat 11 — Trace expander (5:45 - 6:15)

*(I tap the "Used N MCP tool calls" chip — trace expands)*

> "Every MCP call surfaced inline. `aggregate` on purchases — by category. `find` on products — filtered by sneakers. Tool name, args, response preview. Transparency by design. No black box."

---

## CLOSE (6:15 - 6:30)

> "KaJota Concierge — Two MCP servers, one ADK agent. Code, deploy, and the demo script live on GitHub at KaJota-inc slash kajota-concierge-agent. The agent is running right now at kajota-concierge-agent dot onrender dot com. Thanks."

---

## Pacing cheatsheet

| Marker | What's happening |
|---|---|
| 🎬 Start record | Title card visible in Termius |
| ✓ Beat 1 reveal | Banner JSON streamed |
| ⏳ Beat 2 starts | Long pause (~45s) for `/proactive` — talk slowly |
| ⏳ Beat 5/7 | Optional — skip if you're tight on time |
| 🔥 Beat 6 (write) | This is your highlight — emphasize the agent's reasoning |
| 🔀 Transition | Look at emulator window deliberately |
| 📱 Beat 9 spinner | Use the wait to set up beat 10 narration |
| 🛑 End | Closing card lands → stop recording within 3 sec |

---

## If something goes wrong

- **A curl times out:** keep talking. The agent might've stalled on cold start. After the closing card streams, we can re-record just that beat and splice in post.
- **Emulator pauses too long on spinner:** voiceover the architecture from memory ("Gemini → ADK → MongoDB MCP server → Atlas") to fill time.
- **Cards don't render on mobile:** force-stop and relaunch. I'll re-fire from this chat.

When you're set up and rolling, reply **"fire"**.
