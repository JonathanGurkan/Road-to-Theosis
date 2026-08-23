import SwiftUI

struct AddLoggingView: View {
    @Binding var backgroundTheme: AppBackgroundTheme
    @Environment(AppPreferenceStore.self) private var preferences
    let onSave: (LogEntry) -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var entryMode: EntryMode = .sin
    @State private var sinOutcome: SinOutcome = .victory
    @State private var selectedSectionIndex: Int = 0
    @State private var selectedSinIndex: Int = 0
    @State private var note = ""
    @State private var includePrayerMinutes = false
    @State private var prayerMinutes: Int = 0
    @State private var occurredAt = Date()
    @State private var isShowingTimedPrayer = false

    private var prayerTimerCountingMode: PrayerTimerCountingMode {
        preferences.prayerTimerCountingMode
    }

    init(
        backgroundTheme: Binding<AppBackgroundTheme>,
        onSave: @escaping (LogEntry) -> Void,
        initialMode: EntryMode = .sin
    ) {
        self._backgroundTheme = backgroundTheme
        self.onSave = onSave
        self._entryMode = State(initialValue: initialMode)
    }

    private let sections = SinCategory.sample

    private var selectedSection: SinSection {
        sections[min(max(selectedSectionIndex, 0), sections.count - 1)]
    }

    private var selectedSin: SinCategory {
        selectedSection.items[min(max(selectedSinIndex, 0), selectedSection.items.count - 1)]
    }

    private var trimmedNote: String {
        note.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var heroTitle: String {
        switch entryMode {
        case .sin:
            return "Log a specific sin"
        case .quickPrayer:
            return "Log a quick prayer"
        case .note:
            return "Add a note"
        }
    }

    private var heroSubtitle: String {
        switch entryMode {
        case .sin:
            return preferences.isPrayerTimingEnabled ? "Pick the exact sin first, then choose the outcome. Prayer time is optional and separate." : "Pick the exact sin first, then choose the outcome."
        case .quickPrayer:
            return preferences.isPrayerTimingEnabled ? "Use this for a brief prayer without the timer. The timed flow still lives in Prayer Timer." : "Use this for a brief prayer without focusing on elapsed time."
        case .note:
            return "Use this for a short reflection without tying it to a sin or prayer session."
        }
    }

    private var heroIcon: String {
        switch entryMode {
        case .sin:
            return selectedSin.icon
        case .quickPrayer:
            return "hands.sparkles"
        case .note:
            return "text.quote"
        }
    }

    private var heroTint: Color {
        switch entryMode {
        case .sin:
            return selectedSin.tint
        case .quickPrayer:
            return .teal
        case .note:
            return .blue
        }
    }

    private var noteTitle: String {
        switch entryMode {
        case .sin:
            return "Notes"
        case .quickPrayer:
            return "Prayer note"
        case .note:
            return "Note"
        }
    }

    private var noteSubtitle: String {
        switch entryMode {
        case .sin:
            return "Add any context you want to remember with this sin log."
        case .quickPrayer:
            return preferences.isPrayerTimingEnabled ? "Keep this short. Use Prayer Timer if you want the session timed." : "Keep this short and focused on the prayer itself."
        case .note:
            return "Write anything short you want to remember."
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackgroundView(theme: backgroundTheme)

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 16) {
                        heroCard
                        modeCard

                        if entryMode == .sin {
                            sinFocusCard
                            outcomeCard
                            if preferences.isPrayerTimingEnabled {
                                prayerCard
                            }
                        } else if entryMode == .quickPrayer {
                            quickPrayerCard
                            if preferences.isPrayerTimingEnabled {
                                timedPrayerCard
                            }
                        }

                        noteCard
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                    .padding(.bottom, 24)
                }
            }
            .navigationTitle("Add Log")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveEntry()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .onChange(of: selectedSectionIndex) { _, _ in
            selectedSinIndex = 0
        }
        .onChange(of: entryMode) { _, newValue in
            if newValue != .sin {
                includePrayerMinutes = false
                prayerMinutes = 0
            }
        }
        .onChange(of: preferences.isPrayerTimingEnabled) { _, isEnabled in
            if !isEnabled {
                includePrayerMinutes = false
                prayerMinutes = 0
                isShowingTimedPrayer = false
            }
        }
        .fullScreenCover(isPresented: $isShowingTimedPrayer) {
            PrayerTimerView(backgroundTheme: $backgroundTheme) { entry in
                onSave(entry)
                dismiss()
            }
        }
    }

    private var heroCard: some View {
        AppSurfaceCard {
            VStack(alignment: .leading, spacing: 10) {
                Text(heroTitle)
                    .font(.largeTitle.weight(.semibold))
                    .foregroundStyle(.primary)

                Text(heroSubtitle)
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                HStack(alignment: .center, spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(heroTint.opacity(0.16))

                        Image(systemName: heroIcon)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(heroTint)
                    }
                    .frame(width: 34, height: 34)

                    VStack(alignment: .leading, spacing: 2) {
                        if entryMode == .sin {
                            Text(selectedSin.title)
                                .font(.headline.weight(.semibold))
                                .foregroundStyle(.primary)
                                .fixedSize(horizontal: false, vertical: true)

                            Text(selectedSection.title)
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.secondary)
                        } else {
                            Text(entryMode.title)
                                .font(.headline.weight(.semibold))
                                .foregroundStyle(.primary)

                            Text(entryMode.subtitle)
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.secondary)
                        }
                    }

                    Spacer(minLength: 8)
                }
            }
        }
    }

    private var modeCard: some View {
        AppSurfaceCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("Mode")
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(.primary)

                Picker("Mode", selection: $entryMode) {
                    ForEach(EntryMode.allCases) { mode in
                        Text(mode.title).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
            }
        }
    }

    private var sinFocusCard: some View {
        AppSurfaceCard(contentPadding: 12) {
            VStack(alignment: .leading, spacing: 10) {
                Text("Sin focus")
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(.primary)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(sections.indices, id: \.self) { index in
                            SectionChip(
                                title: sections[index].title,
                                tint: sections[index].tint,
                                isSelected: selectedSectionIndex == index,
                                count: sections[index].items.count
                            ) {
                                selectedSectionIndex = index
                            }
                        }
                    }
                    .padding(.vertical, 1)
                }

                LazyVGrid(
                    columns: [
                        GridItem(.flexible(), spacing: 8),
                        GridItem(.flexible(), spacing: 8)
                    ],
                    spacing: 8
                ) {
                    ForEach(selectedSection.items.indices, id: \.self) { index in
                        SinChip(
                            category: selectedSection.items[index],
                            isSelected: selectedSinIndex == index
                        ) {
                            selectedSinIndex = index
                        }
                    }
                }

                Text(selectedSin.detail)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var outcomeCard: some View {
        AppSurfaceCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("Outcome")
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(.primary)

                Picker("Type", selection: $sinOutcome) {
                    ForEach(SinOutcome.allCases) { kind in
                        Text(kind.title).tag(kind)
                    }
                }
                .pickerStyle(.segmented)

                DatePicker("When", selection: $occurredAt, displayedComponents: [.date, .hourAndMinute])

                Text(sinOutcome.detail)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var prayerCard: some View {
        AppSurfaceCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Prayer time")
                            .font(.headline.weight(.semibold))
                            .foregroundStyle(.primary)

                        Text("Optional and separate from the sin log.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Toggle("Include prayer time", isOn: $includePrayerMinutes)
                        .labelsHidden()
                }

                if includePrayerMinutes {
                    Stepper(value: $prayerMinutes, in: 0...180, step: 5) {
                        HStack {
                            Label("Minutes prayed", systemImage: "hands.sparkles")
                            Spacer()
                            Text("\(prayerMinutes)m")
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
    }

    private var quickPrayerCard: some View {
        AppSurfaceCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("Quick prayer")
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(.primary)

                Text(preferences.isPrayerTimingEnabled ? "This is a brief prayer entry without a timer. Use Prayer Timer if you want the elapsed time captured." : "This is a brief prayer entry without tracking elapsed time.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                DatePicker("When", selection: $occurredAt, displayedComponents: [.date, .hourAndMinute])
            }
        }
    }

    private var timedPrayerCard: some View {
        AppSurfaceCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("Timed prayer")
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(.primary)

                Text(prayerTimerCountingMode == .background ? "Open the timer for a focused prayer session that keeps counting while the app is in the background." : "Open the timer for a focused prayer session instead of logging a quick prayer.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                Button {
                    isShowingTimedPrayer = true
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "timer")
                            .font(.subheadline.weight(.semibold))

                        Text("Start Timed Prayer")
                            .font(.subheadline.weight(.semibold))

                        Spacer(minLength: 0)
                    }
                    .foregroundStyle(.teal)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .frame(maxWidth: .infinity)
                    .background {
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(.teal.opacity(0.12))
                    }
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .strokeBorder(.teal.opacity(0.35), lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var noteCard: some View {
        AppSurfaceCard {
            VStack(alignment: .leading, spacing: 12) {
                Text(noteTitle)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(.primary)

                Text(noteSubtitle)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                TextEditor(text: $note)
                    .frame(minHeight: 140)
                    .padding(10)
                    .background(Color(uiColor: .secondarySystemBackground), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .strokeBorder(Color.primary.opacity(0.08), lineWidth: 1)
                    )
            }
        }
    }

    private func saveEntry() {
        switch entryMode {
        case .sin:
            let entry = LogEntry(
                kind: sinOutcome.entryKind,
                sectionTitle: selectedSection.title,
                sinTitle: selectedSin.title,
                note: trimmedNote,
                prayerMinutes: includePrayerMinutes ? prayerMinutes : 0,
                occurredAt: occurredAt
            )
            onSave(entry)
        case .quickPrayer:
            let entry = LogEntry(
                kind: .quickPrayer,
                sectionTitle: "Prayer",
                sinTitle: nil,
                note: trimmedNote,
                prayerMinutes: 0,
                occurredAt: occurredAt
            )
            onSave(entry)
        case .note:
            let entry = LogEntry(
                kind: .note,
                sectionTitle: "Note",
                sinTitle: nil,
                note: trimmedNote,
                prayerMinutes: 0,
                occurredAt: occurredAt
            )
            onSave(entry)
        }

        dismiss()
    }
}

private struct SectionChip: View {
    let title: String
    let tint: Color
    let isSelected: Bool
    let count: Int
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(isSelected ? .primary : .secondary)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)

                Text("\(count) sins")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(tint)
            }
            .frame(width: 100, alignment: .leading)
            .frame(minHeight: 46, alignment: .leading)
            .padding(.horizontal, 6)
            .padding(.vertical, 4)
            .background {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(tint.opacity(isSelected ? 0.18 : 0.10))
            }
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(isSelected ? tint.opacity(0.65) : Color.primary.opacity(0.08), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

private struct SinChip: View {
    let category: SinCategory
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(alignment: .top, spacing: 8) {
                ZStack {
                    Circle()
                        .fill(category.tint.opacity(isSelected ? 0.20 : 0.12))

                    Image(systemName: category.icon)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(category.tint)
                }
                .frame(width: 24, height: 24)

                VStack(alignment: .leading, spacing: 2) {
                    Text(category.title)
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.primary)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)

                    Text(category.watchword)
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(category.tint)
                }

                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, minHeight: 52, alignment: .leading)
            .padding(.horizontal, 6)
            .padding(.vertical, 4)
            .background {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(category.tint.opacity(isSelected ? 0.18 : 0.10))
            }
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(isSelected ? category.tint.opacity(0.65) : Color.primary.opacity(0.08), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

enum EntryMode: String, CaseIterable, Identifiable {
    case sin
    case quickPrayer
    case note

    var id: String { rawValue }

    var title: String {
        switch self {
        case .sin:
            return "Sin"
        case .quickPrayer:
            return "Prayer"
        case .note:
            return "Note"
        }
    }

    var subtitle: String {
        switch self {
        case .sin:
            return "Sin log"
        case .quickPrayer:
            return "Quick prayer"
        case .note:
            return "General note"
        }
    }
}

private enum SinOutcome: String, CaseIterable, Identifiable {
    case victory
    case loss
    case note

    var id: String { rawValue }

    var title: String {
        switch self {
        case .victory:
            return "Resistance"
        case .loss:
            return "Loss"
        case .note:
            return "Note"
        }
    }

    var entryKind: LogEntry.Kind {
        switch self {
        case .victory:
            return .victory
        case .loss:
            return .loss
        case .note:
            return .note
        }
    }

    var detail: String {
        switch self {
        case .victory:
            return "Use this when temptation was present and you actively resisted it."
        case .loss:
            return "Use this for a setback, lapse, or moment where you want to regain footing."
        case .note:
            return "Use this for anything short that you want to remember without pushing it into resistance or loss."
        }
    }
}

#Preview {
    AddLoggingView(backgroundTheme: .constant(.blood)) { _ in }
        .environment(AppPreferenceStore())
}
