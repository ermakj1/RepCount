//
//  SetupView.swift
//  RepCount
//
//  Workout setup configuration view
//

import SwiftUI

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
                            if manager.targetTotalReps > 1 {
                                manager.targetTotalReps -= 1
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
                            manager.targetTotalReps += 1
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
                            if manager.restSeconds > 1 {
                                manager.restSeconds -= 1
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
                            manager.restSeconds += 1
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

                // Sync to Watch button
                Button {
                    WatchConnectivityManager.shared.sendSettingsToWatch(
                        targetReps: manager.targetReps,
                        restSeconds: manager.restSeconds,
                        targetTotalReps: manager.targetTotalReps
                    )
                } label: {
                    Label("Sync to Watch", systemImage: "applewatch")
                        .font(.subheadline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.orange)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .padding(.horizontal, 24)

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
                .padding(.top, 6)
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

#Preview {
    SetupView()
        .environmentObject(WorkoutManager())
}
