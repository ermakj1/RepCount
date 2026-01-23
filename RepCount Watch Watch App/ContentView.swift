//
//  ContentView.swift
//  RepCount Watch Watch App
//
//  Main Watch app interface
//

import SwiftUI

struct ContentView: View {
    @StateObject private var manager = WatchWorkoutManager()

    var body: some View {
        if manager.showingSummary {
            WatchSummaryView()
                .environmentObject(manager)
        } else if manager.workoutStarted {
            if manager.isResting {
                WatchRestView()
                    .environmentObject(manager)
            } else {
                WatchActiveView()
                    .environmentObject(manager)
            }
        } else {
            WatchSetupView()
                .environmentObject(manager)
        }
    }
}

// MARK: - Setup View

struct WatchSetupView: View {
    @EnvironmentObject var manager: WatchWorkoutManager

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                // Goal
                VStack(spacing: 4) {
                    Text("Goal")
                        .font(.caption2)
                        .foregroundStyle(.secondary)

                    HStack {
                        Button {
                            if manager.targetTotalReps > 1 {
                                manager.targetTotalReps -= 1
                            }
                        } label: {
                            Image(systemName: "minus")
                        }
                        .buttonStyle(.bordered)
                        .tint(.red)

                        Text("\(manager.targetTotalReps)")
                            .font(.title2.bold())
                            .frame(width: 60)

                        Button {
                            manager.targetTotalReps += 1
                        } label: {
                            Image(systemName: "plus")
                        }
                        .buttonStyle(.bordered)
                        .tint(.green)
                    }
                }

                // Reps per set
                VStack(spacing: 4) {
                    Text("Per Set")
                        .font(.caption2)
                        .foregroundStyle(.secondary)

                    HStack {
                        Button {
                            if manager.targetReps > 1 {
                                manager.targetReps -= 1
                            }
                        } label: {
                            Image(systemName: "minus")
                        }
                        .buttonStyle(.bordered)
                        .tint(.red)

                        Text("\(manager.targetReps)")
                            .font(.title2.bold())
                            .frame(width: 50)

                        Button {
                            manager.targetReps += 1
                        } label: {
                            Image(systemName: "plus")
                        }
                        .buttonStyle(.bordered)
                        .tint(.green)
                    }
                }

                // Rest time
                VStack(spacing: 4) {
                    Text("Rest")
                        .font(.caption2)
                        .foregroundStyle(.secondary)

                    HStack {
                        Button {
                            if manager.restSeconds > 1 {
                                manager.restSeconds -= 1
                            }
                        } label: {
                            Image(systemName: "minus")
                        }
                        .buttonStyle(.bordered)
                        .tint(.red)

                        Text(formatRest(manager.restSeconds))
                            .font(.title3.bold())
                            .frame(width: 50)

                        Button {
                            manager.restSeconds += 1
                        } label: {
                            Image(systemName: "plus")
                        }
                        .buttonStyle(.bordered)
                        .tint(.green)
                    }
                }

                // Start button
                Button {
                    manager.startWorkout()
                } label: {
                    Text("Start")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(.green)
                .padding(.top, 8)
            }
            .padding(.horizontal, 4)
        }
    }

    private func formatRest(_ seconds: Int) -> String {
        let mins = seconds / 60
        let secs = seconds % 60
        if mins > 0 && secs == 0 {
            return "\(mins)m"
        } else if mins > 0 {
            return "\(mins):\(String(format: "%02d", secs))"
        } else {
            return "\(secs)s"
        }
    }
}

// MARK: - Active Workout View

struct WatchActiveView: View {
    @EnvironmentObject var manager: WatchWorkoutManager
    @State private var adjustedReps: Int = 0

    var body: some View {
        ScrollView {
            VStack(spacing: 8) {
                // Elapsed time
                HStack(spacing: 4) {
                    Image(systemName: "clock")
                        .font(.caption2)
                    Text(manager.formatTime(manager.elapsedSeconds))
                        .font(.caption.monospacedDigit())
                }
                .foregroundStyle(.secondary)

                // Progress
                Text("\(manager.completedReps)/\(manager.targetTotalReps)")
                    .font(.caption)
                    .foregroundStyle(manager.isGoalComplete ? .green : .secondary)

                ProgressView(value: manager.progressPercent)
                    .tint(manager.isGoalComplete ? .green : .blue)

                Text("Set \(manager.currentSetNumber)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)

                // Rep adjuster
                HStack {
                    Button {
                        if adjustedReps > 0 {
                            adjustedReps -= 1
                        }
                    } label: {
                        Image(systemName: "minus")
                    }
                    .buttonStyle(.bordered)
                    .tint(.red)

                    Text("\(adjustedReps)")
                        .font(.system(size: 44, weight: .bold, design: .rounded))
                        .frame(width: 70)

                    Button {
                        adjustedReps += 1
                    } label: {
                        Image(systemName: "plus")
                    }
                    .buttonStyle(.bordered)
                    .tint(.green)
                }

                // Done button
                Button {
                    manager.completeSet(reps: adjustedReps)
                    adjustedReps = manager.targetReps
                } label: {
                    Text("Done +\(adjustedReps)")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(.blue)

                // End workout
                Button {
                    manager.endWorkout()
                } label: {
                    Text("End")
                        .font(.caption)
                }
                .buttonStyle(.bordered)
                .tint(.red)
            }
            .padding(.horizontal, 4)
        }
        .onAppear {
            adjustedReps = manager.targetReps
        }
    }
}

// MARK: - Rest Timer View

struct WatchRestView: View {
    @EnvironmentObject var manager: WatchWorkoutManager

    var body: some View {
        VStack(spacing: 8) {
            // Elapsed time
            HStack(spacing: 4) {
                Image(systemName: "clock")
                    .font(.caption2)
                Text(manager.formatTime(manager.elapsedSeconds))
                    .font(.caption.monospacedDigit())
            }
            .foregroundStyle(.secondary)

            // Progress
            Text("\(manager.completedReps)/\(manager.targetTotalReps)")
                .font(.caption2)
                .foregroundStyle(manager.isGoalComplete ? .green : .secondary)

            Text("REST")
                .font(.headline)
                .foregroundStyle(.orange)

            Text(manager.formatTime(manager.restTimeRemaining))
                .font(.system(size: 48, weight: .bold, design: .rounded))

            Text("Next: Set \(manager.currentSetNumber + 1)")
                .font(.caption2)
                .foregroundStyle(.secondary)

            HStack(spacing: 8) {
                if manager.restTimeRemaining <= 10 {
                    Button {
                        manager.addRestTime(10)
                    } label: {
                        Text("+10s")
                            .font(.caption2)
                    }
                    .buttonStyle(.bordered)
                    .tint(.orange)
                }

                Button {
                    manager.skipRest()
                } label: {
                    Text("Skip")
                        .font(.caption2)
                }
                .buttonStyle(.bordered)
                .tint(.blue)
            }

            Button {
                manager.endWorkout()
            } label: {
                Text("End")
                    .font(.caption2)
            }
            .buttonStyle(.bordered)
            .tint(.red)
        }
    }
}

// MARK: - Summary View

struct WatchSummaryView: View {
    @EnvironmentObject var manager: WatchWorkoutManager

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 40))
                    .foregroundStyle(.green)

                Text("Done!")
                    .font(.headline)

                // Stats
                VStack(spacing: 8) {
                    HStack {
                        Image(systemName: "flame.fill")
                            .foregroundStyle(.orange)
                        Text("\(manager.summaryTotalReps) reps")
                            .font(.headline)
                        Spacer()
                    }

                    HStack {
                        Image(systemName: "clock.fill")
                            .foregroundStyle(.blue)
                        Text(formatElapsedTime(manager.summaryElapsedTime))
                            .font(.headline)
                        Spacer()
                    }

                    HStack {
                        Image(systemName: "number.circle.fill")
                            .foregroundStyle(.purple)
                        Text("\(manager.summarySetsCompleted) sets")
                            .font(.headline)
                        Spacer()
                    }
                }
                .padding(.horizontal, 8)

                Button {
                    manager.dismissSummary()
                } label: {
                    Text("Done")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(.blue)
            }
            .padding(.horizontal, 4)
        }
    }

    private func formatElapsedTime(_ seconds: Int) -> String {
        let hours = seconds / 3600
        let mins = (seconds % 3600) / 60
        let secs = seconds % 60

        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, mins, secs)
        } else {
            return String(format: "%d:%02d", mins, secs)
        }
    }
}

#Preview {
    ContentView()
}
