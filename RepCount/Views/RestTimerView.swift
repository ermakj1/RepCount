//
//  RestTimerView.swift
//  RepCount
//
//  Rest timer countdown view
//

import SwiftUI

struct RestTimerView: View {
    @EnvironmentObject var manager: WorkoutManager
    @State private var pulseScale: CGFloat = 1.0

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
                    .font(.system(size: 28, weight: .bold, design: .rounded))

                ProgressView(value: manager.progressPercent)
                    .progressViewStyle(LinearProgressViewStyle(tint: manager.isGoalComplete ? .green : .blue))
                    .scaleEffect(y: 2)
                    .padding(.horizontal, 50)

                if manager.isGoalComplete {
                    Text("Goal Complete!")
                        .font(.subheadline)
                        .foregroundStyle(.green)
                }
            }

            Text(manager.isPaused ? "PAUSED" : "REST")
                .font(.title)
                .fontWeight(.black)
                .foregroundStyle(manager.isPaused ? .gray : .orange)

            // Timer display
            Text(manager.formatTime(manager.restTimeRemaining))
                .font(.system(size: 80, weight: .bold, design: .rounded))
                .foregroundStyle(.primary)
                .scaleEffect(pulseScale)
                .opacity(manager.isPaused ? 0.5 : 1.0)
                .onChange(of: manager.restTimeRemaining) { oldValue, newValue in
                    if newValue <= 3 && newValue > 0 && !manager.isPaused {
                        withAnimation(.easeOut(duration: 0.1)) {
                            pulseScale = 1.1
                        }
                        withAnimation(.easeIn(duration: 0.1).delay(0.1)) {
                            pulseScale = 1.0
                        }
                    }
                }

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

            // Next set info
            Text("Next: Set \(manager.currentSetNumber + 1)")
                .font(.headline)
                .foregroundStyle(.secondary)

            Spacer()

            // Add time button (visible when timer is low or done)
            if manager.restTimeRemaining <= 10 {
                Button {
                    manager.addRestTime(10)
                } label: {
                    Text("+10 seconds")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 32)
                        .padding(.vertical, 14)
                        .background(Color.orange)
                        .clipShape(Capsule())
                }
                .disabled(manager.isPaused)
                .opacity(manager.isPaused ? 0.5 : 1.0)
            }

            // Skip button
            Button {
                manager.skipRest()
            } label: {
                Text("Skip Rest")
                    .font(.headline)
                    .foregroundStyle(.blue)
            }
            .disabled(manager.isPaused)
            .opacity(manager.isPaused ? 0.5 : 1.0)

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
    }
}

#Preview {
    RestTimerView()
        .environmentObject(WorkoutManager())
}
