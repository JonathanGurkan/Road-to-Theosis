import SwiftUI

struct CheckInView: View {
    @Binding var backgroundTheme: AppBackgroundTheme
    let dashboard: DashboardViewModel
    let onSave: (LogEntry) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var selectedAnswerIndices: [Int?]
    @State private var stepIndex = 0

    private let questions = CheckInQuestionnaire.questions

    init(
        backgroundTheme: Binding<AppBackgroundTheme>,
        dashboard: DashboardViewModel,
        onSave: @escaping (LogEntry) -> Void
    ) {
        self._backgroundTheme = backgroundTheme
        self.dashboard = dashboard
        self.onSave = onSave
        self._selectedAnswerIndices = State(initialValue: Array(repeating: nil, count: CheckInQuestionnaire.questions.count))
    }

    private var currentQuestion: CheckInQuestion {
        questions[stepIndex]
    }

    private var currentSelection: Int? {
        guard selectedAnswerIndices.indices.contains(stepIndex) else { return nil }
        return selectedAnswerIndices[stepIndex]
    }

    private var currentProgressLabel: String {
        CheckInQuestionnaire.progressLabel(for: currentQuestion, sections: dashboard.sections)
    }

    private var completionCount: Int {
        selectedAnswerIndices.compactMap { $0 }.count
    }

    private var isLastQuestion: Bool {
        stepIndex == questions.count - 1
    }

    private var canAdvance: Bool {
        currentSelection != nil
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackgroundView(theme: backgroundTheme)

                LinearGradient(
                    colors: [
                        Color.black.opacity(0.10),
                        Color.clear,
                        Color.orange.opacity(0.08)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 16) {
                        headerCard
                        progressRail
                        questionCard
                        answerCard
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                    .padding(.bottom, 24)
                }
            }
            .navigationTitle("Check-in")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .safeAreaInset(edge: .bottom) {
                footerBar
            }
        }
    }

    private var headerCard: some View {
        AppSurfaceCard(contentPadding: 16) {
            VStack(alignment: .leading, spacing: 10) {
                Text("Whole-life recalibration")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)

                Text("Answer honestly and the meter updates right away.")
                    .font(.title.weight(.semibold))
                    .foregroundStyle(.primary)
                    .fixedSize(horizontal: false, vertical: true)

                Text("This is a broad check-in across prayer, speech, purity, relationships, and discipline. It creates one timeline entry with the answers and the recalculated changes.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                HStack(spacing: 8) {
                    Label("\(questions.count) questions", systemImage: "checklist")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                    Spacer(minLength: 8)
                    Text("\(completionCount) answered")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.orange)
                }
            }
        }
    }

    private var progressRail: some View {
        AppSurfaceCard(contentPadding: 12) {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("Progress")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .textCase(.uppercase)

                    Spacer(minLength: 8)

                    Text("Step \(stepIndex + 1) of \(questions.count)")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                }

                GeometryReader { proxy in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color.primary.opacity(0.08))

                        Capsule()
                            .fill(backgroundTheme.glowColor)
                            .frame(width: proxy.size.width * (Double(stepIndex + 1) / Double(questions.count)))
                    }
                }
                .frame(height: 8)

                HStack(spacing: 6) {
                    ForEach(questions.indices, id: \.self) { index in
                        Capsule()
                            .fill(index < stepIndex ? backgroundTheme.glowColor : (index == stepIndex ? .orange : .primary.opacity(0.12)))
                            .frame(width: index == stepIndex ? 22 : 8, height: 8)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .center)
            }
        }
    }

    private var questionCard: some View {
        AppSurfaceCard(contentPadding: 16) {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .top, spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(backgroundTheme.glowColor.opacity(0.16))

                        Image(systemName: "checklist")
                            .font(.headline.weight(.semibold))
                            .foregroundStyle(backgroundTheme.glowColor)
                    }
                    .frame(width: 40, height: 40)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(currentQuestion.shortTitle)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                            .textCase(.uppercase)

                        Text(currentQuestion.prompt)
                            .font(.title2.weight(.semibold))
                            .foregroundStyle(.primary)
                            .fixedSize(horizontal: false, vertical: true)

                        Text(currentQuestion.detail)
                            .font(.callout)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

                Text(currentProgressLabel)
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.primary.opacity(0.05), in: Capsule())
            }
        }
    }

    private var answerCard: some View {
        AppSurfaceCard(contentPadding: 14) {
            VStack(alignment: .leading, spacing: 10) {
                Text("Choose one")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)

                VStack(spacing: 10) {
                    ForEach(CheckInQuestionnaire.answerOptions.indices, id: \.self) { index in
                        answerRow(for: index)
                    }
                }
            }
        }
    }

    private var footerBar: some View {
        AppSurfaceCard(contentPadding: 14) {
            HStack(spacing: 12) {
                Button {
                    if stepIndex > 0 {
                        stepIndex -= 1
                    }
                } label: {
                    Text("Back")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(stepIndex > 0 ? .primary : .secondary)
                }
                .disabled(stepIndex == 0)

                Spacer(minLength: 12)

                ActionButtonView(
                    title: isLastQuestion ? "Apply Check-in" : "Continue",
                    icon: isLastQuestion ? "checkmark" : "arrow.right",
                    tint: .red
                ) {
                    advance()
                }
                .disabled(!canAdvance)
                .opacity(canAdvance ? 1 : 0.55)
            }
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 12)
        .background(.clear)
    }

    @ViewBuilder
    private func answerRow(for index: Int) -> some View {
        let option = CheckInQuestionnaire.answerOptions[index]
        let isSelected = currentSelection == index

        Button {
            selectedAnswerIndices[stepIndex] = index
        } label: {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(option.title)
                            .font(.body.weight(.semibold))
                            .foregroundStyle(.primary)
                        Spacer(minLength: 8)

                        if isSelected {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(backgroundTheme.glowColor)
                        } else {
                            Image(systemName: "circle")
                                .foregroundStyle(.tertiary)
                        }
                    }

                    Text(option.detail)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(isSelected ? backgroundTheme.glowColor.opacity(0.12) : Color.primary.opacity(0.04))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(isSelected ? backgroundTheme.glowColor.opacity(0.45) : Color.primary.opacity(0.08), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    private func advance() {
        guard canAdvance else { return }

        if isLastQuestion {
            saveCheckIn()
        } else {
            stepIndex += 1
        }
    }

    private func saveCheckIn() {
        let responses = questions.indices.compactMap { index -> CheckInResponse? in
            guard let selectedIndex = selectedAnswerIndices[index] else {
                return nil
            }

            return CheckInQuestionnaire.response(
                for: questions[index],
                selectedOptionIndex: selectedIndex,
                sections: dashboard.sections
            )
        }

        guard responses.count == questions.count else {
            return
        }

        let record = CheckInRecord(completedAt: .now, responses: responses)
        guard let payloadData = try? JSONEncoder().encode(record),
              let payload = String(data: payloadData, encoding: .utf8) else {
            return
        }

        let entry = LogEntry(
            kind: .checkIn,
            sectionTitle: "Whole Journey",
            sinTitle: nil,
            note: record.summaryText,
            prayerMinutes: 0,
            checkInRecordJSON: payload,
            occurredAt: record.completedAt
        )

        onSave(entry)
        dismiss()
    }
}

#Preview {
    CheckInView(
        backgroundTheme: .constant(.blood),
        dashboard: DashboardViewModel()
    ) { _ in }
    .environment(AppPreferenceStore())
}
