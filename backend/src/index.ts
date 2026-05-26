import Kuroshiro from "kuroshiro";
import KuromojiAnalyzer from "kuroshiro-analyzer-kuromoji";

const DICT_CDN = "https://cdn.jsdelivr.net/npm/kuromoji@0.1.2/dict/";

// Polyfill XMLHttpRequest for Cloudflare Workers (kuromoji's BrowserDictionaryLoader needs it)
if (typeof (globalThis as Record<string, unknown>).XMLHttpRequest === "undefined") {
  class XMLHttpRequestPolyfill {
    _url = "";
    _method = "GET";
    responseType = "";
    status = 0;
    statusText = "";
    response: unknown = null;
    onload: (() => void) | null = null;
    onerror: ((err: unknown) => void) | null = null;

    open(method: string, url: string) {
      this._method = method;
      this._url = url;
    }

    async send() {
      try {
        const resp = await fetch(this._url);
        this.status = resp.status;
        this.statusText = resp.statusText;
        if (!resp.ok) {
          this.onerror?.(this.statusText);
          return;
        }
        if (this.responseType === "arraybuffer") {
          this.response = await resp.arrayBuffer();
        } else {
          this.response = await resp.text();
        }
        this.onload?.();
      } catch (err) {
        this.onerror?.(err);
      }
    }
  }
  (globalThis as Record<string, unknown>).XMLHttpRequest = XMLHttpRequestPolyfill;
}

let kuroshiro: Kuroshiro | null = null;
let initPromise: Promise<void> | null = null;

async function initKuroshiro(): Promise<void> {
  if (kuroshiro) return;
  if (initPromise) {
    await initPromise;
    return;
  }

  initPromise = (async () => {
    const instance = new Kuroshiro();
    await instance.init(new KuromojiAnalyzer({ dictPath: DICT_CDN }));
    kuroshiro = instance;
  })();

  try {
    await initPromise;
  } catch (err) {
    initPromise = null;
    throw err;
  }
}

interface AnnotateRequest {
  text: string;
  mode?: "furigana" | "okurigana" | "romaji";
  to?: "hiragana" | "katakana" | "romaji";
}

function validateInput(body: unknown): AnnotateRequest | string {
  if (!body || typeof body !== "object") {
    return "Request body must be a JSON object";
  }
  const { text, mode, to } = body as Record<string, unknown>;

  if (!text || typeof text !== "string") {
    return "`text` field is required and must be a string";
  }
  const validModes = ["furigana", "okurigana", "romaji"];
  if (mode !== undefined && !validModes.includes(mode as string)) {
    return `\`mode\` must be one of: ${validModes.join(", ")}`;
  }

  const validTargets = ["hiragana", "katakana", "romaji"];
  if (to !== undefined && !validTargets.includes(to as string)) {
    return `\`to\` must be one of: ${validTargets.join(", ")}`;
  }

  return {
    text: text as string,
    mode: (mode as AnnotateRequest["mode"]) ?? "furigana",
    to: (to as AnnotateRequest["to"]) ?? "hiragana",
  };
}

function corsHeaders(): Record<string, string> {
  return {
    "Access-Control-Allow-Origin": "*",
    "Access-Control-Allow-Methods": "POST, OPTIONS",
    "Access-Control-Allow-Headers": "Content-Type",
  };
}

function jsonResponse(data: unknown, status = 200): Response {
  return new Response(JSON.stringify(data), {
    status,
    headers: {
      "Content-Type": "application/json",
      ...corsHeaders(),
    },
  });
}

export default {
  async fetch(request: Request): Promise<Response> {
    if (request.method === "OPTIONS") {
      return new Response(null, { status: 204, headers: corsHeaders() });
    }

    if (request.method !== "POST") {
      return jsonResponse({ error: "Method not allowed, use POST" }, 405);
    }

    let body: unknown;
    try {
      body = await request.json();
    } catch {
      return jsonResponse({ error: "Invalid JSON body" }, 400);
    }

    const input = validateInput(body);
    if (typeof input === "string") {
      return jsonResponse({ error: input }, 400);
    }

    try {
      await initKuroshiro();
      // Map API mode to kuroshiro options
      // kuroshiro mode: "furigana" | "okurigana" | "normal" | "spaced"
      // kuroshiro to:   "hiragana" | "katakana" | "romaji"
      const kuroshiroMode = input.mode === "romaji" ? "spaced" : input.mode;
      const kuroshiroTo = input.mode === "romaji" ? "romaji" : input.to;
      const result = await kuroshiro!.convert(input.text, {
        mode: kuroshiroMode,
        to: kuroshiroTo,
        romajiSystem: "passport",
      });
      return jsonResponse({ result });
    } catch (err) {
      const message = err instanceof Error ? err.message : "Internal error";
      return jsonResponse({ error: message }, 500);
    }
  },
};
