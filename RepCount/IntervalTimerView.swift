//
//  IntervalTimerView.swift
//  RepCount
//
//  Interval timer for HIIT, Tabata, and custom intervals
//

import SwiftUI

struct IntervalTimerView: View {
    @EnvironmentObject var manager: WorkoutManager
    @State private var showPresetPicker = false
    @State private var customWorkSeconds = 30
    @State private var customRestSeconds = 30
    @State private var customRounds = 10

    var body: some View {
        NavigationStack {
            ZStack {
                // Dynamic background based on phase
                backgroundGradient
                    .ignoresSafeArea()
                    .animation(.easeInOut(duration: 0.3), value: manager.isWorkPhase)

                if manager.isIntervalTimerRunning {
                    activeTimerView
                } else {
                    setupView
                }
            }
            .navigationTitle("Interval Timer")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    // MARK: - Background

    private var backgroundGradient: some View {
        Group {
            if manager.isIntervalTimerRunning {
                if manager.isWorkPhase {
                    LinearGradient(
                        colors: [Color.green.opacity(0.4), Color.green.opacity(0.2)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                } else {
                    LinearGradient(
                        colors: [Color.blue.opacity(0.4), Color.blue.opacity(0.2)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                }
            } else {
                LinearGradient(
                    colors: [Color.gray.opacity(0.2), Color.gray.opacity(0.1)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            }
        }
    }

    // MARK: - Setup View

    private var setupView: some View {
        VStack(spacing: 30) {
            // Presets
            VStack(alignment: .leading, spacing: 12) {
                Text("Quick Start")
                    .font(.headline)
                    .padding(.horizontal)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(IntervalPreset.presets) { preset in
                            PresetCard(preset: preset) {
                                manager.startIntervalTimer(preset: preset)
                            }
                        }
                    }
                    .padding(.horizontal)
                }
            }

            Divider()
                .padding(.horizontal)

            // Custom timer
            VStack(spacing: 20) {
                Text("Custom Timer")
                    .font(.headline)

                HStack(spacing: 30) {
                    VStack {
                        Text("Work")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Picker("Work", selection: $customWorkSeconds) {
                            ForEach([10, 15, 20, 30, 45, 60, 90, 120, 180], id: \.self) { sec in
                                Text("\(sec)s").tag(sec)
                            }
                        }
                        .pickerStyle(.wheel)
                        .frame(width: 80, height: 100)
                        .clipped()
                    }

                    VStack {
                        Text("Rest")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Picker("Rest", selection: $customRestSeconds) {
                            ForEach([5, 10, 15, 20, 30, 45, 60, 90], id: \.self) { sec in
                                Text("\(sec)s").tag(sec)
                            }
                        }
                        .pickerStyle(.wheel)
                        .frame(width: 80, height: 100)
                        .clipped()
                    }

                    VStack {
                        Text("Rounds")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Picker("Rounds", selection: $customRounds) {
                            ForEach(1...20, id: \.self) { round in
                                Text("\(round)").tag(round)
                            }
                        }
                        .pickerStyle(.wheel)
                        .frame(width: 80, height: 100)
                        .clipped()
                    }
                }

                Button {
                    let custom = IntervalPreset(
                        name: "Custom",
                        workSeconds: customWorkSeconds,
                        restSeconds: customRestSeconds,
                        rounds: customRounds
                    )
                    manager.startIntervalTimer(preset: custom)
                } label: {
                    Text("Start Custom Timer")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .padding(.horizontal)
            }

            Spacer()
        }
        .padding(.top)
    }

    // MARK: - Active Timer View

    private var activeTimerView: some View {
        VStack(spacing: 20) {
            // Phase indicator
            Text(manager.isWorkPhase ? "WORK" : "REST")
                .font(.largeTitle)
                .fontWeight(.black)
                .foregroundStyle(manager.isWorkPhase ? .green : .blue)

            // Time remaining
            Text(manager.formatTime(manager.intervalTimeRemaining))
                .font(.system(size: 100, weight: .bold, design: .rounded))
                .foregroundStyle(.primary)

            // Round indicator
            if let preset = manager.currentIntervalPreset {
                Text("Round \(manager.currentRound) of \(preset.rounds)")
                    .font(.title2)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            // Stop button
            Button {
                manager.stopIntervalTimer()
            } label: {
                Text("Stop")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(width: 120, height: 50)
                    .background(Color.red)
                    .clipShape(Capsule())
            }
            .padding(.bottom, 40)
        }
        .padding(.top, 60)
    }
}

// MARK: - Preset Card

struct PresetCard: View {
    let preset: IntervalPreset
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Text(preset.name)
                    .font(.headline)
                    .foregroundStyle(.primary)

                Text("\(preset.workSeconds)s / \(preset.restSeconds)s")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text("\(preset.rounds) rounds")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .frame(width: 120, height: 90)
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(color: .black.opacity(0.1), radius: 4, y: 2)
        }
    }
}

#Preview {
    IntervalTimerView()
        .environmentObject(WorkoutManager())
}
