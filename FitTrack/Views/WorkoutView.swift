//
//  WorkoutView.swift
//  FitTrack
//

import SwiftUI
import SwiftData

struct WorkoutView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let workoutDay: WorkoutDay

    @State private var completedSets: [String: Int] = [:]
    @State private var weights: [String: Double] = [:]
    @State private var startTime = Date()
    @State private var showRestTimer = false
    @State private var showFinishAlert = false
    @State private var elapsedTime: TimeInterval = 0
    @State private var timer: Timer?

    private var categories: [ExerciseCategory] {
        WorkoutData.categories(for: workoutDay)
    }

    private var totalExercises: Int {
        categories.reduce(0) { $0 + $1.exercises.count }
    }

    private var completedExercisesCount: Int {
        categories.reduce(0) { count, category in
            count + category.exercises.filter { exercise in
                (completedSets[exercise.name] ?? 0) >= exercise.sets
            }.count
        }
    }

    private var progress: Double {
        guard totalExercises > 0 else { return 0 }
        return Double(completedExercisesCount) / Double(totalExercises)
    }

    var body: some View {
        ZStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Progress bar
                    progressSection

                    // Exercise categories
                    ForEach(categories) { category in
                        categorySection(category)
                    }

                    // Finish button
                    finishButton
                        .padding(.bottom, 100)
                }
                .padding()
            }

            // Rest timer
            if showRestTimer {
                RestTimerOverlay(isShowing: $showRestTimer)
            }
        }
        .navigationTitle(workoutDay.shortTitle)
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showRestTimer = true
                } label: {
                    Image(systemName: "timer")
                        .font(.title3)
                }
            }
        }
        .onAppear {
            startTime = Date()
            loadLastWeights()
            startTimer()
        }
        .onDisappear {
            timer?.invalidate()
        }
        .alert("Завершить тренировку?", isPresented: $showFinishAlert) {
            Button("Отмена", role: .cancel) { }
            Button("Завершить") {
                saveWorkout()
                dismiss()
            }
        } message: {
            Text("Выполнено \(completedExercisesCount) из \(totalExercises) упражнений")
        }
    }

    // MARK: - Progress Section
    private var progressSection: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Прогресс")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    Text("\(completedExercisesCount)/\(totalExercises)")
                        .font(.title)
                        .fontWeight(.bold)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text("Время")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    Text(formatTime(elapsedTime))
                        .font(.title)
                        .fontWeight(.bold)
                        .monospacedDigit()
                }
            }

            ProgressView(value: progress)
                .tint(accentColor)
                .scaleEffect(y: 2)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Category Section
    private func categorySection(_ category: ExerciseCategory) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(category.name)
                .font(.headline)
                .foregroundStyle(.secondary)

            VStack(spacing: 8) {
                ForEach(category.exercises) { exercise in
                    ExerciseRow(
                        exercise: exercise,
                        completedSets: completedSets[exercise.name] ?? 0,
                        weight: weights[exercise.name] ?? exercise.defaultWeight ?? 0,
                        accentColor: accentColor,
                        onSetCompleted: {
                            withAnimation(.spring(response: 0.3)) {
                                let current = completedSets[exercise.name] ?? 0
                                if current < exercise.sets {
                                    completedSets[exercise.name] = current + 1
                                    // Show rest timer after set (except last one)
                                    if current + 1 < exercise.sets {
                                        showRestTimer = true
                                    }
                                }
                            }
                        },
                        onSetDecremented: {
                            withAnimation(.spring(response: 0.3)) {
                                let current = completedSets[exercise.name] ?? 0
                                if current > 0 {
                                    completedSets[exercise.name] = current - 1
                                }
                            }
                        },
                        onWeightChanged: { newWeight in
                            weights[exercise.name] = newWeight
                        }
                    )
                }
            }
        }
    }

    // MARK: - Finish Button
    private var finishButton: some View {
        Button {
            showFinishAlert = true
        } label: {
            HStack {
                Image(systemName: "checkmark.circle.fill")
                Text("Завершить тренировку")
            }
            .font(.headline)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(accentColor)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }

    // MARK: - Helpers
    private var accentColor: Color {
        switch workoutDay.accentColor {
        case "orange": return .orange
        case "blue": return .blue
        case "green": return .green
        default: return .orange
        }
    }

    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            elapsedTime = Date().timeIntervalSince(startTime)
        }
    }

    private func loadLastWeights() {
        // Load weights from last workout
        // (will be implemented via SwiftData Query)
    }

    private func saveWorkout() {
        let session = WorkoutSession(
            date: Date(),
            workoutDay: workoutDay.rawValue,
            duration: elapsedTime,
            isCompleted: completedExercisesCount == totalExercises,
            totalExercises: totalExercises,
            completedExercises: completedExercisesCount
        )
        modelContext.insert(session)

        // Save exercise weights
        for category in categories {
            for exercise in category.exercises {
                let completed = CompletedExercise(
                    exerciseName: exercise.name,
                    sets: exercise.sets,
                    reps: exercise.reps,
                    weight: weights[exercise.name] ?? exercise.defaultWeight ?? 0,
                    completedSets: completedSets[exercise.name] ?? 0,
                    date: Date(),
                    workoutDay: workoutDay.rawValue
                )
                modelContext.insert(completed)
            }
        }
    }
}

// MARK: - Exercise Row
struct ExerciseRow: View {
    let exercise: Exercise
    let completedSets: Int
    let weight: Double
    let accentColor: Color
    let onSetCompleted: () -> Void
    let onSetDecremented: () -> Void
    let onWeightChanged: (Double) -> Void

    @State private var showWeightPicker = false

    private var isCompleted: Bool {
        completedSets >= exercise.sets
    }

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                // Name and parameters
                VStack(alignment: .leading, spacing: 4) {
                    Text(exercise.name)
                        .font(.body)
                        .fontWeight(.medium)
                        .strikethrough(isCompleted)
                        .foregroundStyle(isCompleted ? .secondary : .primary)

                    HStack(spacing: 12) {
                        Label(exercise.setsRepsText, systemImage: "repeat")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        if weight > 0 {
                            Button {
                                showWeightPicker = true
                            } label: {
                                Label("\(Int(weight)) кг", systemImage: "scalemass")
                                    .font(.caption)
                                    .foregroundStyle(accentColor)
                            }
                        }
                    }
                }

                Spacer()

                // Sets counter
                HStack(spacing: 8) {
                    Button {
                        onSetDecremented()
                    } label: {
                        Image(systemName: "minus.circle.fill")
                            .font(.title2)
                            .foregroundStyle(.secondary)
                    }
                    .opacity(completedSets > 0 ? 1 : 0.3)
                    .disabled(completedSets == 0)

                    Text("\(completedSets)/\(exercise.sets)")
                        .font(.headline)
                        .monospacedDigit()
                        .frame(minWidth: 44)

                    Button {
                        onSetCompleted()
                    } label: {
                        Image(systemName: isCompleted ? "checkmark.circle.fill" : "plus.circle.fill")
                            .font(.title2)
                            .foregroundStyle(isCompleted ? .green : accentColor)
                    }
                    .disabled(isCompleted)
                }
            }

            // Set indicators
            HStack(spacing: 6) {
                ForEach(0..<exercise.sets, id: \.self) { index in
                    Circle()
                        .fill(index < completedSets ? accentColor : Color(.systemGray4))
                        .frame(width: 8, height: 8)
                }
                Spacer()
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .sheet(isPresented: $showWeightPicker) {
            WeightPickerSheet(weight: weight, onSave: onWeightChanged)
                .presentationDetents([.height(300)])
        }
    }
}

// MARK: - Weight Picker Sheet
struct WeightPickerSheet: View {
    let weight: Double
    let onSave: (Double) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var selectedWeight: Double

    init(weight: Double, onSave: @escaping (Double) -> Void) {
        self.weight = weight
        self.onSave = onSave
        _selectedWeight = State(initialValue: weight)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Text("\(Int(selectedWeight)) кг")
                    .font(.system(size: 48, weight: .bold))

                HStack(spacing: 16) {
                    WeightButton(text: "-5") { selectedWeight = max(0, selectedWeight - 5) }
                    WeightButton(text: "-2.5") { selectedWeight = max(0, selectedWeight - 2.5) }
                    WeightButton(text: "+2.5") { selectedWeight += 2.5 }
                    WeightButton(text: "+5") { selectedWeight += 5 }
                }

                Slider(value: $selectedWeight, in: 0...200, step: 2.5)
                    .padding(.horizontal)
            }
            .padding()
            .navigationTitle("Вес")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Отмена") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Сохранить") {
                        onSave(selectedWeight)
                        dismiss()
                    }
                }
            }
        }
    }
}

struct WeightButton: View {
    let text: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(text)
                .font(.headline)
                .frame(width: 60, height: 44)
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 10))
        }
    }
}

#Preview {
    NavigationStack {
        WorkoutView(workoutDay: .day1)
    }
    .modelContainer(for: [WorkoutSession.self, CompletedExercise.self])
}
