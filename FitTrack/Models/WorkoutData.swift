//
//  WorkoutData.swift
//  FitTrack
//

import Foundation

// MARK: - Workout Data
struct WorkoutData {

    // MARK: - Day 1: Chest, Shoulders, Triceps
    static let day1Categories: [ExerciseCategory] = [
        ExerciseCategory(name: "Разминка", exercises: [
            Exercise(name: "Велотренажёр или эллипс", sets: 1, reps: 5, defaultWeight: nil)
        ]),
        ExerciseCategory(name: "Активация кора", exercises: [
            Exercise(name: "Мёртвый жук", sets: 3, reps: 10, defaultWeight: nil),
            Exercise(name: "Планка", sets: 3, reps: 30, defaultWeight: nil)
        ]),
        ExerciseCategory(name: "Грудь", exercises: [
            Exercise(name: "Сведение рук в «бабочке»", sets: 3, reps: 15, defaultWeight: 25),
            Exercise(name: "Жим в тренажёре", sets: 4, reps: 12, defaultWeight: 10)
        ]),
        ExerciseCategory(name: "Плечи", exercises: [
            Exercise(name: "Жим сидя в тренажёре", sets: 3, reps: 12, defaultWeight: 20),
            Exercise(name: "Разведения гантелей в стороны", sets: 3, reps: 15, defaultWeight: nil)
        ]),
        ExerciseCategory(name: "Трицепс", exercises: [
            Exercise(name: "Разгибания на блоке (канат)", sets: 3, reps: 15, defaultWeight: 30),
            Exercise(name: "Отжимания на брусьях в гравитроне", sets: 3, reps: 10, defaultWeight: nil)
        ]),
        ExerciseCategory(name: "Кардио", exercises: [
            Exercise(name: "Ходьба", sets: 1, reps: 20, defaultWeight: nil)
        ])
    ]

    // MARK: - Day 2: Back, Biceps
    static let day2Categories: [ExerciseCategory] = [
        ExerciseCategory(name: "Разминка", exercises: [
            Exercise(name: "Кардио", sets: 1, reps: 5, defaultWeight: nil)
        ]),
        ExerciseCategory(name: "Активация кора", exercises: [
            Exercise(name: "Мёртвый жук", sets: 3, reps: 10, defaultWeight: nil),
            Exercise(name: "Боковая планка", sets: 3, reps: 20, defaultWeight: nil)
        ]),
        ExerciseCategory(name: "Спина", exercises: [
            Exercise(name: "Вертикальная тяга широким хватом", sets: 4, reps: 12, defaultWeight: nil),
            Exercise(name: "Горизонтальная тяга (блок к поясу)", sets: 4, reps: 12, defaultWeight: nil),
            Exercise(name: "Рычажная тяга (хаммер)", sets: 3, reps: 12, defaultWeight: nil)
        ]),
        ExerciseCategory(name: "Бицепс", exercises: [
            Exercise(name: "Сгибания на бицепс", sets: 3, reps: 12, defaultWeight: nil),
            Exercise(name: "Сгибания «молот»", sets: 3, reps: 12, defaultWeight: nil)
        ]),
        ExerciseCategory(name: "Задняя дельта", exercises: [
            Exercise(name: "Разведения в тренажёре (обратная бабочка)", sets: 3, reps: 15, defaultWeight: nil)
        ]),
        ExerciseCategory(name: "Кардио", exercises: [
            Exercise(name: "Ходьба", sets: 1, reps: 20, defaultWeight: nil)
        ])
    ]

    // MARK: - Day 3: Legs, Abs
    static let day3Categories: [ExerciseCategory] = [
        ExerciseCategory(name: "Разминка", exercises: [
            Exercise(name: "Кардио", sets: 1, reps: 5, defaultWeight: nil)
        ]),
        ExerciseCategory(name: "Активация", exercises: [
            Exercise(name: "Ягодичный мостик", sets: 3, reps: 15, defaultWeight: nil),
            Exercise(name: "Мёртвый жук", sets: 3, reps: 10, defaultWeight: nil)
        ]),
        ExerciseCategory(name: "Ноги", exercises: [
            Exercise(name: "Жим ногами (платформа)", sets: 4, reps: 12, defaultWeight: 20),
            Exercise(name: "Разгибания ног", sets: 3, reps: 15, defaultWeight: 25),
            Exercise(name: "Сгибания ног лёжа", sets: 3, reps: 15, defaultWeight: nil),
            Exercise(name: "Сведение ног", sets: 3, reps: 15, defaultWeight: 30),
            Exercise(name: "Разведение ног", sets: 3, reps: 15, defaultWeight: 35),
            Exercise(name: "Подъём на носки", sets: 3, reps: 20, defaultWeight: 10)
        ]),
        ExerciseCategory(name: "Пресс", exercises: [
            Exercise(name: "Скручивания в тренажёре", sets: 3, reps: 15, defaultWeight: 30),
            Exercise(name: "Подъём ног в упоре", sets: 3, reps: 10, defaultWeight: nil)
        ]),
        ExerciseCategory(name: "Кардио", exercises: [
            Exercise(name: "Ходьба", sets: 1, reps: 20, defaultWeight: nil)
        ])
    ]

    // MARK: - Get Categories by Day
    static func categories(for day: WorkoutDay) -> [ExerciseCategory] {
        switch day {
        case .day1: return day1Categories
        case .day2: return day2Categories
        case .day3: return day3Categories
        }
    }

    // MARK: - Total Exercises Count
    static func totalExercises(for day: WorkoutDay) -> Int {
        categories(for: day).reduce(0) { $0 + $1.exercises.count }
    }
}
