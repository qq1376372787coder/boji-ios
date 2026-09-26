import { createHash } from "node:crypto";

const DEFAULT_MODEL = "deepseek-v4.1-flash";
const DEFAULT_URL = "https://api.deepseek.com/chat/completions";

export function aiConfigured() {
  return Boolean(process.env.DEEPSEEK_API_KEY);
}

export function aiModel() {
  return process.env.DEEPSEEK_MODEL || DEFAULT_MODEL;
}

export function extractJsonObject(text) {
  const raw = String(text || "")
    .replace(/^```(?:json)?\s*/i, "")
    .replace(/```\s*$/i, "")
    .trim();
  const start = raw.indexOf("{");
  const end = raw.lastIndexOf("}");
  if (start < 0 || end <= start) return null;
  try {
    return JSON.parse(raw.slice(start, end + 1));
  } catch {
    return null;
  }
}

export async function callDeepSeek(messages, options = {}) {
  if (!aiConfigured()) {
    const error = new Error("DeepSeek API 尚未配置。");
    error.status = 503;
    throw error;
  }

  const controller = new AbortController();
  const timeout = setTimeout(() => controller.abort(), options.timeoutMs ?? 30000);

  try {
    const response = await fetch(options.url || DEFAULT_URL, {
      method: "POST",
      headers: {
        "content-type": "application/json",
        authorization: `Bearer ${process.env.DEEPSEEK_API_KEY}`,
      },
      body: JSON.stringify({
        model: aiModel(),
        messages,
        temperature: options.temperature ?? 0.3,
        response_format: options.responseFormat || { type: "json_object" },
      }),
      signal: controller.signal,
    });

    const payload = await response.json().catch(() => ({}));
    if (!response.ok) {
      const message = payload?.error?.message || `DeepSeek 请求失败：${response.status}`;
      const error = new Error(message);
      error.status = response.status >= 500 ? 502 : 400;
      throw error;
    }

    const content = payload?.choices?.[0]?.message?.content || "";
    return {
      ok: true,
      content,
      json: extractJsonObject(content),
      model: payload?.model || aiModel(),
      usage: payload?.usage || null,
    };
  } catch (error) {
    if (error.name === "AbortError") {
      const timeoutError = new Error("AI 请求超时，请稍后重试。");
      timeoutError.status = 504;
      throw timeoutError;
    }
    throw error;
  } finally {
    clearTimeout(timeout);
  }
}

export function normalizeDailyReport(raw) {
  const title = String(raw?.title || "").trim().slice(0, 80);
  const rhythm = String(raw?.rhythm || "").trim().slice(0, 800);
  const nutrition = String(raw?.nutrition || "").trim().slice(0, 800);
  const advice = String(raw?.advice || "").trim().slice(0, 800);
  return {
    title: title || "最近 30 天总结",
    rhythm,
    nutrition,
    advice,
    generatedAt: new Date().toISOString(),
  };
}

export function reportCacheKey(input) {
  return createHash("sha256").update(JSON.stringify(input)).digest("hex");
}
