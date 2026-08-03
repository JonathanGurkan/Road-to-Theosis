import SwiftUI

struct DefenseVersesSheetView: View {
    let category: SinCategory

    @Environment(AppPreferenceStore.self) private var preferences
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @State private var customVerses: [BibleDefenseVerse] = []
    @State private var verseEditor: VerseEditorContext?
    @State private var pendingDeleteVerse: BibleDefenseVerse?

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [
                        category.tint.opacity(colorScheme == .dark ? 0.18 : 0.10),
                        Color(uiColor: .systemBackground),
                        Color(uiColor: .secondarySystemBackground)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                TabView {
                    ForEach(BibleDefenseVerse.defaultVerses) { verse in
                        VerseCardView(
                            verse: verse,
                            accent: category.tint,
                            showsApplication: preferences.showVerseApplications
                        )
                        .padding(.horizontal, 16)
                        .padding(.vertical, 0)
                    }

                    ForEach(customVerses) { verse in
                        VerseCardView(
                            verse: verse,
                            accent: category.tint,
                            showsApplication: preferences.showVerseApplications,
                            onEdit: {
                                verseEditor = VerseEditorContext(verse: verse)
                            },
                            onDelete: {
                                pendingDeleteVerse = verse
                            }
                        )
                        .padding(.horizontal, 16)
                        .padding(.vertical, 0)
                        .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .opacity.combined(with: .move(edge: .leading))))
                    }

                    AddVersePromptView(accent: category.tint) {
                        verseEditor = VerseEditorContext()
                    }
                    .padding(.horizontal, 16)
                }
                .tabViewStyle(.page(indexDisplayMode: .automatic))
                .animation(.easeInOut(duration: 0.24), value: customVerses.map(\.id))
            }
            .navigationTitle("Defense Verses")
            .navigationBarTitleDisplayMode(.inline)
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        verseEditor = VerseEditorContext()
                    } label: {
                        Label("Add Verse", systemImage: "plus.circle.fill")
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .safeAreaInset(edge: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(category.title)
                        .font(.title2.weight(.semibold))
                        .foregroundStyle(.primary)

                    Text("Swipe through defense verses or add one for this focus area.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 16)
                .padding(.top, 4)
                .padding(.bottom, 8)
            }
        }
        .onAppear(perform: loadCustomVerses)
        .sheet(item: $verseEditor) { editor in
            AddDefenseVerseSheetView(accent: category.tint, verse: editor.verse) { verse in
                if let existingID = editor.verse?.id,
                   let index = customVerses.firstIndex(where: { $0.id == existingID }) {
                    customVerses[index] = verse
                } else {
                    customVerses.append(verse)
                }

                saveCustomVerses()
            }
        }
        .alert("Delete verse?", isPresented: deleteAlertBinding, presenting: pendingDeleteVerse) { verse in
            Button("Delete", role: .destructive) {
                deleteCustomVerse(verse)
            }

            Button("Cancel", role: .cancel) {
                pendingDeleteVerse = nil
            }
        } message: { verse in
            Text("Are you sure you want to delete \"\(verse.title)\" from this sin?")
        }
    }

    private var deleteAlertBinding: Binding<Bool> {
        Binding(
            get: { pendingDeleteVerse != nil },
            set: { isPresented in
                if !isPresented {
                    pendingDeleteVerse = nil
                }
            }
        )
    }

    private func loadCustomVerses() {
        customVerses = decodedStorage()[category.title] ?? []
    }

    private func deleteCustomVerse(_ verse: BibleDefenseVerse) {
        withAnimation(.easeInOut(duration: 0.24)) {
            customVerses.removeAll { $0.id == verse.id }
        }
        pendingDeleteVerse = nil
        saveCustomVerses()
    }

    private func saveCustomVerses() {
        var storage = decodedStorage()
        storage[category.title] = customVerses

        guard let data = try? JSONEncoder().encode(storage),
              let encoded = String(data: data, encoding: .utf8) else {
            return
        }

        preferences.customDefenseVersesBySin = encoded
    }

    private func decodedStorage() -> [String: [BibleDefenseVerse]] {
        guard let data = preferences.customDefenseVersesBySin.data(using: .utf8),
              let decoded = try? JSONDecoder().decode([String: [BibleDefenseVerse]].self, from: data) else {
            return [:]
        }

        return decoded
    }
}

private struct VerseEditorContext: Identifiable {
    let id = UUID()
    let verse: BibleDefenseVerse?

    init(verse: BibleDefenseVerse? = nil) {
        self.verse = verse
    }
}

private struct VerseCardView: View {
    let verse: BibleDefenseVerse
    let accent: Color
    let showsApplication: Bool
    var onEdit: (() -> Void)? = nil
    var onDelete: (() -> Void)? = nil
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        AppSurfaceCard(contentPadding: 10) {
            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .top, spacing: 8) {
                    ZStack {
                        Circle()
                            .fill(accent.opacity(colorScheme == .dark ? 0.16 : 0.12))

                        Image(systemName: verse.symbol)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(accent)
                    }
                    .frame(width: 30, height: 30)

                    VStack(alignment: .leading, spacing: 1) {
                        Text(verse.title)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.primary)

                        Text(verse.translation)
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(.secondary)
                            .textCase(.uppercase)
                    }

                    Spacer(minLength: 8)

                    if !verse.reference.isEmpty {
                        Text(verse.reference)
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(accent)
                            .padding(.horizontal, 7)
                            .padding(.vertical, 3)
                            .background(accent.opacity(colorScheme == .dark ? 0.14 : 0.10), in: Capsule())
                    }
                }

                Text(verse.excerpt)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                    .fixedSize(horizontal: false, vertical: true)

                if showsApplication {
                    Text(verse.application)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                if onEdit != nil || onDelete != nil {
                    HStack(spacing: 8) {
                        if let onEdit {
                            Button {
                                onEdit()
                            } label: {
                                Label("Edit", systemImage: "pencil")
                                    .frame(maxWidth: .infinity)
                            }
                            .ifAvailableGlass(tint: accent)
                        }

                        if let onDelete {
                            Button(role: .destructive) {
                                onDelete()
                            } label: {
                                Label("Delete", systemImage: "trash")
                                    .frame(maxWidth: .infinity)
                            }
                            .ifAvailableGlass(tint: .red)
                        }
                    }
                    .font(.caption.weight(.semibold))
                    .padding(.top, 2)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .frame(minHeight: 138, alignment: .topLeading)
        }
        .frame(maxWidth: 300, alignment: .center)
    }
}

private struct AddVersePromptView: View {
    let accent: Color
    let action: () -> Void

    var body: some View {
        AppSurfaceCard(contentPadding: 14) {
            VStack(alignment: .leading, spacing: 12) {
                ZStack {
                    Circle()
                        .fill(accent.opacity(0.16))

                    Image(systemName: "plus")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(accent)
                }
                .frame(width: 36, height: 36)

                Text("Add a verse")
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(.primary)

                Text("Save your own Scripture, translation, title, description, and icon for this focus area.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                Button {
                    action()
                } label: {
                    Label("Add Verse", systemImage: "plus.circle.fill")
                        .frame(maxWidth: .infinity)
                }
                .ifAvailableGlassProminent(tint: accent)
            }
            .frame(minHeight: 168, alignment: .topLeading)
        }
        .frame(maxWidth: 300, alignment: .center)
    }
}

private struct AddDefenseVerseSheetView: View {
    let accent: Color
    let verse: BibleDefenseVerse?
    let onSave: (BibleDefenseVerse) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var title: String
    @State private var reference: String
    @State private var excerpt: String
    @State private var translation: String
    @State private var application: String
    @State private var symbol: String

    init(accent: Color, verse: BibleDefenseVerse? = nil, onSave: @escaping (BibleDefenseVerse) -> Void) {
        self.accent = accent
        self.verse = verse
        self.onSave = onSave
        self._title = State(initialValue: verse?.title ?? "")
        self._reference = State(initialValue: verse?.reference ?? "")
        self._excerpt = State(initialValue: verse?.excerpt ?? "")
        self._translation = State(initialValue: verse?.translation ?? "")
        self._application = State(initialValue: verse?.application ?? "")
        self._symbol = State(initialValue: verse?.symbol ?? "book.fill")
    }

    private let suggestedSymbols = [
        "book.fill",
        "shield.lefthalf.filled",
        "cross.fill",
        "heart.fill",
        "flame.fill",
        "hands.sparkles.fill",
        "sun.max.fill",
        "checkmark.seal.fill"
    ]

    private var canSave: Bool {
        !trimmed(title).isEmpty && !trimmed(reference).isEmpty && !trimmed(excerpt).isEmpty && !trimmed(translation).isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Verse") {
                    TextField("Example: Stand Firm", text: $title)
                    TextField("Example: Romans 8:13", text: $reference)
                    TextField("Example: NKJV", text: $translation)
                        .textInputAutocapitalization(.characters)

                    TextEditor(text: $excerpt)
                        .frame(minHeight: 90)
                        .overlay(alignment: .topLeading) {
                            if excerpt.isEmpty {
                                Text("Example: If by the Spirit you put to death the deeds of the body, you will live.")
                                    .foregroundStyle(.secondary)
                                    .padding(.top, 8)
                                    .padding(.leading, 4)
                                    .allowsHitTesting(false)
                            }
                        }
                }

                Section("Description") {
                    TextEditor(text: $application)
                        .frame(minHeight: 84)
                        .overlay(alignment: .topLeading) {
                            if application.isEmpty {
                                Text("Example: Pray this when temptation starts to feel urgent.")
                                    .foregroundStyle(.secondary)
                                    .padding(.top, 8)
                                    .padding(.leading, 4)
                                    .allowsHitTesting(false)
                            }
                        }
                }

                Section("Icon") {
                    HStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(accent.opacity(0.16))

                            Image(systemName: trimmed(symbol).isEmpty ? "book.fill" : trimmed(symbol))
                                .font(.headline.weight(.semibold))
                                .foregroundStyle(accent)
                        }
                        .frame(width: 42, height: 42)

                        TextField("Example: shield.lefthalf.filled", text: $symbol)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                    }

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(suggestedSymbols, id: \.self) { suggestedSymbol in
                                Button {
                                    symbol = suggestedSymbol
                                } label: {
                                    Image(systemName: suggestedSymbol)
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundStyle(symbol == suggestedSymbol ? Color.white : accent)
                                        .frame(width: 34, height: 34)
                                        .background(symbol == suggestedSymbol ? accent : accent.opacity(0.12), in: Circle())
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.vertical, 2)
                    }
                }
            }
            .navigationTitle(verse == nil ? "New Verse" : "Edit Verse")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveVerse()
                    }
                    .fontWeight(.semibold)
                    .disabled(!canSave)
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    private func saveVerse() {
        onSave(
            BibleDefenseVerse(
                id: verse?.id ?? UUID(),
                title: trimmed(title),
                reference: trimmed(reference),
                translation: trimmed(translation),
                excerpt: trimmed(excerpt),
                application: trimmed(application).isEmpty ? "Personal defense verse." : trimmed(application),
                symbol: trimmed(symbol).isEmpty ? "book.fill" : trimmed(symbol)
            )
        )
        dismiss()
    }

    private func trimmed(_ value: String) -> String {
        value.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

#Preview {
    DefenseVersesSheetView(category: .item("Evil Thoughts", "Unclean or destructive thoughts", icon: "brain.head.profile", tint: .gray, watchword: "Guarded", progress: 0.58))
        .environment(AppPreferenceStore())
}
