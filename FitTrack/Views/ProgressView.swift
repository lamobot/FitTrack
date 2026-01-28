//
//  ProgressView.swift
//  FitTrack
//

import SwiftUI
import SwiftData
import Charts

struct ProgressReportView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \WorkoutSession.date, order: .reverse) private var sessions: [WorkoutSession]
    @Query(sort: \CompletedExercise.date, order: .reverse) private var exercises: [CompletedExercise]

    @State private var selectedExercise: String = ""
    @State private var selectedPeriod: TimePeriod = .month

    private var exerciseNames: [String] {
        let names = Set(exercises.filter { $0.weight > 0 }.map { $0.exerciseName })
        return Array(names).sorted()
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    if sessions.isEmpty {
                        emptyState
                    } else {
                        // Period selector
                        periodSelector

                        // Activity calendar
                        activityCalendarSection

                        // Workout duration chart
                        durationChartSection

                        // Weight progress chart
                        if !exerciseNames.isEmpty {
                            weightProgressSection
                        }

                        // Summary stats
                        summarySection
                    }
                }
                .padding()
            }
            .navigationTitle("Прогресс")
            .onAppear {
                if selectedExercise.isEmpty, let first = exerciseNames.first {
                    selectedExercise = first
                }
            }
        }
    }

    // MARK: - Empty State
    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.system(size: 64))
                .foregroundStyle(.secondary)

            Text("Пока нет данных")
                .font(.title3)
                .foregroundStyle(.secondary)

            Text("Завершите несколько тренировок,\nчтобы увидеть прогресс")
                .font(.subheadline)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 100)
    }

    // MARK: - Period Selector
    private var periodSelector: some View {
        Picker("Период", selection: $selectedPeriod) {
            ForEach(TimePeriod.allCases, id: \.self) { period in
                Text(period.title).tag(period)
            }
        }
        .pickerStyle(.segmented)
    }

    // MARK: - Activity Calendar
    private var activityCalendarSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Активность")
                .font(.headline)

            ActivityCalendarView(sessions: filteredSessions)
                .frame(height: 140)
                .padding()
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }

    // MARK: - Duration Chart
    private var durationChartSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Время тренировок")
                .font(.headline)

            Chart(filteredSessions) { session in
                BarMark(
                    x: .value("Дата", session.date, unit: .day),
                    y: .value("Минуты", Int(session.duration) / 60)
                )
                .foregroundStyle(colorForDay(session.workoutDay))
                .cornerRadius(4)
            }
            .frame(height: 200)
            .chartXAxis {
                AxisMarks(values: .stride(by: .day, count: selectedPeriod == .week ? 1 : 7)) { _ in
                    AxisGridLine()
                    AxisValueLabel(format: .dateTime.day().month(.abbreviated))
                }
            }
            .chartYAxis {
                AxisMarks { mark in
                    AxisGridLine()
                    AxisValueLabel {
                        if let value = mark.as(Int.self) {
                            Text("\(value) мин")
                        }
                    }
                }
            }
            .padding()
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16))

            // Average duration
            HStack {
                Text("Среднее время:")
                    .foregroundStyle(.secondary)
                Spacer()
                Text("\(averageDuration) мин")
                    .fontWeight(.semibold)
            }
            .font(.subheadline)
        }
    }

    // MARK: - Weight Progress
    private var weightProgressSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Прогресс веса")
                    .font(.headline)
                Spacer()
            }

            // Exercise picker
            Menu {
                ForEach(exerciseNames, id: \.self) { name in
                    Button(name) {
                        selectedExercise = name
                    }
                }
            } label: {
                HStack {
                    Text(selectedExercise.isEmpty ? "Выберите упражнение" : selectedExercise)
                        .foregroundStyle(.primary)
                    Spacer()
                    Image(systemName: "chevron.down")
                        .foregroundStyle(.secondary)
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }

            if !selectedExercise.isEmpty {
                let exerciseData = weightDataForExercise(selectedExercise)

                if exerciseData.count >= 2 {
                    Chart(exerciseData) { item in
                        LineMark(
                            x: .value("Дата", item.date),
                            y: .value("Вес", item.weight)
                        )
                        .foregroundStyle(.orange)
                        .interpolationMethod(.catmullRom)

                        PointMark(
                            x: .value("Дата", item.date),
                            y: .value("Вес", item.weight)
                        )
                        .foregroundStyle(.orange)
                    }
                    .frame(height: 200)
                    .chartYScale(domain: .automatic(includesZero: false))
                    .chartXAxis {
                        AxisMarks { _ in
                            AxisGridLine()
                            AxisValueLabel(format: .dateTime.day().month(.abbreviated))
                        }
                    }
                    .chartYAxis {
                        AxisMarks { mark in
                            AxisGridLine()
                            AxisValueLabel {
                                if let value = mark.as(Double.self) {
                                    Text("\(Int(value)) кг")
                                }
                            }
                        }
                    }
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 16))

                    // Progress summary
                    if let first = exerciseData.first, let last = exerciseData.last {
                        let diff = last.weight - first.weight
                        HStack {
                            Text("Изменение:")
                                .foregroundStyle(.secondary)
                            Spacer()
                            HStack(spacing: 4) {
                                Image(systemName: diff >= 0 ? "arrow.up" : "arrow.down")
                                Text("\(abs(Int(diff))) кг")
                            }
                            .foregroundStyle(diff >= 0 ? .green : .red)
                            .fontWeight(.semibold)
                        }
                        .font(.subheadline)
                    }
                } else {
                    Text("Недостаточно данных для графика")
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                }
            }
        }
    }

    // MARK: - Summary
    private var summarySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("За период")
                .font(.headline)

            HStack(spacing: 12) {
                SummaryCard(
                    title: "Тренировок",
                    value: "\(filteredSessions.count)",
                    icon: "flame.fill",
                    color: .orange
                )

                SummaryCard(
                    title: "Завершено",
                    value: "\(completionRate)%",
                    icon: "checkmark.circle.fill",
                    color: .green
                )
            }

            HStack(spacing: 12) {
                SummaryCard(
                    title: "Общее время",
                    value: totalTimeFormatted,
                    icon: "clock.fill",
                    color: .blue
                )

                SummaryCard(
                    title: "Регулярность",
                    value: "\(regularityRate)%",
                    icon: "calendar",
                    color: .purple
                )
            }
        }
    }

    // MARK: - Helpers
    private var filteredSessions: [WorkoutSession] {
        let startDate = selectedPeriod.startDate
        return sessions.filter { $0.date >= startDate }
    }

    private var averageDuration: Int {
        guard !filteredSessions.isEmpty else { return 0 }
        let total = filteredSessions.reduce(0) { $0 + Int($1.duration) }
        return total / filteredSessions.count / 60
    }

    private var completionRate: Int {
        guard !filteredSessions.isEmpty else { return 0 }
        let completed = filteredSessions.filter { $0.isCompleted }.count
        return completed * 100 / filteredSessions.count
    }

    private var regularityRate: Int {
        let expectedWorkouts = selectedPeriod.expectedWorkouts
        guard expectedWorkouts > 0 else { return 0 }
        return min(100, filteredSessions.count * 100 / expectedWorkouts)
    }

    private var totalTimeFormatted: String {
        let totalMinutes = filteredSessions.reduce(0) { $0 + Int($1.duration) / 60 }
        if totalMinutes >= 60 {
            return "\(totalMinutes / 60)ч \(totalMinutes % 60)м"
        }
        return "\(totalMinutes)м"
    }

    private func colorForDay(_ day: String) -> Color {
        switch day {
        case "day1": return .orange
        case "day2": return .blue
        case "day3": return .green
        default: return .orange
        }
    }

    private func weightDataForExercise(_ name: String) -> [WeightDataPoint] {
        let filtered = exercises
            .filter { $0.exerciseName == name && $0.weight > 0 }
            .sorted { $0.date < $1.date }

        // Group by date and take max weight for each day
        var grouped: [Date: Double] = [:]
        for exercise in filtered {
            let dayStart = Calendar.current.startOfDay(for: exercise.date)
            if let existing = grouped[dayStart] {
                grouped[dayStart] = max(existing, exercise.weight)
            } else {
                grouped[dayStart] = exercise.weight
            }
        }

        return grouped.map { WeightDataPoint(date: $0.key, weight: $0.value) }
            .sorted { $0.date < $1.date }
    }
}

// MARK: - Time Period
enum TimePeriod: CaseIterable {
    case week, month, threeMonths

    var title: String {
        switch self {
        case .week: return "Неделя"
        case .month: return "Месяц"
        case .threeMonths: return "3 месяца"
        }
    }

    var startDate: Date {
        let calendar = Calendar.current
        switch self {
        case .week:
            return calendar.date(byAdding: .day, value: -7, to: Date())!
        case .month:
            return calendar.date(byAdding: .month, value: -1, to: Date())!
        case .threeMonths:
            return calendar.date(byAdding: .month, value: -3, to: Date())!
        }
    }

    var expectedWorkouts: Int {
        switch self {
        case .week: return 3
        case .month: return 12
        case .threeMonths: return 36
        }
    }
}

// MARK: - Weight Data Point
struct WeightDataPoint: Identifiable {
    let id = UUID()
    let date: Date
    let weight: Double
}

// MARK: - Activity Calendar
struct ActivityCalendarView: View {
    let sessions: [WorkoutSession]

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 7)
    private let weekdays = ["Пн", "Вт", "Ср", "Чт", "Пт", "Сб", "Вс"]

    var body: some View {
        VStack(spacing: 8) {
            // Weekday headers
            HStack(spacing: 4) {
                ForEach(weekdays, id: \.self) { day in
                    Text(day)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                }
            }

            // Calendar grid
            LazyVGrid(columns: columns, spacing: 4) {
                ForEach(calendarDays, id: \.self) { date in
                    if let date = date {
                        let hasWorkout = hasWorkout(on: date)
                        RoundedRectangle(cornerRadius: 4)
                            .fill(hasWorkout ? Color.orange : Color(.systemGray5))
                            .aspectRatio(1, contentMode: .fit)
                            .overlay {
                                if Calendar.current.isDateInToday(date) {
                                    RoundedRectangle(cornerRadius: 4)
                                        .stroke(Color.orange, lineWidth: 2)
                                }
                            }
                    } else {
                        Color.clear
                            .aspectRatio(1, contentMode: .fit)
                    }
                }
            }
        }
    }

    private var calendarDays: [Date?] {
        let calendar = Calendar.current
        let today = Date()

        // Get start of current week (Monday)
        var components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: today)
        components.weekday = 2 // Monday
        let startOfWeek = calendar.date(from: components)!

        // Go back 4 weeks
        let startDate = calendar.date(byAdding: .day, value: -28, to: startOfWeek)!

        var days: [Date?] = []

        // Add leading empty cells for first week alignment
        let firstWeekday = calendar.component(.weekday, from: startDate)
        let leadingEmpty = (firstWeekday + 5) % 7 // Convert to Monday = 0
        for _ in 0..<leadingEmpty {
            days.append(nil)
        }

        // Add 35 days (5 weeks)
        for i in 0..<35 {
            if let date = calendar.date(byAdding: .day, value: i, to: startDate) {
                days.append(date)
            }
        }

        return days
    }

    private func hasWorkout(on date: Date) -> Bool {
        let calendar = Calendar.current
        return sessions.contains { session in
            calendar.isDate(session.date, inSameDayAs: date)
        }
    }
}

// MARK: - Summary Card
struct SummaryCard: View {
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
                .font(.title3)
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
    ProgressReportView()
        .modelContainer(for: [WorkoutSession.self, CompletedExercise.self])
}
