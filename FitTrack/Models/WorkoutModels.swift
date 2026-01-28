//
//  WorkoutModels.swift
//  FitTrack
//

import Foundation
import SwiftData

// MARK: - Workout Day
enum WorkoutDay: String, CaseIterable, Codable {
    case day1 = "day1"
    case day2 = "day2"
    case day3 = "day3"

    var title: String {
        switch self {
        case .day1: return "Грудь • Плечи • Трицепс"
        case .day2: return "Спина • Бицепс"
        case .day3: return "Ноги • Пресс"
        }
    }

    var shortTitle: String {
        switch self {
        case .day1: return "Грудь"
        case .day2: return "Спина"
        case .day3: return "Ноги"
        }
    }

    var weekday: String {
        switch self {
        case .day1: return "Понедельник"
        case .day2: return "Среда"
        case .day3: return "Пятница"
        }
    }

    var icon: String {
        switch self {
        case .day1: return "figure.strengthtraining.traditional"
        case .day2: return "figure.mixed.cardio"
        case .day3: return "figure.run"
        }
    }

    var accentColor: String {
        switch self {
        case .day1: return "orange"
        case .day2: return "blue"
        case .day3: return "green"
        }
    }
}

// MARK: - Exercise Category
struct ExerciseCategory: Identifiable {
    let id = UUID()
    let name: String
    let exercises: [Exercise]
}

// MARK: - Exercise Template
struct Exercise: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let sets: Int
    let reps: Int
    let defaultWeight: Double?

    var setsRepsText: String {
        "\(sets)×\(reps)"
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(name)
    }

    static func == (lhs: Exercise, rhs: Exercise) -> Bool {
        lhs.name == rhs.name
    }
}

// MARK: - Effort Level (RPE indicator)
enum EffortLevel: Int, Codable, CaseIterable {
    case easy = 1      // Can increase weight
    case normal = 2    // Good working weight
    case hard = 3      // At the limit

    var title: String {
        switch self {
        case .easy: return "Легко"
        case .normal: return "Нормально"
        case .hard: return "Тяжело"
        }
    }

    var icon: String {
        switch self {
        case .easy: return "arrow.up.circle.fill"
        case .normal: return "checkmark.circle.fill"
        case .hard: return "flame.fill"
        }
    }

    var color: String {
        switch self {
        case .easy: return "green"
        case .normal: return "orange"
        case .hard: return "red"
        }
    }

    var hint: String {
        switch self {
        case .easy: return "Увеличь вес"
        case .normal: return "Рабочий вес"
        case .hard: return "На пределе"
        }
    }
}

// MARK: - Completed Exercise Record
@Model
class CompletedExercise {
    var exerciseName: String
    var sets: Int
    var reps: Int
    var weight: Double
    var completedSets: Int
    var date: Date
    var workoutDay: String
    var effortLevelRaw: Int?

    var effortLevel: EffortLevel? {
        get {
            guard let raw = effortLevelRaw else { return nil }
            return EffortLevel(rawValue: raw)
        }
        set {
            effortLevelRaw = newValue?.rawValue
        }
    }

    init(exerciseName: String, sets: Int, reps: Int, weight: Double = 0, completedSets: Int = 0, date: Date = .now, workoutDay: String, effortLevel: EffortLevel? = nil) {
        self.exerciseName = exerciseName
        self.sets = sets
        self.reps = reps
        self.weight = weight
        self.completedSets = completedSets
        self.date = date
        self.workoutDay = workoutDay
        self.effortLevelRaw = effortLevel?.rawValue
    }

    var isCompleted: Bool {
        completedSets >= sets
    }
}

// MARK: - Workout Session History
@Model
class WorkoutSession {
    var date: Date
    var workoutDay: String
    var duration: TimeInterval
    var isCompleted: Bool
    var totalExercises: Int
    var completedExercises: Int

    init(date: Date = .now, workoutDay: String, duration: TimeInterval = 0, isCompleted: Bool = false, totalExercises: Int = 0, completedExercises: Int = 0) {
        self.date = date
        self.workoutDay = workoutDay
        self.duration = duration
        self.isCompleted = isCompleted
        self.totalExercises = totalExercises
        self.completedExercises = completedExercises
    }

    var formattedDuration: String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}
