//
//  FitTrackApp.swift
//  FitTrack
//

import SwiftUI
import SwiftData

@main
struct FitTrackApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [WorkoutSession.self, CompletedExercise.self])
    }
}
