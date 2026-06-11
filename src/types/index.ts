/**
 * Shared types for the KaJota Concierge mobile client.
 *
 * Mirrors the backend Pydantic models in
 * `agent/kajota_concierge/server.py`. Keep them in sync — every wire
 * format change should land here too.
 */

/* ------------------------------------------------------------------ */
/*  Navigation                                                        */
/* ------------------------------------------------------------------ */

export type RootStackParamList = {
  Concierge: undefined;
};

/* ------------------------------------------------------------------ */
/*  Agent wire formats                                                */
/*  Talks directly to the standalone Concierge agent service —        */
/*  POST /chat and POST /proactive both return ChatResponse.          */
/*  Shape mirrors agent/kajota_concierge/server.py ChatResponse.      */
/* ------------------------------------------------------------------ */

/** One ADK event part — either text, a tool call, or a tool response. */
export interface ConciergeEventPart {
  text?: string;
  tool_call?: { name: string; args: Record<string, unknown> };
  tool_response?: { name: string; preview: string };
}

/** One ADK event row from the agent's run_async stream. */
export interface ConciergeEvent {
  author: string;
  final: boolean;
  parts: ConciergeEventPart[];
}

export interface ConciergeChatRequest {
  message: string;
  userId?: string;
  sessionId?: string | null;
}

export interface ConciergeChatResponse {
  sessionId: string;
  response: string;
  events: ConciergeEvent[];
}

/** Flattened tool invocation for inline rendering in the chat bubble. */
export interface ConciergeToolInvocation {
  name: string;
  /** JSON-stringified args (e.g. `{"collection":"purchases","filter":...}`). */
  args?: string;
  /** Truncated preview of the MCP tool response. */
  preview?: string;
}

/**
 * Structured product/order/wishlist card the agent emits inside a
 * trailing `[CARDS]...[/CARDS]` JSON block. Mirrors the format
 * pinned in `agent/kajota_concierge/agent.py` system prompt.
 */
export interface ConciergeProductCard {
  /** Item name (e.g. "Yeezy Boost 350 v2"). */
  title: string;
  /** Category, status, or short tag (e.g. "sneakers", "delivered"). */
  subtitle: string;
  /** Display price with currency (e.g. "39000 NGNT"). */
  price: string;
  /** Optional extra line — target price, ETA, restock note, etc. */
  footer: string;
}

/** Local-only chat-bubble shape used by ConciergeScreen. */
export interface ConciergeLocalMessage {
  id: string;
  role: 'user' | 'agent';
  text: string;
  toolsCalled?: ConciergeToolInvocation[];
  /** Cards parsed out of the agent's trailing CARDS block. */
  cards?: ConciergeProductCard[];
  timestamp: number;
  pending?: boolean;
  error?: string;
}
