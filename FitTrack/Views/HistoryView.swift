//
//  HistoryView.swift
//  FitTrack
//

import SwiftUI
import SwiftData

struct HistoryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \WorkoutSession.date, order: .reverse) private var sessions: [WorkoutSession]

    var body: some View {
        NavigationStack {
            Group {
                if sessions.isEmpty {
                    emptyState
                } else {
                    sessionsList
                }
            }
            .navigationTitle("История")
        }
    }

    // MARK: - Empty State
    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "calendar.badge.clock")
                .font(.system(size: 64))
                .foregroundStyle(.secondary)

            Text("Пока нет тренировок")
                .font(.title3)
                .foregroundStyle(.secondary)

            Text("Завершите первую тренировку,\nчтобы увидеть историю")
                .font(.subheadline)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }

    // MARK: - Sessions List
    private var sessionsList: some View {
        List {
            // Stats
            Section {
                statsSection
            }

            // Workouts list
            Section("Тренировки") {
                ForEach(sessions) { session in
                    SessionRow(session: session)
                }
                .onDelete(perform: deleteSessions)
            }
        }
        .listStyle(.insetGrouped)
    }

    // MARK: - Stats Section
    private var statsSection: some View {
        VStack(spacing: 16) {
            HStack(spacing: 16) {
                StatBox(
                    title: "Всего",
                    value: "\(sessions.count)",
                    subtitle: "тренировок",
                    color: .orange
                )

                StatBox(
                    title: "Время",
                    value: totalTimeFormatted,
                    subtitle: "общее",
                    color: .blue
                )
            }

            HStack(spacing: 16) {
                StatBox(
                    title: "Эта неделя",
                    value: "\(thisWeekCount)",
                    subtitle: "тренировок",
                    color: .green
                )

                StatBox(
                    title: "Серия",
                    value: "\(currentStreak)",
                    subtitle: "недель подряд",
                    color: .purple
                )
            }
        }
        .listRowInsets(EdgeInsets())
        .listRowBackground(Color.clear)
        .padding(.vertical, 8)
    }

    private var totalTimeFormatted: String {
        let totalMinutes = sessions.reduce(0) { $0 + Int($1.duration) / 60 }
        if totalMinutes >= 60 {
            let hours = totalMinutes / 60
            let mins = totalMinutes % 60
            return "\(hours)ч \(mins)м"
        }
        return "\(totalMinutes)м"
    }

    private var thisWeekCount: Int {
        let calendar = Calendar.current
        let startOfWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date()))!
        return sessions.filter { $0.date >= startOfWeek }.count
    }

    private var currentStreak: Int {
        // Simple streak calculation (consecutive weeks with workouts)
        var streak = 0
        let calendar = Calendar.current
        var checkDate = Date()

        for _ in 0..<52 { // Check up to a year back
            let weekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: checkDate))!
            let weekEnd = calendar.date(byAdding: .day, value: 7, to: weekStart)!

            let hasWorkoutInWeek = sessions.contains { session in
                session.date >= weekStart && session.date < weekEnd
            }

            if hasWorkoutInWeek {
                streak += 1
                checkDate = calendar.date(byAdding: .day, value: -7, to: checkDate)!
            } else {
                break
            }
        }

        return streak
    }

    private func deleteSessions(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(sessions[index])
        }
    }
}

// MARK: - Stat Box
struct StatBox: View {
    let title: String
    let value: String
    let subtitle: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)

            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundStyle(color)

            Text(subtitle)
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Session Row
struct SessionRow: View {
    let session: WorkoutSession

    private var workoutDay: WorkoutDay? {
        WorkoutDay(rawValue: session.workoutDay)
    }

    var body: some View {
        HStack(spacing: 12) {
            // Icon
            ZStack {
                Circle()
                    .fill(accentColor.opacity(0.15))
                    .frame(width: 44, height: 44)

                Image(systemName: workoutDay?.icon ?? "figure.walk")
                    .foregroundStyle(accentColor)
            }

            // Info
            VStack(alignment: .leading, spacing: 4) {
                Text(workoutDay?.shortTitle ?? "Тренировка")
                    .font(.headline)

                Text(session.date, style: .date)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            // Stats
            VStack(alignment: .trailing, spacing: 4) {
                Text(session.formattedDuration)
                    .font(.headline)
                    .foregroundStyle(accentColor)

                HStack(spacing: 4) {
                    if session.isCompleted {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                            .font(.caption)
                    }
                    Text("\(session.completedExercises)/\(session.totalExercises)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
    }

    private var accentColor: Color {
        switch workoutDay?.accentColor {
        case "orange": return .orange
        case "blue": return .blue
        case "green": return .green
        default: return .orange
        }
    }
}

#Preview {
    HistoryView()
        .modelContainer(for: [WorkoutSession.self, CompletedExercise.self])
}
