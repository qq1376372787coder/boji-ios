import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject private var session: SessionStore
    @State private var gender = "male"
    @State private var age = 25
    @State private var height = 175.0
    @State private var weight = 70.0
    @State private var experience = "beginner"
    @State private var environment = "home"
    @State private var equipment = Set<String>()
    @State private var daysPerWeek = 3
    @State private var sessionMinutes = 45
    @State private var goal = "muscle_gain"
    @State private var limitations = ""
    @State private var submitting = false
    @State private var errorMessage: String?

    private let equipmentOptions = [
        ("bodyweight", "徒手"),
        ("mat", "瑜伽垫"),
        ("bands", "弹力带"),
        ("dumbbell", "哑铃"),
        ("barbell", "杠铃"),
        ("gym", "健身房器械")
    ]

    var body: some View {
        NavigationStack {
            Form {
                Section("身体情况") {
                    Picker("性别", selection: $gender) {
                        Text("男").tag("male")
                        Text("女").tag("female")
                        Text("不透露").tag("other")
                    }
                    Stepper("年龄：\(age) 岁", value: $age, in: 16...80)
                    Stepper(
                        "身高：\(height, specifier: "%.0f") cm",
                        value: $height,
                        in: 120...230,
                        step: 1
                    )
                    Stepper(
                        "体重：\(weight, specifier: "%.1f") kg",
                        value: $weight,
                        in: 30...250,
                        step: 0.5
                    )
                }

                Section("训练条件") {
                    Picker("训练经验", selection: $experience) {
                        Text("零基础").tag("beginner")
                        Text("入门").tag("novice")
                        Text("有经验").tag("intermediate")
                    }
                    Picker("训练场地", selection: $environment) {
                        Text("在家").tag("home")
                        Text("健身房").tag("gym")
                        Text("户外").tag("outdoor")
                    }

                    ForEach(equipmentOptions, id: \.0) { value, label in
                        Toggle(label, isOn: Binding(
                            get: { equipment.contains(value) },
                            set: { selected in
                                if selected {
                                    equipment.insert(value)
                                } else {
                                    equipment.remove(value)
                                }
                            }
                        ))
                    }

                    Stepper("每周训练 \(daysPerWeek) 天", value: $daysPerWeek, in: 2...6)
                    Stepper("每次 \(sessionMinutes) 分钟", value: $sessionMinutes, in: 20...90, step: 5)
                }

                Section("训练目标") {
                    Picker("目标", selection: $goal) {
                        Text("增肌").tag("muscle_gain")
                        Text("减脂").tag("fat_loss")
                        Text("增力").tag("strength")
                        Text("改善体态").tag("posture")
                        Text("保持健康").tag("fitness")
                    }
                    TextField("伤病、疼痛或动作限制（可选）", text: $limitations, axis: .vertical)
                        .lineLimit(2...5)
                }

                if let errorMessage {
                    Text(errorMessage)
                        .foregroundStyle(.red)
                }

                Section {
                    Button {
                        Task { await submit() }
                    } label: {
                        if submitting {
                            HStack {
                                ProgressView()
                                Text("正在保存资料…")
                            }
                        } else {
                            Text("保存并生成训练计划")
                                .font(.headline)
                        }
                    }
                    .disabled(equipment.isEmpty || submitting)
                }
            }
            .navigationTitle("建立训练档案")
        }
    }

    private func submit() async {
        submitting = true
        errorMessage = nil

        let payload = OnboardingPayload(
            gender: gender,
            age: age,
            heightCm: height,
            weightKg: weight,
            experience: experience,
            environment: environment,
            equipment: equipment.sorted(),
            daysPerWeek: daysPerWeek,
            sessionMinutes: sessionMinutes,
            goal: goal,
            limitations: limitations.trimmingCharacters(in: .whitespacesAndNewlines)
        )

        do {
            try await session.completeOnboarding(payload)
        } catch {
            errorMessage = error.localizedDescription
        }

        submitting = false
    }
}
