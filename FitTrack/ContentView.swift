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

            ProgressReportView()
                .tabItem {
                    Label("Прогресс", systemImage: "chart.line.uptrend.xyaxis")
                }
                .tag(1)

            HistoryView()
                .tabItem {
                    Label("История", systemImage: "calendar")
                }
                .tag(2)

            SettingsView()
                .tabItem {
                    Label("Настройки", systemImage: "gearshape.fill")
                }
                .tag(3)
        }
        .tint(.orange)
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [WorkoutSession.self, CompletedExercise.self])
}
