import { createHash, createPrivateKey, sign } from "node:crypto";
import { readFileSync } from "node:fs";

const APPLE_API_AUDIENCE = "appstoreconnect-v1";

export function decodeJwsPayload(jws) {
  const raw = String(jws || "").trim();
  if (raw.startsWith("{")) return JSON.parse(raw);
  const parts = raw.split(".");
  if (parts.length !== 3) throw new Error("Apple JWS 格式不正确。");
  return JSON.parse(Buffer.from(parts[1], "base64url").toString("utf8"));
}

export async function verifyAppleTransaction(transactionJWS) {
  const decoded = decodeJwsPayload(transactionJWS);
  const transactionId = decoded.transactionId || decoded.transaction_id;
  if (!transactionId) throw new Error("Apple 交易缺少 transactionId。");

  if (process.env.APPLE_VERIFICATION_MODE === "mock") {
    return validateTransaction(decoded, transactionJWS);
  }

  const canonical = await fetchAppleTransaction(transactionId);
  return validateTransaction(canonical, JSON.stringify(canonical));
}

export async function verifyAppleTransactionById(transactionId) {
  if (process.env.APPLE_VERIFICATION_MODE === "mock") {
    throw new Error("mock 模式必须提供 signedTransactionInfo。");
  }
  const canonical = await fetchAppleTransaction(transactionId);
  return validateTransaction(canonical, JSON.stringify(canonical));
}

export async function fetchAppleTransaction(transactionId) {
  const response = await appleRequest(`/inApps/v1/transactions/${transactionId}`);
  const payload = await response.json().catch(() => ({}));
  if (!response.ok) {
    console.error("Apple transaction lookup failed:", payload);
    throw new Error("无法验证 Apple 交易。");
  }
  return payload.transactionInfo || payload;
}

export async function processAppleNotification(signedPayload) {
  const notification = decodeJwsPayload(signedPayload);
  const signedTransaction = notification?.data?.signedTransactionInfo;
  if (!signedTransaction) return { handled: false };

  const decodedTransaction = decodeJwsPayload(signedTransaction);
  const transactionId = decodedTransaction.transactionId || decodedTransaction.transaction_id;
  if (!transactionId) return { handled: false };

  const transaction =
    process.env.APPLE_VERIFICATION_MODE === "mock"
      ? validateTransaction(decodedTransaction, signedTransaction)
      : await verifyAppleTransactionById(transactionId);

  return { handled: true, transaction };
}

function validateTransaction(transaction, rawTransaction) {
  const bundleId = transaction.bundleId || transaction.bundle_id;
  const productId = transaction.productId || transaction.product_id;
  const transactionId = transaction.transactionId || transaction.transaction_id;
  const originalTransactionId =
    transaction.originalTransactionId || transaction.original_transaction_id;
  const expiresDate = parseAppleDate(
    transaction.expiresDate ?? transaction.expires_date
  );
  const revocationDate = parseAppleDate(
    transaction.revocationDate ?? transaction.revocation_date
  );

  if (bundleId !== requireEnv("APPLE_BUNDLE_ID")) {
    throw new Error("Apple 交易不属于当前 App。");
  }
  if (productId !== requireEnv("APPLE_PRODUCT_ID")) {
    throw new Error("Apple 交易商品不匹配。");
  }
  if (!transactionId || !originalTransactionId) {
    throw new Error("Apple 交易信息不完整。");
  }
  if (revocationDate) {
    throw new Error("该 Apple 交易已退款或被撤销。");
  }
  if (!expiresDate || expiresDate.getTime() <= Date.now()) {
    throw new Error("该 Apple 会员已过期。");
  }

  return {
    transactionId,
    originalTransactionId,
    productId,
    bundleId,
    environment: transaction.environment || "Production",
    purchaseDate: parseAppleDate(transaction.purchaseDate ?? transaction.purchase_date),
    expiresDate,
    revocationDate,
    rawTransaction,
    rawHash: createHash("sha256").update(rawTransaction).digest("hex")
  };
}

export async function appleRequest(path) {
  const token = createAppStoreConnectToken();
  const host =
    process.env.APPLE_ENVIRONMENT === "sandbox"
      ? "https://api.storekit-sandbox.itunes.apple.com"
      : "https://api.storekit.itunes.apple.com";

  return fetch(`${host}${path}`, {
    headers: {
      Authorization: `Bearer ${token}`,
      Accept: "application/json"
    }
  });
}

export function createAppStoreConnectToken() {
  const issuerId = requireEnv("APPLE_ISSUER_ID");
  const keyId = requireEnv("APPLE_KEY_ID");
  const privateKey = loadApplePrivateKey();

  const header = { alg: "ES256", kid: keyId, typ: "JWT" };
  const issuedAt = Math.floor(Date.now() / 1000);
  const payload = {
    iss: issuerId,
    iat: issuedAt,
    exp: issuedAt + 20 * 60,
    aud: APPLE_API_AUDIENCE,
    bid: requireEnv("APPLE_BUNDLE_ID")
  };

  const encodedHeader = base64url(JSON.stringify(header));
  const encodedPayload = base64url(JSON.stringify(payload));
  const signingInput = `${encodedHeader}.${encodedPayload}`;
  const signature = sign("sha256", Buffer.from(signingInput), {
    key: privateKey,
    dsaEncoding: "ieee-p1363"
  });

  return `${signingInput}.${base64url(signature)}`;
}

function loadApplePrivateKey() {
  const raw = process.env.APPLE_PRIVATE_KEY;
  const path = process.env.APPLE_PRIVATE_KEY_PATH;

  if (path) {
    return createPrivateKey(readFileSync(path, "utf8"));
  }
  if (!raw) {
    throw new Error("缺少 APPLE_PRIVATE_KEY 或 APPLE_PRIVATE_KEY_PATH。");
  }
  return createPrivateKey(raw.replace(/\\n/g, "\n"));
}

function parseAppleDate(value) {
  if (!value) return null;
  if (value instanceof Date) return value;
  const numeric = Number(value);
  if (Number.isFinite(numeric)) {
    return new Date(numeric > 10_000_000_000 ? numeric : numeric * 1000);
  }
  const date = new Date(value);
  return Number.isNaN(date.getTime()) ? null : date;
}

function requireEnv(name) {
  const value = process.env[name];
  if (!value) throw new Error(`缺少 Apple 配置：${name}`);
  return value;
}

function base64url(value) {
  const buffer = Buffer.isBuffer(value) ? value : Buffer.from(String(value), "utf8");
  return buffer.toString("base64url");
}


