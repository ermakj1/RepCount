//
//  ActiveWorkoutView.swift
//  RepCount
//
//  Active workout rep counting view
//

import SwiftUI

struct ActiveWorkoutView: View {
    @EnvironmentObject var manager: WorkoutManager
    @State private var adjustedReps: Int = 0

    var body: some View {
        VStack(spacing: 24) {
            // Elapsed time
            HStack {
                Image(systemName: "clock")
                    .foregroundStyle(.secondary)
                Text(manager.formatTime(manager.elapsedSeconds))
                    .font(.headline.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
            .padding(.top, 10)

            // Progress display
            VStack(spacing: 8) {
                Text("\(manager.completedReps)/\(manager.targetTotalReps)")
                    .font(.system(size: 36, weight: .bold, design: .rounded))

                ProgressView(value: manager.progressPercent)
                    .progressViewStyle(LinearProgressViewStyle(tint: manager.isGoalComplete ? .green : .blue))
                    .scaleEffect(y: 2)
                    .padding(.horizontal, 40)

                if manager.isGoalComplete {
                    Text("Goal Complete!")
                        .font(.headline)
                        .foregroundStyle(.green)
                }
            }

            // Set counter
            Text("Set \(manager.currentSetNumber)")
                .font(.title2)
                .foregroundStyle(.secondary)

            // Pause/Resume button
            Button {
                if manager.isPaused {
                    manager.resumeWorkout()
                } else {
                    manager.pauseWorkout()
                }
            } label: {
                HStack {
                    Image(systemName: manager.isPaused ? "play.fill" : "pause.fill")
                    Text(manager.isPaused ? "Resume" : "Pause")
                }
                .font(.headline)
                .foregroundStyle(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 10)
                .background(manager.isPaused ? Color.green : Color.gray)
                .clipShape(Capsule())
            }

            Spacer()

            // Adjusted reps display
            VStack(spacing: 8) {
                Text("Reps Completed")
                    .font(.headline)
                    .foregroundStyle(.secondary)

                HStack(spacing: 24) {
                    Button {
                        if adjustedReps > 0 {
                            adjustedReps -= 1
                        }
                    } label: {
                        Image(systemName: "minus.circle.fill")
                            .font(.system(size: 50))
                            .foregroundStyle(.red.opacity(0.8))
                    }
                    .disabled(manager.isPaused)

                    Text("\(adjustedReps)")
                        .font(.system(size: 100, weight: .bold, design: .rounded))
                        .frame(width: 140)

                    Button {
                        adjustedReps += 1
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 50))
                            .foregroundStyle(.green.opacity(0.8))
                    }
                    .disabled(manager.isPaused)
                }
            }
            .opacity(manager.isPaused ? 0.5 : 1.0)

            Spacer()

            // Quick complete button (target reps)
            Button {
                manager.completeSet(reps: manager.targetReps)
                adjustedReps = manager.targetReps
            } label: {
                Text("Done: +\(manager.targetReps) reps")
                    .font(.title2.bold())
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(Color.blue)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .padding(.horizontal, 24)
            .disabled(manager.isPaused)
            .opacity(manager.isPaused ? 0.5 : 1.0)

            // Submit adjusted reps if different
            if adjustedReps != manager.targetReps && adjustedReps > 0 {
                Button {
                    manager.completeSet(reps: adjustedReps)
                } label: {
                    Text("Done: +\(adjustedReps) reps")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.orange)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .padding(.horizontal, 24)
                .disabled(manager.isPaused)
                .opacity(manager.isPaused ? 0.5 : 1.0)
            }

            // End workout button
            Button {
                manager.endWorkout()
            } label: {
                Text("End Workout")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.red.opacity(0.8))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 20)
        }
        .onAppear {
            adjustedReps = manager.targetReps
        }
    }
}

#Preview {
    ActiveWorkoutView()
        .environmentObject(WorkoutManager())
}
