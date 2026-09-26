import assert from "node:assert/strict";
import test from "node:test";
import {
  extractJsonObject,
  normalizeDailyReport,
  reportCacheKey,
} from "../lib/deepseek.mjs";

test("extracts JSON from DeepSeek markdown response", () => {
  const parsed = extractJsonObject('```json\n{"title":"测试","advice":"保持稳定"}\n```');
  assert.equal(parsed?.title, "测试");
  assert.equal(parsed?.advice, "保持稳定");
});

test("normalizes daily report fields", () => {
  const report = normalizeDailyReport({
    title: "本周总结",
    rhythm: "训练稳定",
    nutrition: "蛋白质不足",
    advice: "增加休息",
  });
  assert.equal(report.title, "本周总结");
  assert.equal(report.rhythm, "训练稳定");
  assert.ok(report.generatedAt);
});

test("creates stable report cache key", () => {
  const key = reportCacheKey({ days: 30, totalWorkout: 3 });
  assert.equal(key, reportCacheKey({ days: 30, totalWorkout: 3 }));
});
