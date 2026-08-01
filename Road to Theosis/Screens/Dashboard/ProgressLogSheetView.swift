import SwiftUI

struct ProgressLogDraft: Identifiable {
    let id = UUID()
    let sectionTitle: String
    let sinTitle: String
    let progressPercentage: Int
    let tint: Color

    var frequencyLabel: String {
        SinFrequencyScale.label(for: progressPercentage)
    }
}

struct ProgressLogSheetView: View {
    @Binding var backgroundTheme: AppBackgroundTheme
    let draft: ProgressLogDraft
    let onSave: (String) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var note = ""

    private var trimmedNote: String {
        note.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackgroundView(theme: backgroundTheme)

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 16) {
                        AppSurfaceCard {
                            VStack(alignment: .leading, spacing: 10) {
                                Text("Add Log")
                                    .font(.largeTitle.weight(.semibold))
                                    .foregroundStyle(.primary)

                                Text("Frequency changed to \(draft.frequencyLabel).")
                                    .font(.callout)
                                    .foregroundStyle(.secondary)

                                HStack(alignment: .center, spacing: 12) {
                                    ZStack {
                                        Circle()
                                            .fill(draft.tint.opacity(0.16))

                                        Image(systemName: "calendar.badge.clock")
                                            .font(.subheadline.weight(.semibold))
                                            .foregroundStyle(draft.tint)
                                    }
                                    .frame(width: 34, height: 34)

                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(draft.sinTitle)
                                            .font(.headline.weight(.semibold))
                                            .foregroundStyle(.primary)
                                            .fixedSize(horizontal: false, vertical: true)

                                        Text(draft.sectionTitle)
                                            .font(.caption.weight(.semibold))
                                            .foregroundStyle(.secondary)
                                    }

                                    Spacer(minLength: 8)
                                }
                            }
                        }

                        AppSurfaceCard {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Note")
                                    .font(.headline.weight(.semibold))
                                    .foregroundStyle(.primary)

                                Text("Add context for this frequency change, or save it without a note.")
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
                    Button(trimmedNote.isEmpty ? "Skip Note" : "Save") {
                        onSave(trimmedNote)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
}

#Preview {
    ProgressLogSheetView(
        backgroundTheme: .constant(.blood),
        draft: ProgressLogDraft(sectionTitle: "Sins Against God", sinTitle: "Neglect of Prayer", progressPercentage: 64, tint: .green)
    ) { _ in }
}
