//
//  RestTimerOverlay.swift
//  FitTrack
//

import SwiftUI
import UserNotifications
import AudioToolbox

struct RestTimerOverlay: View {
    @Binding var isShowing: Bool
    @Environment(\.scenePhase) private var scenePhase

    @AppStorage("restTimerDuration") private var defaultDuration: Int = 90

    @State private var timeRemaining: Int = 90
    @State private var selectedDuration: Int = 90
    @State private var isRunning = false
    @State private var timer: Timer?
    @State private var endTime: Date?

    private let durations = [30, 60, 90, 120, 180]

    var body: some View {
        ZStack {
            // Background dimming
            Color.black.opacity(0.85)
                .ignoresSafeArea()
                .onTapGesture {
                    if !isRunning {
                        isShowing = false
                    }
                }

            VStack(spacing: 32) {
                // Header
                HStack {
                    Text("Отдых")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)

                    Spacer()

                    Button {
                        stopTimer()
                        isShowing = false
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundStyle(.white.opacity(0.6))
                    }
                }

                // Circular timer
                ZStack {
                    // Circle background
                    Circle()
                        .stroke(Color.white.opacity(0.2), lineWidth: 12)
                        .frame(width: 200, height: 200)

                    // Progress
                    Circle()
                        .trim(from: 0, to: progress)
                        .stroke(
                            Color.orange,
                            style: StrokeStyle(lineWidth: 12, lineCap: .round)
                        )
                        .frame(width: 200, height: 200)
                        .rotationEffect(.degrees(-90))
                        .animation(.linear(duration: 1), value: progress)

                    // Time display
                    VStack(spacing: 4) {
                        Text(formatTime(timeRemaining))
                            .font(.system(size: 56, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                            .monospacedDigit()

                        Text("секунд")
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.6))
                    }
                }

                // Duration selection
                if !isRunning {
                    HStack(spacing: 12) {
                        ForEach(durations, id: \.self) { duration in
                            Button {
                                selectedDuration = duration
                                timeRemaining = duration
                            } label: {
                                Text("\(duration)с")
                                    .font(.headline)
                                    .foregroundStyle(selectedDuration == duration ? .black : .white)
                                    .frame(width: 56, height: 44)
                                    .background(selectedDuration == duration ? Color.orange : Color.white.opacity(0.2))
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                            }
                        }
                    }
                }

                // Control buttons
                HStack(spacing: 20) {
                    if isRunning {
                        // Add 30 seconds
                        Button {
                            timeRemaining += 30
                            // Update scheduled notification
                            if let currentEnd = endTime {
                                endTime = currentEnd.addingTimeInterval(30)
                                scheduleTimerNotification()
                            }
                        } label: {
                            Label("+30с", systemImage: "plus")
                                .font(.headline)
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.white.opacity(0.2))
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                        }

                        // Skip
                        Button {
                            stopTimer()
                            isShowing = false
                        } label: {
                            Label("Пропустить", systemImage: "forward.fill")
                                .font(.headline)
                                .foregroundStyle(.black)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.orange)
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                        }
                    } else {
                        // Start
                        Button {
                            startTimer()
                        } label: {
                            Label("Старт", systemImage: "play.fill")
                                .font(.headline)
                                .foregroundStyle(.black)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.orange)
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                        }
                    }
                }
            }
            .padding(24)
        }
        .onAppear {
            // Load default duration from settings
            selectedDuration = defaultDuration
            timeRemaining = defaultDuration
            requestNotificationPermission()
        }
        .onDisappear {
            stopTimer()
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active && isRunning {
                // Recalculate time remaining when app becomes active
                if let end = endTime {
                    let remaining = Int(end.timeIntervalSince(Date()))
                    if remaining <= 0 {
                        timerFinished()
                    } else {
                        timeRemaining = remaining
                    }
                }
            }
        }
    }

    private var progress: Double {
        guard selectedDuration > 0 else { return 0 }
        return Double(timeRemaining) / Double(selectedDuration)
    }

    private func formatTime(_ seconds: Int) -> String {
        let mins = seconds / 60
        let secs = seconds % 60
        if mins > 0 {
            return String(format: "%d:%02d", mins, secs)
        }
        return "\(secs)"
    }

    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }

    private func startTimer() {
        isRunning = true
        endTime = Date().addingTimeInterval(TimeInterval(timeRemaining))

        // Schedule notification for when timer ends
        scheduleTimerNotification()

        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            if timeRemaining > 0 {
                timeRemaining -= 1
            } else {
                timerFinished()
            }
        }
    }

    private func scheduleTimerNotification() {
        // Cancel any existing timer notification
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["rest-timer"])

        guard let end = endTime else { return }

        let content = UNMutableNotificationContent()
        content.title = "Отдых окончен!"
        content.body = "Время следующего подхода"
        content.sound = UNNotificationSound.default
        // Make it time-sensitive so it shows on lock screen and breaks through Focus
        content.interruptionLevel = .timeSensitive

        let timeInterval = end.timeIntervalSince(Date())
        guard timeInterval > 0 else { return }

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: timeInterval, repeats: false)
        let request = UNNotificationRequest(identifier: "rest-timer", content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request)
    }

    private func timerFinished() {
        timer?.invalidate()
        timer = nil
        isRunning = false
        endTime = nil

        // Strong haptic feedback (works reliably in foreground)
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(.success)

        // Play alert sound
        AudioServicesPlayAlertSound(SystemSoundID(1005))

        // Repeat haptic after short delays to make it noticeable
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            generator.notificationOccurred(.success)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            generator.notificationOccurred(.success)
        }

        // Dismiss after vibrations complete
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            timeRemaining = selectedDuration
            isShowing = false
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
        isRunning = false
        endTime = nil
        timeRemaining = selectedDuration

        // Cancel scheduled notification
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["rest-timer"])
    }
}

#Preview {
    RestTimerOverlay(isShowing: .constant(true))
}
