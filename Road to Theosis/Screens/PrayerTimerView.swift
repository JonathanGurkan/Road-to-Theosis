import SwiftUI
import Combine
import UIKit

struct PrayerTimerView: View {
    @Binding var backgroundTheme: AppBackgroundTheme
    @Environment(AppPreferenceStore.self) private var preferences
    let onSave: (LogEntry) -> Void
    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase
    @State private var elapsedSeconds: Int = 0
    @State private var isRunning = true
    @State private var prayerNote = ""
    @State private var connectedPrayerSins: Set<ConnectedSinReference> = []
    @State private var startedAt = Date()
    @State private var hasStartedSession = false
    @State private var hasStoppedSession = false
    @State private var isShowingDiscardConfirmation = false

    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    private var prayerTimerCountingMode: PrayerTimerCountingMode {
        preferences.prayerTimerCountingMode
    }

    private var currentElapsedSeconds: Int {
        switch prayerTimerCountingMode {
        case .foreground:
            return elapsedSeconds
        case .background:
            guard isRunning else { return elapsedSeconds }
            return max(0, Int(Date().timeIntervalSince(startedAt)))
        }
    }

    private var shouldKeepScreenAwake: Bool {
        prayerTimerCountingMode == .foreground && preferences.keepScreenAwakeDuringPrayer
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackgroundView(theme: backgroundTheme)

                if hasStoppedSession {
                    notesView
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                } else {
                    focusView
                        .transition(.opacity)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(hasStoppedSession ? .visible : .hidden, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    if hasStoppedSession {
                        Button("Cancel") {
                            isShowingDiscardConfirmation = true
                        }
                    }
                }
            }
        }
        .interactiveDismissDisabled(isRunning)
        .onAppear {
            startSessionIfNeeded()
            if shouldKeepScreenAwake {
                UIApplication.shared.isIdleTimerDisabled = true
            }
        }
        .onDisappear {
            if shouldKeepScreenAwake {
                UIApplication.shared.isIdleTimerDisabled = false
            }
        }
        .onReceive(timer) { _ in
            guard isRunning else { return }
            tickElapsedSeconds()
        }
        .onChange(of: scenePhase) { _, newPhase in
            guard newPhase == .active, isRunning else { return }
            refreshElapsedSeconds()
        }
        .confirmationDialog(
            "Discard prayer session?",
            isPresented: $isShowingDiscardConfirmation,
            titleVisibility: .visible
        ) {
            Button("Yes", role: .destructive) {
                discardSession()
            }
            Button("No, keep Praying", role: .cancel) { }
        } message: {
            Text("This prayer session will not be saved to your timeline.")
        }
    }

    private var focusView: some View {
        VStack(spacing: 34) {
            Spacer(minLength: 24)

            VStack(spacing: 10) {
                Text("Keep focusing on prayer")
                    .font(.largeTitle.weight(.semibold))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.primary)

                Text(prayerTimerCountingMode.runningInstruction)
                    .font(.subheadline)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, 28)

            if prayerTimerCountingMode == .background {
                backgroundEncouragement
            } else {
                foregroundTimerRing
            }

            Spacer(minLength: 20)

            HStack(spacing: 16) {
                Button {
                    stopSession()
                } label: {
                    Image(systemName: "checkmark")
                        .font(.title3.weight(.semibold))
                        .frame(width: 72, height: 54)
                }
                .ifAvailableGlassProminent(tint: backgroundTheme.glowColor)
                .accessibilityLabel("Stop session and add notes")

                Button(role: .cancel) {
                    isShowingDiscardConfirmation = true
                } label: {
                    Image(systemName: "xmark")
                        .font(.title3.weight(.semibold))
                        .frame(width: 72, height: 54)
                }
                .ifAvailableGlass(tint: .red)
                .accessibilityLabel("Discard prayer session")
            }
            .padding(.horizontal, 28)
            .padding(.bottom, 28)
        }
    }

    private var foregroundTimerRing: some View {
        VStack() {
            Text("Time elapsed")
                .font(.caption.weight(.semibold))
                .foregroundStyle(backgroundTheme.glowColor)
                .textCase(.uppercase)
            
            Text(formatElapsedTime(currentElapsedSeconds))
                .font(.system(size: 58, weight: .semibold, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(.primary)
        }
        .frame(width: 238, height: 238)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Prayer timer, \(formatElapsedTime(currentElapsedSeconds)) elapsed")
    }

    private var backgroundEncouragement: some View {
        VStack(spacing: 14) {
            Image(systemName: "hands.sparkles.fill")
                .font(.system(size: 62, weight: .semibold))
                .foregroundStyle(backgroundTheme.glowColor)

            Text("God is with you in this moment.")
                .font(.title2.weight(.semibold))
                .multilineTextAlignment(.center)
                .foregroundStyle(.primary)

            Text("Set the phone aside, breathe, and keep your heart on prayer.")
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, 34)
        .accessibilityElement(children: .combine)
    }

    private var notesView: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 18) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Prayer session")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(backgroundTheme.glowColor)
                        .textCase(.uppercase)

                    Text("Add notes if needed")
                        .font(.largeTitle.weight(.semibold))
                        .foregroundStyle(.primary)

                    Text("\(savedPrayerDurationText) will be added to your timeline.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                PrayerSinPickerView(
                    title: "Connected sins",
                    subtitle: "Attach one or more sins to this prayer session.",
                    selectedReferences: $connectedPrayerSins
                )

                TextEditor(text: $prayerNote)
                    .frame(minHeight: 170)
                    .padding(12)
                    .background(Color(uiColor: .secondarySystemBackground), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .strokeBorder(Color.primary.opacity(0.08), lineWidth: 1)
                    )
                    .scrollContentBackground(.hidden)

                VStack(spacing: 10) {
                    Button {
                        saveSession()
                    } label: {
                        Text("Save Session")
                            .font(.headline.weight(.semibold))
                            .frame(maxWidth: .infinity)
                    }
                    .ifAvailableGlassProminent(tint: backgroundTheme.glowColor)

                    Button {
                        prayerNote = ""
                        saveSession()
                    } label: {
                        Text("Skip Notes")
                            .font(.subheadline.weight(.semibold))
                            .frame(maxWidth: .infinity)
                    }
                    .ifAvailableGlass(tint: backgroundTheme.glowColor)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 28)
            .padding(.bottom, 28)
        }
    }

    private var progress: Double {
        min(1, Double(currentElapsedSeconds) / 3600.0)
    }

    private var savedPrayerMinutes: Int {
        max(1, Int(ceil(Double(max(elapsedSeconds, 1)) / 60.0)))
    }

    private var savedPrayerDurationText: String {
        LogEntry.formatPrayerDuration(seconds: elapsedSeconds)
    }

    private func startSessionIfNeeded() {
        guard !hasStartedSession else { return }
        startedAt = .now
        elapsedSeconds = 0
        isRunning = true
        hasStoppedSession = false
        hasStartedSession = true
    }

    private func stopSession() {
        refreshElapsedSeconds()
        elapsedSeconds = currentElapsedSeconds
        isRunning = false
        hasStoppedSession = true

        if shouldKeepScreenAwake {
            UIApplication.shared.isIdleTimerDisabled = false
        }
    }

    private func tickElapsedSeconds() {
        switch prayerTimerCountingMode {
        case .foreground:
            elapsedSeconds += 1
        case .background:
            refreshElapsedSeconds()
        }
    }

    private func refreshElapsedSeconds() {
        guard prayerTimerCountingMode == .background else { return }
        elapsedSeconds = max(0, Int(Date().timeIntervalSince(startedAt)))
    }

    private func discardSession() {
        isRunning = false
        if shouldKeepScreenAwake {
            UIApplication.shared.isIdleTimerDisabled = false
        }
        dismiss()
    }

    private func saveSession() {
        let entry = LogEntry(
            kind: .prayer,
            sectionTitle: "Prayer",
            sinTitle: nil,
            note: prayerNote.trimmingCharacters(in: .whitespacesAndNewlines),
            prayerMinutes: savedPrayerMinutes,
            prayerDurationSeconds: elapsedSeconds,
            connectedSins: ConnectedSinReference.ordered(connectedPrayerSins),
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
        .environment(AppPreferenceStore())
}
