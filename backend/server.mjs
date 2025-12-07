import http from "node:http";
import { readFileSync, existsSync } from "node:fs";
import { join, dirname } from "node:path";
import { fileURLToPath } from "node:url";

const __dirname = dirname(fileURLToPath(import.meta.url));
loadDotEnv(join(__dirname, ".env"));

const PORT = Number(process.env.PORT || 8787);
const OPENAI_API_KEY = process.env.OPENAI_API_KEY || "";
const OPENAI_MODEL = process.env.OPENAI_MODEL || "gpt-5.4-mini";
const OPENAI_MODERATION_MODEL = process.env.OPENAI_MODERATION_MODEL || "omni-moderation-latest";
const OPENAI_BASE_URL = process.env.OPENAI_BASE_URL || "https://api.openai.com/v1";
const OPENAI_REASONING_EFFORT = process.env.OPENAI_REASONING_EFFORT || "low";

const server = http.createServer(async (req, res) => {
  setCorsHeaders(res);

  if (req.method === "OPTIONS") {
    res.writeHead(204);
    res.end();
    return;
  }

  if (req.method === "GET" && req.url === "/health") {
    respondJson(res, 200, {
      ok: true,
      openaiConfigured: Boolean(OPENAI_API_KEY),
      model: OPENAI_MODEL,
    });
    return;
  }

  if (req.method === "POST" && req.url === "/api/ai/support-chat") {
    try {
      if (!OPENAI_API_KEY) {
        respondJson(res, 503, {
          error: "OPENAI_API_KEY non configurata nel backend.",
        });
        return;
      }

      const body = await readJsonBody(req);
      const message = String(body?.message || "").trim();

      if (!message) {
        respondJson(res, 400, { error: "Il campo `message` e obbligatorio." });
        return;
      }

      const moderation = await moderateMessage(message);
      if (moderation.flagged) {
        respondJson(res, 200, {
          reply:
            "Quello che hai scritto sembra piu serio di una normale fase di stress. Se senti che potresti farti del male o non sei al sicuro, contatta subito il 112 o una persona reale adesso. Non restare sola con questo peso.",
          model: OPENAI_MODERATION_MODEL,
          flagged: true,
        });
        return;
      }

      const prompt = buildUserPrompt(body);
      const reply = await generateSupportReply(prompt);

      respondJson(res, 200, {
        reply,
        model: OPENAI_MODEL,
        flagged: false,
      });
    } catch (error) {
      console.error("[support-chat] request failed", error);
      respondJson(res, 500, {
        error: "Errore interno del backend AI.",
      });
    }
    return;
  }

  respondJson(res, 404, { error: "Not found" });
});

server.listen(PORT, "127.0.0.1", () => {
  console.log(`[mindmesh-ai] listening on http://127.0.0.1:${PORT}`);
});

async function moderateMessage(message) {
  const response = await fetch(`${OPENAI_BASE_URL}/moderations`, {
    method: "POST",
    headers: openAIHeaders(),
    body: JSON.stringify({
      model: OPENAI_MODERATION_MODEL,
      input: message,
    }),
  });

  if (!response.ok) {
    throw new Error(`Moderation failed with status ${response.status}`);
  }

  const data = await response.json();
  const flagged = Boolean(data?.results?.some?.((item) => item.flagged));
  return { flagged };
}

async function generateSupportReply(prompt) {
  const response = await fetch(`${OPENAI_BASE_URL}/responses`, {
    method: "POST",
    headers: openAIHeaders(),
    body: JSON.stringify({
      model: OPENAI_MODEL,
      instructions: SYSTEM_INSTRUCTIONS,
      input: prompt,
      reasoning: { effort: OPENAI_REASONING_EFFORT },
      max_output_tokens: 420,
    }),
  });

  if (!response.ok) {
    const errorText = await response.text();
    throw new Error(`Responses API failed with status ${response.status}: ${errorText}`);
  }

  const data = await response.json();
  const reply = extractOutputText(data);

  if (!reply) {
    throw new Error("Responses API returned an empty reply");
  }

  return reply;
}

function buildUserPrompt(body) {
  const conversation = Array.isArray(body?.conversation) ? body.conversation.slice(-8) : [];
  const snapshot = body?.snapshot && typeof body.snapshot === "object" ? body.snapshot : null;

  const transcript = conversation
    .map((entry) => {
      const role = entry?.role === "assistant" ? "assistant" : "user";
      const text = String(entry?.text || "").trim();
      return text ? `${role}: ${text}` : null;
    })
    .filter(Boolean)
    .join("\n");

  const snapshotBlock = snapshot
    ? `Contesto app facoltativo:\n- sintesi: ${snapshot.title || ""}\n- andamento: ${snapshot.trendLabel || ""}\n- energia: ${snapshot.energyLabel || ""}\n`
    : "Contesto app facoltativo: non disponibile.\n";

  return `Conversazione recente:\n${transcript || "Nessuna."}\n\n${snapshotBlock}\nUltimo messaggio utente:\n${String(
    body?.message || "",
  ).trim()}\n\nRispondi in modo empatico, naturale, specifico e non meccanico.`;
}

function extractOutputText(data) {
  if (typeof data?.output_text === "string" && data.output_text.trim()) {
    return data.output_text.trim();
  }

  const parts = [];
  for (const item of data?.output || []) {
    for (const content of item?.content || []) {
      if (typeof content?.text === "string" && content.text.trim()) {
        parts.push(content.text.trim());
      }
    }
  }

  return parts.join("\n").trim();
}

function openAIHeaders() {
  return {
    "Content-Type": "application/json",
    Authorization: `Bearer ${OPENAI_API_KEY}`,
  };
}

function setCorsHeaders(res) {
  res.setHeader("Access-Control-Allow-Origin", "*");
  res.setHeader("Access-Control-Allow-Methods", "GET,POST,OPTIONS");
  res.setHeader("Access-Control-Allow-Headers", "Content-Type, Authorization");
}

function respondJson(res, statusCode, payload) {
  res.writeHead(statusCode, { "Content-Type": "application/json; charset=utf-8" });
  res.end(JSON.stringify(payload));
}

function readJsonBody(req) {
  return new Promise((resolve, reject) => {
    let raw = "";

    req.on("data", (chunk) => {
      raw += chunk;
      if (raw.length > 1_000_000) {
        reject(new Error("Payload too large"));
      }
    });

    req.on("end", () => {
      try {
        resolve(raw ? JSON.parse(raw) : {});
      } catch (error) {
        reject(error);
      }
    });

    req.on("error", reject);
  });
}

function loadDotEnv(pathname) {
  if (!existsSync(pathname)) {
    return;
  }

  const lines = readFileSync(pathname, "utf8").split(/\r?\n/);
  for (const line of lines) {
    const trimmed = line.trim();
    if (!trimmed || trimmed.startsWith("#")) {
      continue;
    }

    const separatorIndex = trimmed.indexOf("=");
    if (separatorIndex === -1) {
      continue;
    }

    const key = trimmed.slice(0, separatorIndex).trim();
    const value = trimmed.slice(separatorIndex + 1).trim().replace(/^['"]|['"]$/g, "");

    if (!(key in process.env)) {
      process.env[key] = value;
    }
  }
}

const SYSTEM_INSTRUCTIONS = `
Sei l'assistente premium di MindMesh.
Rispondi in italiano, con tono empatico, umano, caldo e concreto.
Non essere meccanico, non parlare come un template e non ripetere slogan.
Parti da quello che la persona ha appena scritto e usa il contesto dell'app solo se aiuta davvero.
Non fare diagnosi, non fingere competenze cliniche e non dire che sei un terapeuta.
Se emerge rischio imminente di autolesione o suicidio, interrompi il tono normale e indirizza subito verso emergenza o supporto umano immediato.
Fai risposte brevi o medie, naturali, con massimo un suggerimento pratico per volta.
`;
