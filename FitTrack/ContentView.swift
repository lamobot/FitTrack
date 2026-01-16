//
//  ContentView.swift
//  FitTrack
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tabItem {
                    Label("Тренировки", systemImage: "dumbbell.fill")
                }
                .tag(0)

            HistoryView()
                .tabItem {
                    Label("История", systemImage: "chart.bar.fill")
                }
                .tag(1)

            SettingsView()
                .tabItem {
                    Label("Настройки", systemImage: "gearshape.fill")
                }
                .tag(2)
        }
        .tint(.orange)
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [WorkoutSession.self, CompletedExercise.self])
}
