//
//  CounterView.swift
//  RepCount
//
//  Main rep counting interface with tap-to-count
//

import SwiftUI

struct CounterView: View {
    @EnvironmentObject var manager: WorkoutManager
    @State private var showExercisePicker = false
    @State private var pulseScale: CGFloat = 1.0

    var body: some View {
        NavigationStack {
            ZStack {
                // Background gradient
                LinearGradient(
                    colors: [Color.blue.opacity(0.3), Color.purple.opacity(0.3)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                VStack(spacing: 20) {
                    // Exercise info
                    if let session = manager.currentSession {
                        VStack(spacing: 8) {
                            Text(session.exercise.name)
                                .font(.title2)
                                .fontWeight(.semibold)

                            Text("Set \(manager.currentSetNumber) of \(session.exercise.defaultSets)")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.top, 20)
                    } else {
                        Text("Tap to Count")
                            .font(.title2)
                            .foregroundStyle(.secondary)
                            .padding(.top, 20)
                    }

                    Spacer()

                    // Rest timer overlay
                    if manager.isResting {
                        RestTimerOverlay()
                    } else {
                        // Main counter tap area
                        counterTapArea
                    }

                    Spacer()

                    // Bottom controls
                    bottomControls
                }
            }
            .navigationTitle("Counter")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showExercisePicker = true
                    } label: {
                        Image(systemName: "dumbbell.fill")
                    }
                }
            }
            .sheet(isPresented: $showExercisePicker) {
                ExercisePickerView()
            }
        }
    }

    // MARK: - Counter Tap Area

    private var counterTapArea: some View {
        VStack(spacing: 16) {
            // Rep count display
            Text("\(manager.currentReps)")
                .font(.system(size: 120, weight: .bold, design: .rounded))
                .foregroundStyle(.primary)
                .scaleEffect(pulseScale)

            Text("reps")
                .font(.title3)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .contentShape(Rectangle())
        .onTapGesture {
            manager.incrementRep()
            withAnimation(.easeOut(duration: 0.1)) {
                pulseScale = 1.1
            }
            withAnimation(.easeIn(duration: 0.1).delay(0.1)) {
                pulseScale = 1.0
            }
        }
    }

    // MARK: - Bottom Controls

    private var bottomControls: some View {
        VStack(spacing: 16) {
            // Adjustment buttons
            HStack(spacing: 40) {
                Button {
                    manager.decrementRep()
                } label: {
                    Image(systemName: "minus.circle.fill")
                        .font(.system(size: 50))
                        .foregroundStyle(.red.opacity(0.8))
                }

                Button {
                    manager.resetReps()
                } label: {
                    Image(systemName: "arrow.counterclockwise.circle.fill")
                        .font(.system(size: 50))
                        .foregroundStyle(.orange.opacity(0.8))
                }

                Button {
                    manager.incrementRep()
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 50))
                        .foregroundStyle(.green.opacity(0.8))
                }
            }

            // Complete set / Start workout button
            if manager.currentSession != nil {
                Button {
                    manager.completeSet()
                } label: {
                    Text("Complete Set")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .padding(.horizontal)
            }
        }
        .padding(.bottom, 20)
    }
}

// MARK: - Rest Timer Overlay

struct RestTimerOverlay: View {
    @EnvironmentObject var manager: WorkoutManager

    var body: some View {
        VStack(spacing: 20) {
            Text("REST")
                .font(.title)
                .fontWeight(.bold)
                .foregroundStyle(.orange)

            Text(manager.formatTime(manager.restTimeRemaining))
                .font(.system(size: 80, weight: .bold, design: .rounded))
                .foregroundStyle(.primary)

            Button {
                manager.skipRest()
            } label: {
                Text("Skip Rest")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 12)
                    .background(Color.orange)
                    .clipShape(Capsule())
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black.opacity(0.3))
    }
}

// MARK: - Exercise Picker

struct ExercisePickerView: View {
    @EnvironmentObject var manager: WorkoutManager
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section("Quick Start") {
                    Button {
                        manager.cancelWorkout()
                        dismiss()
                    } label: {
                        Label("Free Count (No Exercise)", systemImage: "hand.tap.fill")
                    }
                }

                Section("Exercises") {
                    ForEach(Exercise.presets) { exercise in
                        Button {
                            manager.startWorkout(exercise: exercise)
                            dismiss()
                        } label: {
                            HStack {
                                Text(exercise.name)
                                Spacer()
                                Text("\(exercise.defaultSets) x \(exercise.defaultReps)")
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Select Exercise")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    CounterView()
        .environmentObject(WorkoutManager())
}
