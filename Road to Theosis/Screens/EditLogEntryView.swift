import SwiftUI

struct EditLogEntryView: View {
    @Binding var backgroundTheme: AppBackgroundTheme
    let entry: LogEntry
    let onSave: (LogEntry) -> Void
    let onDelete: (() -> Void)?
    @Environment(\.dismiss) private var dismiss
    @State private var note: String
    @State private var occurredAt: Date
    @State private var prayerDurationSeconds: Int
    @State private var connectedPrayerSins: Set<ConnectedSinReference>
    @State private var progressPercentage: Int

    init(
        backgroundTheme: Binding<AppBackgroundTheme>,
        entry: LogEntry,
        onSave: @escaping (LogEntry) -> Void,
        onDelete: (() -> Void)? = nil
    ) {
        self._backgroundTheme = backgroundTheme
        self.entry = entry
        self.onSave = onSave
        self.onDelete = onDelete
        self._note = State(initialValue: entry.note)
        self._occurredAt = State(initialValue: entry.occurredAt)
        self._prayerDurationSeconds = State(initialValue: entry.prayerDurationSeconds)
        self._connectedPrayerSins = State(initialValue: Set(entry.prayerConnectedSins))
        self._progressPercentage = State(initialValue: entry.progressPercentage ?? 0)
    }

    private var trimmedNote: String {
        note.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var canEditPrayerDuration: Bool {
        entry.kind == .prayer || entry.kind == .quickPrayer || entry.prayerDurationSeconds > 0
    }

    private var canEditProgress: Bool {
        entry.progressPercentage != nil
    }

    private var targetText: String {
        if let sinTitle = entry.sinTitle {
            return "\(entry.sectionTitle) / \(sinTitle)"
        }

        return entry.sectionTitle
    }

    private var progressBinding: Binding<Double> {
        Binding {
            Double(progressPercentage)
        } set: { newValue in
            progressPercentage = Int(newValue.rounded())
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackgroundView(theme: backgroundTheme)

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 16) {
                        summaryCard
                        detailsCard
                        noteCard
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                    .padding(.bottom, 24)
                }
            }
            .navigationTitle("Edit Log")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                if onDelete != nil {
                    ToolbarItem(placement: .destructiveAction) {
                        Button("Delete", role: .destructive) {
                            delete()
                        }
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        save()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    private var summaryCard: some View {
        AppSurfaceCard {
            HStack(alignment: .top, spacing: 12) {
                ZStack {
                    Circle()
                        .fill(entry.kind.tint.opacity(0.14))

                    Image(systemName: entry.kind.symbolName)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(entry.kind.tint)
                }
                .frame(width: 38, height: 38)

                VStack(alignment: .leading, spacing: 4) {
                    Text(entry.kind.title)
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(.primary)

                    Text(targetText)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }

    private var detailsCard: some View {
        AppSurfaceCard {
            VStack(alignment: .leading, spacing: 12) {
                DatePicker("When", selection: $occurredAt, displayedComponents: [.date, .hourAndMinute])

                if canEditPrayerDuration {
                    Stepper(value: $prayerDurationSeconds, in: 0...10_800, step: 60) {
                        HStack {
                            Label("Prayer time", systemImage: "hands.sparkles")
                            Spacer()
                            Text(LogEntry.formatPrayerDuration(seconds: prayerDurationSeconds))
                                .foregroundStyle(.secondary)
                        }
                    }

                    PrayerSinPickerView(
                        title: "Connected sins",
                        subtitle: "Attach one or more sins to this prayer session.",
                        selectedReferences: $connectedPrayerSins
                    )
                }

                if canEditProgress {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Label("Purity", systemImage: "slider.horizontal.below.rectangle")
                            Spacer()
                            Text(SinFrequencyScale.label(for: progressPercentage))
                                .foregroundStyle(entry.kind.tint)
                        }

                        Slider(value: progressBinding, in: 0...100, step: 1)
                            .tint(entry.kind.tint)
                    }
                }
            }
        }
    }

    private var noteCard: some View {
        AppSurfaceCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("Note")
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(.primary)

                TextEditor(text: $note)
                    .frame(minHeight: 160)
                    .padding(10)
                    .background(Color(uiColor: .secondarySystemBackground), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .strokeBorder(Color.primary.opacity(0.08), lineWidth: 1)
                    )
            }
        }
    }

    private func save() {
        let updatedPrayerDurationSeconds = canEditPrayerDuration ? prayerDurationSeconds : entry.prayerDurationSeconds
        let updatedPrayerMinutes = updatedPrayerDurationSeconds / 60
        let updatedEntry = LogEntry(
            id: entry.id,
            kind: entry.kind,
            sectionTitle: entry.sectionTitle,
            sinTitle: entry.isPrayerEntry ? nil : entry.sinTitle,
            note: trimmedNote,
            prayerMinutes: updatedPrayerMinutes,
            prayerDurationSeconds: updatedPrayerDurationSeconds,
            connectedSins: entry.isPrayerEntry ? ConnectedSinReference.ordered(connectedPrayerSins) : [],
            progressPercentage: canEditProgress ? progressPercentage : entry.progressPercentage,
            occurredAt: occurredAt
        )

        onSave(updatedEntry)
        dismiss()
    }

    private func delete() {
        onDelete?()
        dismiss()
    }
}
