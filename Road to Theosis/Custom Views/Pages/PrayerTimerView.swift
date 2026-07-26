import SwiftUI
import Combine
import UIKit

struct PrayerTimerView: View {
    @Binding var backgroundTheme: AppBackgroundTheme
    let onSave: (LogEntry) -> Void
    @Environment(\.dismiss) private var dismiss
    @AppStorage("keepScreenAwakeDuringPrayer") private var keepScreenAwakeDuringPrayer = true

    @State private var elapsedSeconds: Int = 0
    @State private var isRunning = false
    @State private var prayerNote = ""
    @State private var startedAt = Date()

    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackgroundView(theme: backgroundTheme)

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 20) {
                        heroCard
                        timerCard
                        intentionCard
                        controlCard
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                    .padding(.bottom, 24)
                }
            }
            .navigationTitle("Prayer Focus")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
        .interactiveDismissDisabled(isRunning)
        .onAppear {
            if keepScreenAwakeDuringPrayer {
                UIApplication.shared.isIdleTimerDisabled = true
            }
        }
        .onDisappear {
            if keepScreenAwakeDuringPrayer {
                UIApplication.shared.isIdleTimerDisabled = false
            }
        }
        .onReceive(timer) { _ in
            guard isRunning else { return }
            elapsedSeconds += 1
        }
    }

    private var heroCard: some View {
        AppSurfaceCard {
            VStack(alignment: .leading, spacing: 8) {
                Label("Non-distracting mode", systemImage: "moon.stars.fill")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(backgroundTheme.glowColor)
                    .textCase(.uppercase)

                Text(isRunning ? "Stay with the prayer" : "Set a quiet window")
                    .font(.title.weight(.semibold))
                    .foregroundStyle(.primary)

                Text(isRunning ? "Leave the phone and pray. Stop the session when you are done, and it will be added to the timeline." : "Start the session, leave the phone, and pray without distraction. When you stop, the time is saved.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var timerCard: some View {
        AppSurfaceCard {
            VStack(alignment: .center, spacing: 16) {
                ZStack {
                    Circle()
                        .stroke(Color.primary.opacity(0.08), lineWidth: 12)

                    Circle()
                        .trim(from: 0, to: progress)
                        .stroke(backgroundTheme.glowColor, style: StrokeStyle(lineWidth: 12, lineCap: .round))
                        .rotationEffect(.degrees(-90))

                    VStack(spacing: 6) {
                        Text(formatElapsedTime(elapsedSeconds))
                            .font(.system(size: 54, weight: .semibold, design: .rounded))
                            .monospacedDigit()
                            .foregroundStyle(.primary)

                        Text(isRunning ? "Running" : "Ready")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(backgroundTheme.glowColor)
                    }
                }
                .frame(width: 220, height: 220)

                Text(isRunning ? "Keep your attention on prayer, not the clock." : "Tap start, then leave the phone alone and pray.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
    }

    private var intentionCard: some View {
        AppSurfaceCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("Intention")
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(.primary)

                TextField("What are you bringing to prayer?", text: $prayerNote, axis: .vertical)
                    .textFieldStyle(.plain)
                    .padding(12)
                    .background(Color(uiColor: .secondarySystemBackground), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .strokeBorder(Color.primary.opacity(0.08), lineWidth: 1)
                    )
                    .disabled(isRunning)
                    .opacity(isRunning ? 0.8 : 1)
            }
        }
    }

    private var controlCard: some View {
        AppSurfaceCard {
            VStack(spacing: 12) {
                if isRunning {
                    Button {
                        Task {
                            await finishSession()
                        }
                    } label: {
                        Text("Stop and Save")
                            .frame(maxWidth: .infinity)
                    }
                    .ifAvailableGlassProminent(tint: backgroundTheme.glowColor)
                } else {
                    Button {
                        Task {
                            await startSession()
                        }
                    } label: {
                        Text("Start Prayer Timer")
                            .frame(maxWidth: .infinity)
                    }
                    .ifAvailableGlassProminent(tint: backgroundTheme.glowColor)
                }
            }
        }
    }

    private var progress: Double {
        min(1, Double(elapsedSeconds) / 3600.0)
    }

    @MainActor
    private func startSession() async {
        startedAt = .now
        elapsedSeconds = 0
        isRunning = true

    }

    @MainActor
    private func finishSession() async {
        let prayerMinutes = max(1, Int(ceil(Double(max(elapsedSeconds, 1)) / 60.0)))

        let entry = LogEntry(
            kind: .prayer,
            sectionTitle: "Prayer",
            sinTitle: nil,
            note: prayerNote.trimmingCharacters(in: .whitespacesAndNewlines),
            prayerMinutes: prayerMinutes,
            occurredAt: startedAt
        )

        onSave(entry)
        dismiss()
    }

    private func formatElapsedTime(_ seconds: Int) -> String {
        let minutes = seconds / 60
        let remaining = seconds % 60
        return String(format: "%02d:%02d", minutes, remaining)
    }
}

#Preview {
    PrayerTimerView(backgroundTheme: .constant(.blood)) { _ in }
}
