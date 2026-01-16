//
//  SettingsView.swift
//  FitTrack
//

import SwiftUI
import UserNotifications

struct SettingsView: View {
    @AppStorage("notificationsEnabled") private var notificationsEnabled = false
    @AppStorage("notificationTime") private var notificationTime = Date.defaultNotificationTime
    @AppStorage("restTimerDuration") private var restTimerDuration = 90

    @State private var showingNotificationAlert = false

    var body: some View {
        NavigationStack {
            List {
                // Notifications
                Section {
                    Toggle("Напоминания о тренировках", isOn: $notificationsEnabled)
                        .onChange(of: notificationsEnabled) { _, newValue in
                            if newValue {
                                requestNotificationPermission()
                            } else {
                                cancelNotifications()
                            }
                        }

                    if notificationsEnabled {
                        DatePicker(
                            "Время напоминания",
                            selection: $notificationTime,
                            displayedComponents: .hourAndMinute
                        )
                        .onChange(of: notificationTime) { _, _ in
                            scheduleNotifications()
                        }

                        HStack {
                            Image(systemName: "info.circle")
                                .foregroundStyle(.secondary)
                            Text("ПН, СР, ПТ")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                } header: {
                    Text("Уведомления")
                } footer: {
                    Text("Напоминания будут приходить в дни тренировок")
                }

                // Rest timer
                Section("Таймер отдыха") {
                    Picker("Время по умолчанию", selection: $restTimerDuration) {
                        Text("30 сек").tag(30)
                        Text("60 сек").tag(60)
                        Text("90 сек").tag(90)
                        Text("120 сек").tag(120)
                        Text("180 сек").tag(180)
                    }
                }

                // About
                Section("О приложении") {
                    HStack {
                        Text("Версия")
                        Spacer()
                        Text("1.0.0")
                            .foregroundStyle(.secondary)
                    }

                    HStack {
                        Text("Разработчик")
                        Spacer()
                        Text("FitTrack")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("Настройки")
        }
        .alert("Уведомления отключены", isPresented: $showingNotificationAlert) {
            Button("Открыть настройки") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            Button("Отмена", role: .cancel) {
                notificationsEnabled = false
            }
        } message: {
            Text("Разрешите уведомления в настройках, чтобы получать напоминания о тренировках")
        }
    }

    // MARK: - Notifications
    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, _ in
            DispatchQueue.main.async {
                if granted {
                    scheduleNotifications()
                } else {
                    showingNotificationAlert = true
                }
            }
        }
    }

    private func scheduleNotifications() {
        cancelNotifications()

        let content = UNMutableNotificationContent()
        content.title = "Время тренировки!"
        content.body = "Не забудь про сегодняшнюю тренировку"
        content.sound = .default

        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: notificationTime)
        let minute = calendar.component(.minute, from: notificationTime)

        // Mon (2), Wed (4), Fri (6)
        let workoutDays = [2, 4, 6]

        for weekday in workoutDays {
            var dateComponents = DateComponents()
            dateComponents.weekday = weekday
            dateComponents.hour = hour
            dateComponents.minute = minute

            let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
            let request = UNNotificationRequest(
                identifier: "workout-\(weekday)",
                content: content,
                trigger: trigger
            )

            UNUserNotificationCenter.current().add(request)
        }
    }

    private func cancelNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }
}

// MARK: - Date Extension
extension Date {
    static var defaultNotificationTime: Date {
        var components = DateComponents()
        components.hour = 18
        components.minute = 0
        return Calendar.current.date(from: components) ?? Date()
    }
}

#Preview {
    SettingsView()
}
