-- 薄肌俱乐部 iOS / 手机登录 / Apple 会员迁移
ALTER TABLE users
  ADD COLUMN phone_e164 VARCHAR(24) NULL,
  ADD COLUMN phone_verified_at DATETIME NULL,
  ADD COLUMN last_login_at DATETIME NULL,
  ADD UNIQUE KEY uniq_users_phone_e164 (phone_e164);

CREATE TABLE IF NOT EXISTS sms_codes (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  phone_hash CHAR(64) NOT NULL,
  code_hash CHAR(64) NOT NULL,
  purpose VARCHAR(32) NOT NULL DEFAULT 'login',
  expires_at DATETIME NOT NULL,
  attempt_count TINYINT UNSIGNED NOT NULL DEFAULT 0,
  consumed_at DATETIME NULL,
  created_ip_hash CHAR(64) NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  KEY idx_sms_codes_phone_created (phone_hash, created_at),
  KEY idx_sms_codes_expires (expires_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

CREATE TABLE IF NOT EXISTS memberships (
  user_id INT NOT NULL,
  product_id VARCHAR(128) NOT NULL,
  status VARCHAR(24) NOT NULL DEFAULT 'active',
  started_at DATETIME NOT NULL,
  expires_at DATETIME NOT NULL,
  original_transaction_id VARCHAR(128) NOT NULL,
  latest_transaction_id VARCHAR(128) NOT NULL,
  environment VARCHAR(24) NOT NULL,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (user_id),
  UNIQUE KEY uniq_memberships_transaction (original_transaction_id),
  KEY idx_memberships_expires (expires_at),
  CONSTRAINT fk_memberships_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

CREATE TABLE IF NOT EXISTS apple_transactions (
  transaction_id VARCHAR(128) NOT NULL,
  original_transaction_id VARCHAR(128) NOT NULL,
  user_id INT NOT NULL,
  product_id VARCHAR(128) NOT NULL,
  environment VARCHAR(24) NOT NULL,
  purchase_date DATETIME NULL,
  expires_date DATETIME NULL,
  revocation_date DATETIME NULL,
  verified_payload_hash CHAR(64) NOT NULL,
  raw_transaction_json LONGTEXT NOT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (transaction_id),
  KEY idx_apple_transactions_user (user_id, created_at),
  KEY idx_apple_transactions_original (original_transaction_id),
  CONSTRAINT fk_apple_transactions_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

CREATE TABLE IF NOT EXISTS devices (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  user_id INT NOT NULL,
  device_id CHAR(36) NOT NULL,
  platform VARCHAR(24) NOT NULL DEFAULT 'ios',
  apns_token VARCHAR(255) NOT NULL,
  environment VARCHAR(24) NOT NULL DEFAULT 'production',
  app_version VARCHAR(32) NULL,
  push_enabled TINYINT(1) NOT NULL DEFAULT 1,
  last_seen_at DATETIME NOT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uniq_devices_token (apns_token),
  KEY idx_devices_user (user_id),
  CONSTRAINT fk_devices_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

CREATE TABLE IF NOT EXISTS privacy_consents (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  user_id INT NOT NULL,
  terms_version VARCHAR(24) NOT NULL,
  privacy_version VARCHAR(24) NOT NULL,
  consented_at DATETIME NOT NULL,
  source VARCHAR(24) NOT NULL DEFAULT 'ios',
  PRIMARY KEY (id),
  KEY idx_privacy_consents_user (user_id, consented_at),
  CONSTRAINT fk_privacy_consents_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

ALTER TABLE user_profile
  ADD COLUMN experience VARCHAR(24) NULL,
  ADD COLUMN equipment_json LONGTEXT NULL,
  ADD COLUMN session_minutes SMALLINT UNSIGNED NULL,
  ADD COLUMN limitations VARCHAR(500) NULL,
  ADD COLUMN onboarding_payload_json LONGTEXT NULL;
