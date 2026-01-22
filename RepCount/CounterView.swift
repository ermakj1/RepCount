//
//  CounterView.swift
//  RepCount
//
//  Streamlined rep counter: set target reps, log sets, rest timer
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

                if manager.workoutStarted {
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

// MARK: - Setup View

struct SetupView: View {
    @EnvironmentObject var manager: WorkoutManager

    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                Text("Set Up Your Workout")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .padding(.top, 20)

                // Target total reps
                VStack(spacing: 8) {
                    Text("Total Goal")
                        .font(.headline)
                        .foregroundStyle(.secondary)

                    HStack(spacing: 20) {
                        Button {
                            if manager.targetTotalReps > 10 {
                                manager.targetTotalReps -= 10
                            }
                        } label: {
                            Image(systemName: "minus.circle.fill")
                                .font(.system(size: 40))
                                .foregroundStyle(.red.opacity(0.8))
                        }

                        Text("\(manager.targetTotalReps)")
                            .font(.system(size: 50, weight: .bold, design: .rounded))
                            .frame(width: 110)

                        Button {
                            manager.targetTotalReps += 10
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 40))
                                .foregroundStyle(.green.opacity(0.8))
                        }
                    }

                    // Quick select buttons
                    HStack(spacing: 10) {
                        ForEach([50, 100, 150, 200], id: \.self) { num in
                            Button {
                                manager.targetTotalReps = num
                            } label: {
                                Text("\(num)")
                                    .font(.subheadline.bold())
                                    .foregroundStyle(manager.targetTotalReps == num ? .white : .primary)
                                    .frame(width: 50, height: 34)
                                    .background(manager.targetTotalReps == num ? Color.blue : Color.gray.opacity(0.2))
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                            }
                        }
                    }
                }

                // Reps per set picker
                VStack(spacing: 8) {
                    Text("Reps per Set")
                        .font(.headline)
                        .foregroundStyle(.secondary)

                    HStack(spacing: 20) {
                        Button {
                            if manager.targetReps > 1 {
                                manager.targetReps -= 1
                            }
                        } label: {
                            Image(systemName: "minus.circle.fill")
                                .font(.system(size: 40))
                                .foregroundStyle(.red.opacity(0.8))
                        }

                        Text("\(manager.targetReps)")
                            .font(.system(size: 50, weight: .bold, design: .rounded))
                            .frame(width: 80)

                        Button {
                            manager.targetReps += 1
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 40))
                                .foregroundStyle(.green.opacity(0.8))
                        }
                    }

                    // Quick select buttons
                    HStack(spacing: 10) {
                        ForEach([5, 10, 12, 15, 20], id: \.self) { num in
                            Button {
                                manager.targetReps = num
                            } label: {
                                Text("\(num)")
                                    .font(.subheadline.bold())
                                    .foregroundStyle(manager.targetReps == num ? .white : .primary)
                                    .frame(width: 40, height: 34)
                                    .background(manager.targetReps == num ? Color.blue : Color.gray.opacity(0.2))
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                            }
                        }
                    }
                }

                // Rest time picker
                VStack(spacing: 8) {
                    Text("Rest Between Sets")
                        .font(.headline)
                        .foregroundStyle(.secondary)

                    HStack(spacing: 20) {
                        Button {
                            if manager.restSeconds > 10 {
                                manager.restSeconds -= 10
                            }
                        } label: {
                            Image(systemName: "minus.circle.fill")
                                .font(.system(size: 40))
                                .foregroundStyle(.red.opacity(0.8))
                        }

                        Text(formatTime(manager.restSeconds))
                            .font(.system(size: 44, weight: .bold, design: .rounded))
                            .frame(width: 100)

                        Button {
                            manager.restSeconds += 10
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 40))
                                .foregroundStyle(.green.opacity(0.8))
                        }
                    }

                    // Quick select buttons
                    HStack(spacing: 10) {
                        ForEach([30, 45, 60, 90, 120], id: \.self) { sec in
                            Button {
                                manager.restSeconds = sec
                            } label: {
                                Text(formatTime(sec))
                                    .font(.caption.bold())
                                    .foregroundStyle(manager.restSeconds == sec ? .white : .primary)
                                    .frame(width: 44, height: 34)
                                    .background(manager.restSeconds == sec ? Color.blue : Color.gray.opacity(0.2))
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                            }
                        }
                    }
                }

                // Start button
                Button {
                    manager.startWorkout()
                } label: {
                    Text("Start Workout")
                        .font(.title3.bold())
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.green)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .padding(.horizontal, 24)
                .padding(.top, 10)
                .padding(.bottom, 30)
            }
        }
    }

    private func formatTime(_ seconds: Int) -> String {
        let mins = seconds / 60
        let secs = seconds % 60
        if mins > 0 {
            return String(format: "%d:%02d", mins, secs)
        } else {
            return "\(secs)s"
        }
    }
}

// MARK: - Active Workout View

struct ActiveWorkoutView: View {
    @EnvironmentObject var manager: WorkoutManager
    @State private var adjustedReps: Int = 0

    var body: some View {
        VStack(spacing: 24) {
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
            .padding(.top, 20)

            // Set counter
            Text("Set \(manager.currentSetNumber)")
                .font(.title2)
                .foregroundStyle(.secondary)

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
                }
            }

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
            }

            // End workout button
            Button {
                manager.endWorkout()
            } label: {
                Text("End Workout")
                    .font(.subheadline)
                    .foregroundStyle(.red)
            }
            .padding(.bottom, 20)
        }
        .onAppear {
            adjustedReps = manager.targetReps
        }
    }
}

// MARK: - Rest Timer View

struct RestTimerView: View {
    @EnvironmentObject var manager: WorkoutManager
    @State private var pulseScale: CGFloat = 1.0

    var body: some View {
        VStack(spacing: 24) {
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
            .padding(.top, 30)

            Text("REST")
                .font(.title)
                .fontWeight(.black)
                .foregroundStyle(.orange)

            // Timer display
            Text(manager.formatTime(manager.restTimeRemaining))
                .font(.system(size: 80, weight: .bold, design: .rounded))
                .foregroundStyle(.primary)
                .scaleEffect(pulseScale)
                .onChange(of: manager.restTimeRemaining) { oldValue, newValue in
                    if newValue <= 3 && newValue > 0 {
                        withAnimation(.easeOut(duration: 0.1)) {
                            pulseScale = 1.1
                        }
                        withAnimation(.easeIn(duration: 0.1).delay(0.1)) {
                            pulseScale = 1.0
                        }
                    }
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
            }

            // Skip button
            Button {
                manager.skipRest()
            } label: {
                Text("Skip Rest")
                    .font(.headline)
                    .foregroundStyle(.blue)
            }
            .padding(.bottom, 30)
        }
        .padding(.top, 60)
    }
}

#Preview {
    CounterView()
        .environmentObject(WorkoutManager())
}
