//
//  HomeView.swift
//  FitTrack
//

import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \WorkoutSession.date, order: .reverse) private var sessions: [WorkoutSession]

    @State private var selectedDay: WorkoutDay?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    headerSection

                    // Workout cards
                    workoutCardsSection

                    // Last workout
                    if let lastSession = sessions.first {
                        lastWorkoutSection(session: lastSession)
                    }

                    // Week stats
                    weekStatsSection
                }
                .padding()
            }
            .background(Color(.systemBackground))
            .navigationDestination(item: $selectedDay) { day in
                WorkoutView(workoutDay: day)
            }
        }
    }

    // MARK: - Header
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(greeting)
                .font(.title3)
                .foregroundStyle(.secondary)

            Text("Готов к тренировке?")
                .font(.largeTitle)
                .fontWeight(.bold)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return "Доброе утро"
        case 12..<18: return "Добрый день"
        default: return "Добрый вечер"
        }
    }

    // MARK: - Workout Cards
    private var workoutCardsSection: some View {
        VStack(spacing: 16) {
            ForEach(WorkoutDay.allCases, id: \.self) { day in
                WorkoutDayCard(
                    day: day,
                    isToday: isTodayWorkout(day),
                    lastSession: lastSession(for: day)
                ) {
                    selectedDay = day
                }
            }
        }
    }

    private func isTodayWorkout(_ day: WorkoutDay) -> Bool {
        let weekday = Calendar.current.component(.weekday, from: Date())
        switch day {
        case .day1: return weekday == 2 // Monday
        case .day2: return weekday == 4 // Wednesday
        case .day3: return weekday == 6 // Friday
        }
    }

    private func lastSession(for day: WorkoutDay) -> WorkoutSession? {
        sessions.first { $0.workoutDay == day.rawValue }
    }

    // MARK: - Last Workout
    private func lastWorkoutSection(session: WorkoutSession) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Последняя тренировка")
                .font(.headline)
                .foregroundStyle(.secondary)

            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    if let day = WorkoutDay(rawValue: session.workoutDay) {
                        Text(day.shortTitle)
                            .font(.title3)
                            .fontWeight(.semibold)
                    }

                    Text(session.date, style: .date)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text(session.formattedDuration)
                        .font(.title3)
                        .fontWeight(.semibold)

                    Text("мин")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            .padding()
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }

    // MARK: - Week Stats
    private var weekStatsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Эта неделя")
                .font(.headline)
                .foregroundStyle(.secondary)

            HStack(spacing: 16) {
                StatCard(
                    title: "Тренировок",
                    value: "\(weekSessionsCount)",
                    icon: "flame.fill",
                    color: .orange
                )

                StatCard(
                    title: "Время",
                    value: weekTotalTime,
                    icon: "clock.fill",
                    color: .blue
                )
            }
        }
    }

    private var weekSessionsCount: Int {
        let calendar = Calendar.current
        let startOfWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date()))!
        return sessions.filter { $0.date >= startOfWeek }.count
    }

    private var weekTotalTime: String {
        let calendar = Calendar.current
        let startOfWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date()))!
        let totalMinutes = sessions
            .filter { $0.date >= startOfWeek }
            .reduce(0) { $0 + Int($1.duration) / 60 }
        return "\(totalMinutes) мин"
    }
}

// MARK: - Workout Day Card
struct WorkoutDayCard: View {
    let day: WorkoutDay
    let isToday: Bool
    let lastSession: WorkoutSession?
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                // Icon
                ZStack {
                    Circle()
                        .fill(accentColor.opacity(0.15))
                        .frame(width: 56, height: 56)

                    Image(systemName: day.icon)
                        .font(.title2)
                        .foregroundStyle(accentColor)
                }

                // Text
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(day.shortTitle)
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundStyle(.primary)

                        if isToday {
                            Text("Сегодня")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundStyle(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(accentColor)
                                .clipShape(Capsule())
                        }
                    }

                    Text(day.title)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    Text(day.weekday)
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }

                Spacer()

                // Arrow
                Image(systemName: "chevron.right")
                    .font(.title3)
                    .foregroundStyle(.tertiary)
            }
            .padding()
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isToday ? accentColor : .clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }

    private var accentColor: Color {
        switch day.accentColor {
        case "orange": return .orange
        case "blue": return .blue
        case "green": return .green
        default: return .orange
        }
    }
}

// MARK: - Stat Card
struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)

            Text(value)
                .font(.title2)
                .fontWeight(.bold)

            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

#Preview {
    HomeView()
        .modelContainer(for: [WorkoutSession.self, CompletedExercise.self])
}
