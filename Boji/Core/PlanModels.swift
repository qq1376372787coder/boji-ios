import Foundation

struct PlanGenerationResponse: Codable, Sendable {
    let summary: String
    let plans: [LegacyPlan]
}

struct LegacyPlan: Codable, Identifiable, Sendable {
    let id: UUID
    let name: String
    let note: String
    let exercises: [LegacyExercise]

    enum CodingKeys: String, CodingKey {
        case name
        case note
        case exercises
    }

    init(name: String, note: String, exercises: [LegacyExercise]) {
        self.id = UUID()
        self.name = name
        self.note = note
        self.exercises = exercises
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = UUID()
        self.name = try container.decode(String.self, forKey: .name)
        self.note = try container.decodeIfPresent(String.self, forKey: .note) ?? ""
        self.exercises = try container.decode([LegacyExercise].self, forKey: .exercises)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name, forKey: .name)
        try container.encode(note, forKey: .note)
        try container.encode(exercises, forKey: .exercises)
    }
}

struct LegacyExercise: Codable, Identifiable, Sendable {
    let id: UUID
    let name: String
    let sets: Int
    let reps: String
    let type: String

    init(name: String, sets: Int, reps: String, type: String) {
        self.id = UUID()
        self.name = name
        self.sets = sets
        self.reps = reps
        self.type = type
    }

    init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        let name = try container.decode(String.self)
        let sets = try container.decode(Int.self)
        let reps = try container.decode(String.self)
        let type = try container.decodeIfPresent(String.self) ?? "weight"

        self.id = UUID()
        self.name = name
        self.sets = sets
        self.reps = reps
        self.type = type
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(name)
        try container.encode(sets)
        try container.encode(reps)
        try container.encode(type)
    }
}

struct SavePlanRequest: Codable, Sendable {
    let member: String
    let plans: [LegacyPlan]
}

struct SavePlanResponse: Codable, Sendable {
    let version: SavedPlanVersion
}

struct SavedPlanVersion: Codable, Sendable {
    let id: Int
    let version: Int
    let member: String
}
