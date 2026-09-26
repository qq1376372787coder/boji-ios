import { createHash, randomBytes } from "node:crypto";
import { query, withTransaction } from "../lib/db.mjs";
import {
  ApiError,
  badRequest,
  body,
  clientIp,
  json
} from "../lib/http.mjs";
import {
  codeExpiry,
  createCode,
  hashSecret,
  normalizePhone,
  sendSms,
  verifyCodeHash
} from "../lib/sms.mjs";
import { createSession, currentMember } from "../lib/passport.mjs";
import {
  decodeJwsPayload,
  processAppleNotification,
  verifyAppleTransaction
} from "../lib/apple.mjs";

const ACTIVE_MEMBERSHIP_SQL = `
  SELECT * FROM memberships
   WHERE user_id=? AND status='active' AND expires_at>NOW()
   ORDER BY expires_at DESC LIMIT 1
`;

export function registerMobileRoutes(on) {
  on("POST", "/api/auth/sms/send", async (req, res) => {
    const data = await body(req);
    const phone = normalizePhone(data.phone);
    const purpose = String(data.purpose || "login").slice(0, 32);
    const phoneHash = hashSecret(phone);

    const recent = await query(
      "SELECT created_at FROM sms_codes WHERE phone_hash=? ORDER BY created_at DESC LIMIT 1",
      [phoneHash]
    );
    if (recent.length && Date.now() - new Date(recent[0].created_at).getTime() < 60_000) {
      throw new ApiError(429, "验证码发送太频繁，请 1 分钟后再试。");
    }

    const code = createCode();
    await query(
      `INSERT INTO sms_codes
         (phone_hash, code_hash, purpose, expires_at, created_ip_hash)
       VALUES (?,?,?,?,?)`,
      [
        phoneHash,
        hashSecret(code),
        purpose,
        codeExpiry(),
        hashSecret(clientIp(req))
      ]
    );

    const sent = await sendSms(phone, code);
    return json(res, 200, {
      ok: true,
      retry_after: 60,
      ...(process.env.NODE_ENV === "production" ? {} : { debug_code: sent.debugCode })
    });
  }, "auth");

  on("POST", "/api/auth/sms/verify", async (req, res) => {
    const data = await body(req);
    const phone = normalizePhone(data.phone);
    const inputCode = String(data.code || "").replace(/\D/g, "");
    const purpose = String(data.purpose || "login").slice(0, 32);
    const phoneHash = hashSecret(phone);

    if (inputCode.length !== 6) throw badRequest("验证码不正确。");

    const rows = await query(
      `SELECT * FROM sms_codes
        WHERE phone_hash=? AND purpose=? AND consumed_at IS NULL AND expires_at>NOW()
        ORDER BY created_at DESC LIMIT 1`,
      [phoneHash, purpose]
    );

    const record = rows[0];
    if (!record) throw new ApiError(400, "验证码已失效，请重新获取。");
    if (Number(record.attempt_count) >= 5) {
      throw new ApiError(429, "验证码尝试次数过多，请重新获取。");
    }

    if (!verifyCodeHash(inputCode, record.code_hash)) {
      await query("UPDATE sms_codes SET attempt_count=attempt_count+1 WHERE id=?", [
        record.id
      ]);
      throw new ApiError(400, "验证码不正确。");
    }

    await query("UPDATE sms_codes SET consumed_at=NOW() WHERE id=?", [record.id]);

    const result = await withTransaction(async (conn) => {
      const users = await conn.query(
        "SELECT id, username FROM users WHERE phone_e164=? LIMIT 1",
        [phone]
      );

      let user = users[0];
      if (!user) {
        const suffix = createHash("sha256").update(phone).digest("hex").slice(0, 10);
        const username = `ios_${suffix}`;
        const inserted = await conn.query(
          `INSERT INTO users
             (username, password_hash, phone_e164, phone_verified_at, member_tier, source, status)
           VALUES (?, ?, ?, NOW(), 'member', 'ios_sms', 'active')`,
          [username, `phone-otp:${randomBytes(24).toString("hex")}`, phone]
        );
        const userId = Number(inserted.insertId);
        await conn.query(
          "INSERT INTO user_profile (user_id, member, display_name) VALUES (?, 'me', ?)",
          [userId, `用户${String(userId).slice(-4)}`]
        );
        user = { id: userId, username };
      } else {
        await conn.query(
          "UPDATE users SET phone_verified_at=NOW(), last_login_at=NOW(), status='active' WHERE id=?",
          [user.id]
        );
      }

      return Number(user.id);
    });

    const token = await createSession(result);
    const profile = await currentMember({
      headers: { authorization: `Bearer ${token}` }
    });
    const membership = await membershipForUser(result);

    return json(res, 200, {
      access_token: token,
      refresh_token: token,
      user: publicUser(profile, membership, phone)
    });
  }, "auth");

  on("GET", "/api/me", async (req, res) => {
    const profile = await requireMobileUser(req);
    const membership = await membershipForUser(profile.user_id);
    return json(res, 200, publicUser(profile, membership, await phoneForUser(profile.user_id)));
  });

  on("POST", "/api/onboarding", async (req, res) => {
    const profile = await requireMobileUser(req);
    const data = await body(req);

    const age = boundedInt(data.age, 16, 80);
    const heightCm = boundedNumber(data.height_cm, 120, 230);
    const weightKg = boundedNumber(data.weight_kg, 30, 250);
    const daysPerWeek = boundedInt(data.days_per_week, 2, 6);
    const sessionMinutes = boundedInt(data.session_minutes, 20, 120);
    const gender = enumValue(data.gender, ["male", "female", "other"], "other");
    const experience = enumValue(
      data.experience,
      ["beginner", "novice", "intermediate", "advanced"],
      "beginner"
    );
    const environment = enumValue(
      data.environment,
      ["home", "gym", "outdoor"],
      "home"
    );
    const goal = enumValue(
      data.goal,
      ["muscle_gain", "fat_loss", "strength", "posture", "fitness"],
      "fitness"
    );
    const equipment = Array.isArray(data.equipment)
      ? data.equipment.map((v) => String(v).slice(0, 32)).slice(0, 20)
      : [];
    const limitations = String(data.limitations || "").trim().slice(0, 500);

    if (!age || !heightCm || !weightKg || !daysPerWeek || !sessionMinutes) {
      throw badRequest("训练资料不完整。");
    }

    await query(
      `UPDATE user_profile
          SET gender=?, age=?, height_cm=?, weight_kg=?, experience=?,
              train_env=?, equipment_json=?, days_per_week=?, session_minutes=?,
              goal=?, limitations=?, onboarding_payload_json=?, onboarded=1
        WHERE user_id=?`,
      [
        gender,
        age,
        heightCm,
        weightKg,
        experience,
        environment,
        JSON.stringify(equipment),
        daysPerWeek,
        sessionMinutes,
        goal,
        limitations,
        JSON.stringify(data),
        profile.user_id
      ]
    );

    const updated = await requireMobileUser(req);
    const membership = await membershipForUser(profile.user_id);
    return json(res, 200, publicUser(updated, membership, await phoneForUser(profile.user_id)));
  });

  on("POST", "/api/auth/logout", async (req, res) => {
    const header = String(req.headers.authorization || "");
    const token = header.startsWith("Bearer ") ? header.slice(7) : "";
    if (token) await query("DELETE FROM sessions WHERE token=?", [token]);
    return json(res, 200, { ok: true });
  });

  on("POST", "/api/push-token", async (req, res) => {
    const profile = await requireMobileUser(req);
    const data = await body(req);
    const token = String(data.token || "").trim();
    if (!/^[a-fA-F0-9]{32,255}$/.test(token)) throw badRequest("推送 Token 不正确。");

    const deviceId = createHash("sha256").update(token).digest("hex").slice(0, 36);
    await query(
      `INSERT INTO devices
         (user_id, device_id, platform, apns_token, environment, app_version, last_seen_at)
       VALUES (?,?,?,?,?,?,NOW())
       ON DUPLICATE KEY UPDATE
         user_id=VALUES(user_id),
         environment=VALUES(environment),
         app_version=VALUES(app_version),
         push_enabled=1,
         last_seen_at=NOW()`,
      [
        profile.user_id,
        deviceId,
        "ios",
        token,
        data.environment === "sandbox" ? "sandbox" : "production",
        String(data.app_version || "").slice(0, 32)
      ]
    );

    return json(res, 200, { ok: true });
  });

  on("POST", "/api/billing/apple/verify", async (req, res) => {
    const profile = await requireMobileUser(req);
    const data = await body(req);
    const transaction = await verifyAppleTransaction(data.transaction_jws);

    await saveVerifiedTransaction(profile.user_id, transaction);
    const membership = await membershipForUser(profile.user_id);

    return json(res, 200, {
      ok: true,
      membership: publicMembership(membership)
    });
  });

  on("POST", "/api/billing/apple/webhook", async (req, res) => {
    const data = await body(req);
    const signedPayload = String(data.signedPayload || data.signed_payload || "");
    if (!signedPayload) throw badRequest("缺少 signedPayload。");

    const result = await processAppleNotification(signedPayload);
    if (result.handled) {
      const previous = await query(
        `SELECT user_id FROM apple_transactions
          WHERE original_transaction_id=? ORDER BY created_at DESC LIMIT 1`,
        [result.transaction.originalTransactionId]
      );
      if (previous.length) {
        await saveVerifiedTransaction(Number(previous[0].user_id), result.transaction);
      }
    }

    return json(res, 200, { ok: true });
  });
}

async function requireMobileUser(req) {
  const profile = await currentMember(req);
  if (!profile) throw new ApiError(401, "请先登录。");
  return profile;
}

async function membershipForUser(userId) {
  const rows = await query(ACTIVE_MEMBERSHIP_SQL, [userId]);
  return rows[0] || null;
}

async function saveVerifiedTransaction(userId, transaction) {
  await withTransaction(async (conn) => {
    await conn.query(
      `INSERT INTO apple_transactions
         (transaction_id, original_transaction_id, user_id, product_id, environment,
          purchase_date, expires_date, revocation_date, verified_payload_hash,
          raw_transaction_json)
       VALUES (?,?,?,?,?,?,?,?,?,?)
       ON DUPLICATE KEY UPDATE
         original_transaction_id=VALUES(original_transaction_id),
         product_id=VALUES(product_id),
         environment=VALUES(environment),
         purchase_date=VALUES(purchase_date),
         expires_date=VALUES(expires_date),
         revocation_date=VALUES(revocation_date),
         verified_payload_hash=VALUES(verified_payload_hash),
         raw_transaction_json=VALUES(raw_transaction_json)`,
      [
        transaction.transactionId,
        transaction.originalTransactionId,
        userId,
        transaction.productId,
        transaction.environment,
        transaction.purchaseDate,
        transaction.expiresDate,
        transaction.revocationDate,
        transaction.rawHash,
        transaction.rawTransaction
      ]
    );

    await conn.query(
      `INSERT INTO memberships
         (user_id, product_id, status, started_at, expires_at,
          original_transaction_id, latest_transaction_id, environment)
       VALUES (?,?,?,?,?,?,?,?)
       ON DUPLICATE KEY UPDATE
         product_id=VALUES(product_id),
         status=VALUES(status),
         expires_at=VALUES(expires_at),
         latest_transaction_id=VALUES(latest_transaction_id),
         environment=VALUES(environment)`,
      [
        userId,
        transaction.productId,
        "active",
        transaction.purchaseDate || new Date(),
        transaction.expiresDate,
        transaction.originalTransactionId,
        transaction.transactionId,
        transaction.environment
      ]
    );
  });
}

async function phoneForUser(userId) {
  const rows = await query("SELECT phone_e164 FROM users WHERE id=? LIMIT 1", [userId]);
  return rows[0]?.phone_e164 || "";
}

function publicUser(profile, membership, phone = "") {
  return {
    id: Number(profile.user_id),
    phone: maskPhone(phone),
    display_name: profile.display_name || "",
    onboarded: Boolean(Number(profile.onboarded || 0)),
    membership: publicMembership(membership)
  };
}

function publicMembership(membership) {
  return {
    active: Boolean(membership && new Date(membership.expires_at).getTime() > Date.now()),
    status: membership?.status || "none",
    expires_at: membership?.expires_at || null
  };
}

function maskPhone(phone) {
  const text = String(phone || "");
  if (text.length < 7) return text;
  return `${text.slice(0, 3)}****${text.slice(-4)}`;
}

function boundedInt(value, min, max) {
  const n = Math.round(Number(value));
  return Number.isFinite(n) && n >= min && n <= max ? n : null;
}

function boundedNumber(value, min, max) {
  const n = Number(value);
  return Number.isFinite(n) && n >= min && n <= max ? n : null;
}

function enumValue(value, allowed, fallback) {
  const text = String(value || "").toLowerCase();
  return allowed.includes(text) ? text : fallback;
}



