import Foundation

protocol PlanServiceProtocol: Sendable {
    func generate() async throws -> PlanGenerationResponse
    func importText(_ text: String) async throws -> PlanGenerationResponse
    func save(_ plans: [LegacyPlan]) async throws -> SavedPlanVersion
}

struct PlanService: PlanServiceProtocol {
    private let api: APIClientProtocol

    init(api: APIClientProtocol = APIClient.shared) {
        self.api = api
    }

    func generate() async throws -> PlanGenerationResponse {
        try await api.sendAuthorized(
            Endpoint("/api/plan/generate", method: .post, body: EmptyPayload())
        )
    }

    func importText(_ text: String) async throws -> PlanGenerationResponse {
        struct Payload: Encodable, Sendable {
            let text: String
        }
        return try await api.sendAuthorized(
            Endpoint("/api/plan/import", method: .post, body: Payload(text: text))
        )
    }

    func save(_ plans: [LegacyPlan]) async throws -> SavedPlanVersion {
        let response: SavePlanResponse = try await api.sendAuthorized(
            Endpoint(
                "/api/plan/version",
                method: .post,
                body: SavePlanRequest(member: "me", plans: plans)
            )
        )
        return response.version
    }
}

private struct EmptyPayload: Encodable, Sendable {}
