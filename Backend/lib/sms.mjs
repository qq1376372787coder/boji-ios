import {
  createHash,
  createHmac,
  randomInt,
  randomUUID,
  timingSafeEqual
} from "node:crypto";

export function normalizePhone(value) {
  const digits = String(value || "").replace(/\D/g, "");
  if (digits.startsWith("86") && digits.length === 13) return `+${digits}`;
  if (digits.length === 11) return `+86${digits}`;
  throw new Error("手机号格式不正确。");
}

export function hashSecret(value) {
  const pepper = process.env.SMS_PEPPER || process.env.SESSION_SECRET || "";
  return createHash("sha256").update(`${pepper}:${value}`).digest("hex");
}

export function createCode() {
  return String(randomInt(100000, 1000000));
}

export function verifyCodeHash(input, expectedHash) {
  const actual = Buffer.from(hashSecret(input));
  const expected = Buffer.from(String(expectedHash || ""));
  return actual.length === expected.length && timingSafeEqual(actual, expected);
}

export function codeExpiry() {
  return new Date(Date.now() + 5 * 60_000);
}

export async function sendSms(phone, code) {
  const provider = String(process.env.SMS_PROVIDER || "mock").toLowerCase();

  if (provider === "mock") {
    if (process.env.NODE_ENV === "production") {
      throw new Error("生产环境不允许使用 mock 短信服务。");
    }
    console.log(`[mock-sms] ${phone} -> ${code}`);
    return { provider, debugCode: code };
  }

  if (provider === "aliyun") {
    return sendAliyunSms(phone, code);
  }

  throw new Error("未支持的短信服务商。");
}

async function sendAliyunSms(phone, code) {
  const accessKeyId = requireEnv("SMS_ACCESS_KEY_ID");
  const accessKeySecret = requireEnv("SMS_ACCESS_KEY_SECRET");
  const signName = requireEnv("SMS_SIGN_NAME");
  const templateCode = requireEnv("SMS_TEMPLATE_CODE");
  const regionId = process.env.SMS_REGION_ID || "cn-hangzhou";

  const params = {
    AccessKeyId: accessKeyId,
    Action: "SendSms",
    Format: "JSON",
    PhoneNumbers: phone.replace(/^\+/, ""),
    RegionId: regionId,
    SignName: signName,
    SignatureMethod: "HMAC-SHA1",
    SignatureNonce: randomUUID(),
    SignatureVersion: "1.0",
    TemplateCode: templateCode,
    TemplateParam: JSON.stringify({ code }),
    Timestamp: new Date().toISOString().replace(/\.\d{3}Z$/, "Z"),
    Version: "2017-05-25"
  };

  const canonicalQuery = Object.keys(params)
    .sort()
    .map((key) => `${percentEncode(key)}=${percentEncode(params[key])}`)
    .join("&");

  const stringToSign = `GET&%2F&${percentEncode(canonicalQuery)}`;
  const signature = createHmac("sha1", `${accessKeySecret}&`)
    .update(stringToSign)
    .digest("base64");
  const query = `${canonicalQuery}&Signature=${percentEncode(signature)}`;

  const response = await fetch(`https://dysmsapi.aliyuncs.com/?${query}`, {
    method: "GET"
  });
  const result = await response.json().catch(() => ({}));

  if (!response.ok || result.Code !== "OK") {
    console.error("Aliyun SMS failed:", result);
    throw new Error("短信发送失败，请稍后重试。");
  }

  return { provider: "aliyun", requestId: result.RequestId };
}

function requireEnv(name) {
  const value = process.env[name];
  if (!value) throw new Error(`缺少短信服务配置：${name}`);
  return value;
}

function percentEncode(value) {
  return encodeURIComponent(String(value))
    .replace(/[!'()*]/g, (c) => `%${c.charCodeAt(0).toString(16).toUpperCase()}`)
    .replace(/%20/g, "+");
}
