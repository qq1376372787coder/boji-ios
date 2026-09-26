import Foundation

struct AuthResponse: Codable, Sendable {
    let accessToken: String
    let refreshToken: String
    let user: User
}

struct User: Codable, Identifiable, Sendable {
    let id: Int
    let phone: String
    let displayName: String?
    let onboarded: Bool
    let membership: Membership
}

struct Membership: Codable, Sendable {
    let active: Bool
    let status: String
    let expiresAt: Date?
}

struct SendCodeResponse: Codable, Sendable {
    let retryAfter: Int
}

struct SuccessResponse: Codable, Sendable {
    let ok: Bool
}

struct OnboardingPayload: Codable, Sendable {
    let gender: String
    let age: Int
    let heightCm: Double
    let weightKg: Double
    let experience: String
    let environment: String
    let equipment: [String]
    let daysPerWeek: Int
    let sessionMinutes: Int
    let goal: String
    let limitations: String?
}

struct PlanGenerationRequest: Codable, Sendable {
    let mode: String
    let sourceText: String?
    let onboarding: OnboardingPayload
}

struct AppleVerificationRequest: Codable, Sendable {
    let transactionJWS: String
    let environment: String

    enum CodingKeys: String, CodingKey {
        case transactionJWS = "transaction_jws"
        case environment
    }
}

struct RegisterPushRequest: Codable, Sendable {
    let token: String
    let environment: String
    let appVersion: String
}

