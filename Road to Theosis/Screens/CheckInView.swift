import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

struct CheckInView: View {
    @Binding var backgroundTheme: AppBackgroundTheme
    let dashboard: DashboardViewModel
    let onSave: (LogEntry) -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(AppPreferenceStore.self) private var preferences
    @State private var selectedAnswerIndicesByQuestionID: [String: Int] = [:]
    @State private var skippedQuestionIDs: Set<String> = []
    @State private var stepIndex = 0
    @State private var reviewDraft: CheckInReviewDraft?

    private var questions: [CheckInQuestion] {
        CheckInQuestionnaire.questions(for: preferences.checkInEnabledQuestionIDs)
    }

    init(
        backgroundTheme: Binding<AppBackgroundTheme>,
        dashboard: DashboardViewModel,
        onSave: @escaping (LogEntry) -> Void
    ) {
        self._backgroundTheme = backgroundTheme
        self.dashboard = dashboard
        self.onSave = onSave
    }

    private var currentQuestion: CheckInQuestion {
        questions[stepIndex]
    }

    private var currentSelection: Int? {
        selectedAnswerIndicesByQuestionID[currentQuestion.id]
    }

    private var currentProgressLabel: String {
        CheckInQuestionnaire.progressLabel(for: currentQuestion, sections: dashboard.sections)
    }

    private var completionCount: Int {
        questions.filter { selectedAnswerIndicesByQuestionID[$0.id] != nil }.count
    }

    private var isLastQuestion: Bool {
        stepIndex == questions.count - 1
    }

    private var skippedCount: Int {
        questions.filter { skippedQuestionIDs.contains($0.id) && selectedAnswerIndicesByQuestionID[$0.id] == nil }.count
    }

    private var unansweredCount: Int {
        questions.count - completionCount
    }

    private var firstUnansweredIndex: Int? {
        questions.firstIndex { selectedAnswerIndicesByQuestionID[$0.id] == nil }
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

                ScrollViewReader { proxy in
                    ScrollView(showsIndicators: false) {
                        VStack(alignment: .leading, spacing: 16) {
                            headerCard
                                .id(Self.scrollTopID)
                            progressRail
                            questionCard
                            answerCard
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 16)
                        .padding(.bottom, 24)
                    }
                    .onChange(of: stepIndex) { _, _ in
                        withAnimation(.easeInOut(duration: 0.22)) {
                            proxy.scrollTo(Self.scrollTopID, anchor: .top)
                        }
                    }
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
        .onChange(of: questions.count) { _, count in
            stepIndex = min(stepIndex, max(count - 1, 0))
        }
        .sheet(item: $reviewDraft) { draft in
            CheckInReviewSheetView(
                backgroundTheme: backgroundTheme,
                record: draft.record,
                onBack: {
                    reviewDraft = nil
                },
                onApply: {
                    applyCheckIn(draft.record)
                }
            )
        }
    }

    private static let scrollTopID = "check-in-scroll-top"

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
                    Text(progressSummaryText)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.orange)
                }
            }
        }
    }

    private var progressSummaryText: String {
        if skippedCount > 0 {
            return "\(completionCount) answered, \(skippedCount) skipped"
        }

        return "\(completionCount) answered"
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
                        progressMarker(for: index)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .center)

                HStack(spacing: 12) {
                    progressLegendItem(title: "Answered", status: .answered)
                    progressLegendItem(title: "Skipped", status: .skipped)
                    progressLegendItem(title: "Current", status: .current)
                }
                .frame(maxWidth: .infinity, alignment: .center)
            }
        }
    }

    @ViewBuilder
    private func progressMarker(for index: Int) -> some View {
        let status = progressStatus(for: index)

        Button {
            goToQuestion(at: index)
        } label: {
            Capsule()
                .fill(progressMarkerFill(for: status))
                .frame(width: status == .current ? 22 : 8, height: 8)
                .overlay {
                    if status == .skipped {
                        Capsule()
                            .strokeBorder(Color.orange.opacity(0.85), lineWidth: 1.5)
                    }
                }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Question \(index + 1)")
        .accessibilityValue(progressAccessibilityValue(for: status))
    }

    private func progressLegendItem(title: String, status: CheckInProgressStatus) -> some View {
        HStack(spacing: 5) {
            Capsule()
                .fill(progressMarkerFill(for: status))
                .frame(width: status == .current ? 16 : 8, height: 8)
                .overlay {
                    if status == .skipped {
                        Capsule()
                            .strokeBorder(Color.orange.opacity(0.85), lineWidth: 1.5)
                    }
                }

            Text(title)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.secondary)
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
                        goToQuestion(at: stepIndex - 1)
                    }
                } label: {
                    Text("Back")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(stepIndex > 0 ? .primary : .secondary)
                }
                .disabled(stepIndex == 0)

                Spacer(minLength: 12)

                if unansweredCount > 0 {
                    Text("\(unansweredCount) left")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                }

                ActionButtonView(
                    title: "Next",
                    icon: "arrow.right",
                    tint: .red
                ) {
                    advance()
                }
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
            playSelectionFeedback()
            selectedAnswerIndicesByQuestionID[currentQuestion.id] = index
            skippedQuestionIDs.remove(currentQuestion.id)
            advanceAfterAnswer()
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

    private func playSelectionFeedback() {
        #if canImport(UIKit)
        UISelectionFeedbackGenerator().selectionChanged()
        #endif
    }

    private func advance() {
        if currentSelection == nil {
            skippedQuestionIDs.insert(currentQuestion.id)
        }

        if let firstUnansweredIndex, isLastQuestion || completionCount == questions.count {
            if firstUnansweredIndex == stepIndex {
                return
            }

            stepIndex = firstUnansweredIndex
        } else if isLastQuestion {
            prepareCheckInReview()
        } else {
            goToQuestion(at: stepIndex + 1, marksCurrentAsSkipped: false)
        }
    }

    private func goToQuestion(at index: Int, marksCurrentAsSkipped: Bool = true) {
        guard questions.indices.contains(index) else { return }

        if marksCurrentAsSkipped, currentSelection == nil {
            skippedQuestionIDs.insert(currentQuestion.id)
        }

        stepIndex = index
    }

    private func advanceAfterAnswer() {
        if completionCount == questions.count {
            if isLastQuestion {
                prepareCheckInReview()
            } else {
                goToQuestion(at: stepIndex + 1, marksCurrentAsSkipped: false)
            }
        } else if isLastQuestion, let firstUnansweredIndex {
            stepIndex = firstUnansweredIndex
        } else if !isLastQuestion {
            goToQuestion(at: stepIndex + 1, marksCurrentAsSkipped: false)
        }
    }

    private func progressStatus(for index: Int) -> CheckInProgressStatus {
        if index == stepIndex {
            return .current
        }

        if selectedAnswerIndicesByQuestionID[questions[index].id] != nil {
            return .answered
        }

        if skippedQuestionIDs.contains(questions[index].id) {
            return .skipped
        }

        return .pending
    }

    private func progressMarkerFill(for status: CheckInProgressStatus) -> Color {
        switch status {
        case .answered:
            return backgroundTheme.glowColor
        case .current:
            return .orange
        case .skipped:
            return Color.orange.opacity(0.18)
        case .pending:
            return Color.primary.opacity(0.12)
        }
    }

    private func progressAccessibilityValue(for status: CheckInProgressStatus) -> String {
        switch status {
        case .answered:
            return "Answered"
        case .current:
            return "Current"
        case .skipped:
            return "Skipped"
        case .pending:
            return "Not answered"
        }
    }

    private func prepareCheckInReview() {
        let responses = questions.compactMap { question -> CheckInResponse? in
            guard let selectedIndex = selectedAnswerIndicesByQuestionID[question.id] else {
                return nil
            }

            return CheckInQuestionnaire.response(
                for: question,
                selectedOptionIndex: selectedIndex,
                sections: dashboard.sections
            )
        }

        guard responses.count == questions.count else {
            return
        }

        let record = CheckInRecord(completedAt: .now, responses: responses)
        reviewDraft = CheckInReviewDraft(record: record)
    }

    private func applyCheckIn(_ record: CheckInRecord) {
        guard let payloadData = try? JSONEncoder().encode(record),
              let payload = String(data: payloadData, encoding: .utf8) else {
            return
        }

        let entry = LogEntry(
            kind: .checkIn,
            sectionTitle: "Whole Journey",
            sinTitle: nil,
            note: record.timelineSummaryText,
            prayerMinutes: 0,
            checkInRecordJSON: payload,
            occurredAt: record.completedAt
        )

        onSave(entry)
        reviewDraft = nil
        dismiss()
    }
}

private struct CheckInReviewDraft: Identifiable {
    let id = UUID()
    let record: CheckInRecord
}

private enum CheckInProgressStatus {
    case answered
    case current
    case skipped
    case pending
}

private struct CheckInReviewSheetView: View {
    let backgroundTheme: AppBackgroundTheme
    let record: CheckInRecord
    let onBack: () -> Void
    let onApply: () -> Void

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackgroundView(theme: backgroundTheme)

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 16) {
                        AppSurfaceCard {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Review check-in")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(.secondary)
                                    .textCase(.uppercase)

                                Text("Confirm your answers before the meter updates.")
                                    .font(.title2.weight(.semibold))
                                    .foregroundStyle(.primary)
                                    .fixedSize(horizontal: false, vertical: true)

                                Text("\(record.responses.count) answers will be saved as one timeline entry.")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                        }

                        ForEach(record.responses) { response in
                            responseCard(response)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                    .padding(.bottom, 24)
                }
            }
            .navigationTitle("Review")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Back", action: onBack)
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Apply", action: onApply)
                        .fontWeight(.semibold)
                }
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }

    private func responseCard(_ response: CheckInResponse) -> some View {
        AppSurfaceCard(contentPadding: 14) {
            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .firstTextBaseline) {
                    Text(response.questionShortTitle)
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(.primary)
                    Spacer(minLength: 8)
                    Text(response.answerTitle)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(backgroundTheme.glowColor)
                }

                Text(response.questionPrompt)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                VStack(alignment: .leading, spacing: 6) {
                    ForEach(Array(response.changes.prefix(4))) { change in
                        HStack(spacing: 8) {
                            Text(change.sinTitle)
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.primary)
                                .lineLimit(1)
                            Spacer(minLength: 8)
                            Text("\(SinFrequencyScale.percentage(for: change.targetProgress))%")
                                .font(.caption.weight(.bold))
                                .foregroundStyle(backgroundTheme.glowColor)
                                .monospacedDigit()
                        }
                    }

                    if response.changes.count > 4 {
                        Text("+\(response.changes.count - 4) more affected areas")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.top, 2)
            }
        }
    }
}

#Preview {
    CheckInView(
        backgroundTheme: .constant(.blood),
        dashboard: DashboardViewModel()
    ) { _ in }
    .environment(AppPreferenceStore())
}
