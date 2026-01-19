//
//  WorkoutView.swift
//  FitTrack
//

import SwiftUI
import SwiftData

struct WorkoutView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase

    let workoutDay: WorkoutDay

    @State private var completedSets: [String: Int] = [:]
    @State private var weights: [String: Double] = [:]
    @State private var startTime: Date?
    @State private var isWorkoutStarted: Bool = false
    @State private var showRestTimer = false
    @State private var showFinishAlert = false
    @State private var elapsedTime: TimeInterval = 0
    @State private var timer: Timer?

    // Keys for saving state
    private var startTimeKey: String { "workout_start_time_\(workoutDay.rawValue)" }
    private var completedSetsKey: String { "workout_sets_\(workoutDay.rawValue)" }
    private var weightsKey: String { "workout_weights_\(workoutDay.rawValue)" }
    private var isStartedKey: String { "workout_started_\(workoutDay.rawValue)" }

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

                    // Finish button (only when workout started)
                    if isWorkoutStarted {
                        finishButton
                            .padding(.bottom, 100)
                    }
                }
                .padding()
            }

            // Start workout overlay
            if !isWorkoutStarted {
                startWorkoutOverlay
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
                if isWorkoutStarted {
                    Button {
                        showRestTimer = true
                    } label: {
                        Image(systemName: "timer")
                            .font(.title3)
                    }
                }
            }
        }
        .onAppear {
            loadSavedState()
            if isWorkoutStarted {
                resumeTimer()
            }
        }
        .onDisappear {
            timer?.invalidate()
            if isWorkoutStarted {
                saveState()
            }
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active && isWorkoutStarted {
                // Recalculate elapsed time when app becomes active
                if let start = startTime {
                    elapsedTime = Date().timeIntervalSince(start)
                }
            } else if newPhase == .background && isWorkoutStarted {
                saveState()
            }
        }
        .alert("Завершить тренировку?", isPresented: $showFinishAlert) {
            Button("Отмена", role: .cancel) { }
            Button("Завершить") {
                saveWorkout()
                clearSavedState()
                dismiss()
            }
        } message: {
            Text("Выполнено \(completedExercisesCount) из \(totalExercises) упражнений")
        }
    }

    // MARK: - Start Workout Overlay
    private var startWorkoutOverlay: some View {
        VStack {
            Spacer()

            Button {
                withAnimation(.spring(response: 0.3)) {
                    startWorkout()
                }
            } label: {
                HStack {
                    Image(systemName: "play.fill")
                    Text("Начать тренировку")
                }
                .font(.headline)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(accentColor)
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            .padding()
            .padding(.bottom, 20)
        }
        .background(
            LinearGradient(
                colors: [.clear, Color(.systemBackground).opacity(0.9), Color(.systemBackground)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
        )
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

                    if isWorkoutStarted {
                        Text(formatTime(elapsedTime))
                            .font(.title)
                            .fontWeight(.bold)
                            .monospacedDigit()
                    } else {
                        Text("0:00")
                            .font(.title)
                            .fontWeight(.bold)
                            .monospacedDigit()
                            .foregroundStyle(.secondary)
                    }
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
                        isEnabled: isWorkoutStarted,
                        onSetCompleted: {
                            withAnimation(.spring(response: 0.3)) {
                                let current = completedSets[exercise.name] ?? 0
                                if current < exercise.sets {
                                    completedSets[exercise.name] = current + 1
                                    saveState()
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
                                    saveState()
                                }
                            }
                        },
                        onWeightChanged: { newWeight in
                            weights[exercise.name] = newWeight
                            saveState()
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

    private func startWorkout() {
        isWorkoutStarted = true
        startTime = Date()
        elapsedTime = 0
        UserDefaults.standard.set(startTime, forKey: startTimeKey)
        UserDefaults.standard.set(true, forKey: isStartedKey)

        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            if let start = startTime {
                elapsedTime = Date().timeIntervalSince(start)
            }
        }
    }

    private func resumeTimer() {
        if let start = startTime {
            elapsedTime = Date().timeIntervalSince(start)
            timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
                elapsedTime = Date().timeIntervalSince(start)
            }
        }
    }

    private func loadSavedState() {
        // Load workout started state
        isWorkoutStarted = UserDefaults.standard.bool(forKey: isStartedKey)

        // Load start time
        if let savedTime = UserDefaults.standard.object(forKey: startTimeKey) as? Date {
            startTime = savedTime
        }

        // Load completed sets
        if let data = UserDefaults.standard.data(forKey: completedSetsKey),
           let decoded = try? JSONDecoder().decode([String: Int].self, from: data) {
            completedSets = decoded
        }

        // Load weights
        if let data = UserDefaults.standard.data(forKey: weightsKey),
           let decoded = try? JSONDecoder().decode([String: Double].self, from: data) {
            weights = decoded
        }
    }

    private func saveState() {
        // Save completed sets
        if let encoded = try? JSONEncoder().encode(completedSets) {
            UserDefaults.standard.set(encoded, forKey: completedSetsKey)
        }
        // Save weights
        if let encoded = try? JSONEncoder().encode(weights) {
            UserDefaults.standard.set(encoded, forKey: weightsKey)
        }
    }

    private func clearSavedState() {
        UserDefaults.standard.removeObject(forKey: startTimeKey)
        UserDefaults.standard.removeObject(forKey: completedSetsKey)
        UserDefaults.standard.removeObject(forKey: weightsKey)
        UserDefaults.standard.removeObject(forKey: isStartedKey)
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
    var isEnabled: Bool = true
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
                    .opacity(completedSets > 0 && isEnabled ? 1 : 0.3)
                    .disabled(completedSets == 0 || !isEnabled)

                    Text("\(completedSets)/\(exercise.sets)")
                        .font(.headline)
                        .monospacedDigit()
                        .frame(minWidth: 44)

                    Button {
                        onSetCompleted()
                    } label: {
                        Image(systemName: isCompleted ? "checkmark.circle.fill" : "plus.circle.fill")
                            .font(.title2)
                            .foregroundStyle(isCompleted ? .green : (isEnabled ? accentColor : .secondary))
                    }
                    .disabled(isCompleted || !isEnabled)
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
        .opacity(isEnabled ? 1 : 0.7)
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
