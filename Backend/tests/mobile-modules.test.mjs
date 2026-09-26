import assert from "node:assert/strict";
import test from "node:test";
import {
  createCode,
  hashSecret,
  normalizePhone,
  verifyCodeHash
} from "../lib/sms.mjs";
import {
  decodeJwsPayload,
  verifyAppleTransaction
} from "../lib/apple.mjs";

function jws(payload) {
  const encode = (value) =>
    Buffer.from(JSON.stringify(value), "utf8").toString("base64url");
  return `${encode({ alg: "ES256" })}.${encode(payload)}.test-signature`;
}

test("normalizePhone accepts mainland mobile numbers", () => {
  assert.equal(normalizePhone("13800138000"), "+8613800138000");
  assert.equal(normalizePhone("+86 138 0013 8000"), "+8613800138000");
});

test("normalizePhone rejects invalid phone numbers", () => {
  assert.throws(() => normalizePhone("123"));
});

test("SMS code hash verifies safely", () => {
  const code = createCode();
  assert.match(code, /^\d{6}$/);
  const hash = hashSecret(code);
  assert.equal(verifyCodeHash(code, hash), true);
  assert.equal(verifyCodeHash("000000", hash), code === "000000");
});

test("decodeJwsPayload decodes Apple payload", () => {
  const payload = decodeJwsPayload(jws({ transactionId: "100", productId: "p1" }));
  assert.equal(payload.transactionId, "100");
  assert.equal(payload.productId, "p1");
});

test("mock Apple transaction is validated", async () => {
  process.env.APPLE_VERIFICATION_MODE = "mock";
  process.env.APPLE_BUNDLE_ID = "cloud.gongxiang.boji";
  process.env.APPLE_PRODUCT_ID = "cloud.gongxiang.boji.annual12";

  const expiresDate = Date.now() + 24 * 60 * 60 * 1000;
  const transaction = await verifyAppleTransaction(jws({
    transactionId: "200",
    originalTransactionId: "100",
    bundleId: "cloud.gongxiang.boji",
    productId: "cloud.gongxiang.boji.annual12",
    environment: "Sandbox",
    purchaseDate: Date.now(),
    expiresDate
  }));

  assert.equal(transaction.transactionId, "200");
  assert.equal(transaction.originalTransactionId, "100");
  assert.equal(transaction.productId, "cloud.gongxiang.boji.annual12");
});
