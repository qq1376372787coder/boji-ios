import { body, json, ApiError } from "../lib/http.mjs";
import { currentMember } from "../lib/passport.mjs";
import {
  aiConfigured,
  callDeepSeek,
  normalizeDailyReport,
} from "../lib/deepseek.mjs";

export function registerFlutterAiRoutes(on) {
  on("POST", "/api/ai/summary", async (req, res) => {
    const member = await currentMember(req);
    if (!member) throw new ApiError(401, "请先登录。");

    const data = await body(req);
    const days = Math.max(1, Math.min(90, Number(data.days) || 30));
    const prompt = [
      {
        role: "system",
        content:
          "你是健身教练。只返回 JSON，不要返回 Markdown。输出结构：{\"title\":\"...\",\"rhythm\":\"...\",\"nutrition\":\"...\",\"advice\":\"...\"}。不要诊断疾病，不要给出药物、极端节食或医疗建议。",
      },
      {
        role: "user",
        content: JSON.stringify({
          days,
          totalWorkout: data.totalWorkout ?? null,
          totalSets: data.totalSets ?? null,
          totalKcal: data.totalKcal ?? null,
          streak: data.streak ?? null,
        }),
      },
    ];

    if (!aiConfigured()) {
      return json(res, 200, {
        text: "AI 服务尚未配置，当前显示示例日报。",
        parsed: normalizeDailyReport({
          title: "最近 30 天总结",
          rhythm: "训练节奏稳定，建议继续保持每周 3 次的频率。",
          nutrition: "今天记录的饮食还比较少，训练后记得补充蛋白质。",
          advice: "下一阶段优先保证动作质量，再逐步增加训练容量。",
        }),
      });
    }

    const result = await callDeepSeek(prompt);
    const parsed = normalizeDailyReport(result.json || {});
    return json(res, 200, {
      text: result.content,
      parsed,
      model: result.model,
      usage: result.usage,
    });
  });
}
