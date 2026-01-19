//
//  LaunchScreen.swift
//  FitTrack
//

import SwiftUI

struct LaunchScreenView: View {
    var body: some View {
        ZStack {
            Color.white
                .ignoresSafeArea()

            VStack(spacing: 20) {
                // Dumbbell icon
                Image(systemName: "dumbbell.fill")
                    .font(.system(size: 80))
                    .foregroundStyle(.orange)

                // App name
                Text("FitTrack")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundStyle(Color(uiColor: .darkGray))
            }
        }
    }
}

#Preview {
    LaunchScreenView()
}
