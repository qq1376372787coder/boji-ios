import SwiftUI

struct PlanFlowView: View {
    enum Mode: String, CaseIterable, Identifiable {
        case generate
        case importText
        case free

        var id: String { rawValue }

        var title: String {
            switch self {
            case .generate: return "AI 生成"
            case .importText: return "导入计划"
            case .free: return "自由训练"
            }
        }
    }

    let initialMode: Mode

    @Environment(\.dismiss) private var dismiss
    @State private var mode: Mode
    @State private var importText = ""
    @State private var response: PlanGenerationResponse?
    @State private var loading = false
    @State private var saving = false
    @State private var savedMessage: String?
    @State private var errorMessage: String?

    private let service = PlanService()

    init(initialMode: Mode) {
        self.initialMode = initialMode
        _mode = State(initialValue: initialMode)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    Picker("方式", selection: $mode) {
                        ForEach(Mode.allCases) { item in
                            Text(item.title).tag(item)
                        }
                    }
                    .pickerStyle(.segmented)

                    switch mode {
                    case .generate:
                        generateSection
                    case .importText:
                        importSection
                    case .free:
                        freeSection
                    }

                    if let response {
                        planPreview(response)
                    }

                    if let savedMessage {
                        Text(savedMessage)
                            .font(.footnote)
                            .foregroundStyle(.green)
                    }

                    if let errorMessage {
                        Text(errorMessage)
                            .font(.footnote)
                            .foregroundStyle(.red)
                    }
                }
                .padding(18)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("训练计划")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("关闭") { dismiss() }
                }
            }
        }
    }

    private var generateSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("AI 会根据你的身体情况、目标、场地、器械和训练时间生成计划。")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Button {
                Task { await generate() }
            } label: {
                Group {
                    if loading {
                        ProgressView()
                    } else {
                        Label("生成训练计划", systemImage: "sparkles")
                            .font(.headline)
                    }
                }
                .frame(maxWidth: .infinity, minHeight: 50)
            }
            .buttonStyle(.borderedProminent)
            .disabled(loading)
        }
    }

    private var importSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("粘贴你的训练计划。AI 只整理格式，不会擅自删除你的动作。")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            TextEditor(text: $importText)
                .frame(minHeight: 180)
                .padding(12)
                .background(.background, in: RoundedRectangle(cornerRadius: 16))

            Button {
                Task { await importPlan() }
            } label: {
                Group {
                    if loading {
                        ProgressView()
                    } else {
                        Text("识别并整理计划")
                            .font(.headline)
                    }
                }
                .frame(maxWidth: .infinity, minHeight: 50)
            }
            .buttonStyle(.borderedProminent)
            .disabled(importText.trimmingCharacters(in: .whitespacesAndNewlines).count < 4 || loading)
        }
    }

    private var freeSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label("自由训练", systemImage: "figure.strengthtraining.traditional")
                .font(.title3.bold())

            Text("不设置固定计划，直接从今天开始记录训练。后续可以随时生成或导入计划。")
                .foregroundStyle(.secondary)

            Button("开始自由训练") {
                savedMessage = "自由训练模式已准备好。"
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.background, in: RoundedRectangle(cornerRadius: 18))
    }

    private func planPreview(_ response: PlanGenerationResponse) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(response.summary)
                .font(.headline)

            ForEach(response.plans) { plan in
                VStack(alignment: .leading, spacing: 10) {
                    Text(plan.name)
                        .font(.headline)
                    if !plan.note.isEmpty {
                        Text(plan.note)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    ForEach(plan.exercises) { exercise in
                        HStack {
                            Text(exercise.name)
                            Spacer()
                            Text("\(exercise.sets) 组 × \(exercise.reps)")
                                .foregroundStyle(.secondary)
                        }
                        .font(.subheadline)
                    }
                }
                .padding(16)
                .background(.background, in: RoundedRectangle(cornerRadius: 16))
            }

            Button {
                Task { await save(response.plans) }
            } label: {
                Group {
                    if saving {
                        ProgressView()
                    } else {
                        Text("确认保存为正式计划")
                            .font(.headline)
                    }
                }
                .frame(maxWidth: .infinity, minHeight: 50)
            }
            .buttonStyle(.borderedProminent)
            .disabled(saving)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.accentColor.opacity(0.06), in: RoundedRectangle(cornerRadius: 20))
    }

    private func generate() async {
        loading = true
        errorMessage = nil
        savedMessage = nil
        do {
            response = try await service.generate()
        } catch {
            errorMessage = error.localizedDescription
        }
        loading = false
    }

    private func importPlan() async {
        loading = true
        errorMessage = nil
        savedMessage = nil
        do {
            response = try await service.importText(importText)
            if response?.plans.isEmpty == true {
                errorMessage = "没有识别出训练动作，请把动作、组数和次数写清楚一些。"
            }
        } catch {
            errorMessage = error.localizedDescription
        }
        loading = false
    }

    private func save(_ plans: [LegacyPlan]) async {
        saving = true
        errorMessage = nil
        do {
            let version = try await service.save(plans)
            savedMessage = "计划已保存为 v\(version.version)。"
        } catch {
            errorMessage = error.localizedDescription
        }
        saving = false
    }
}
