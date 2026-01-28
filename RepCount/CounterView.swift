//
//  CounterView.swift
//  RepCount
//
//  Main workout view router
//

import SwiftUI

struct CounterView: View {
    @EnvironmentObject var manager: WorkoutManager

    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                LinearGradient(
                    colors: [Color.blue.opacity(0.2), Color.purple.opacity(0.2)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                if manager.showingSummary {
                    WorkoutSummaryView()
                } else if manager.workoutStarted {
                    if manager.isResting {
                        RestTimerView()
                    } else {
                        ActiveWorkoutView()
                    }
                } else {
                    SetupView()
                }
            }
            .navigationTitle("RepCount")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

#Preview {
    CounterView()
        .environmentObject(WorkoutManager())
}
