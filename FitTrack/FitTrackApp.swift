//
//  FitTrackApp.swift
//  FitTrack
//

import SwiftUI
import SwiftData

@main
struct FitTrackApp: App {
    @State private var showLaunchScreen = true

    var body: some Scene {
        WindowGroup {
            ZStack {
                ContentView()

                if showLaunchScreen {
                    LaunchScreenView()
                        .transition(.opacity)
                        .zIndex(1)
                }
            }
            .onAppear {
                // Show launch screen for 1.5 seconds
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    withAnimation(.easeOut(duration: 0.3)) {
                        showLaunchScreen = false
                    }
                }
            }
        }
        .modelContainer(for: [WorkoutSession.self, CompletedExercise.self])
    }
}
