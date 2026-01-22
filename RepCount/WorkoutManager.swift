//
//  WorkoutManager.swift
//  RepCount
//
//  Manages workout state, timers, and persistence
//

import Foundation
import SwiftUI
import Combine
import UIKit

@MainActor
class WorkoutManager: ObservableObject {

    // MARK: - Published State

    // Setup
    @Published var targetReps: Int = 10
    @Published var restSeconds: Int = 60

    // Workout state
    @Published var workoutStarted: Bool = false
    @Published var currentSetNumber: Int = 1
    @Published var completedSets: [WorkoutSet] = []

    // Rest timer
    @Published var isResting: Bool = false
    @Published var restTimeRemaining: Int = 0

    // Interval timer
    @Published var isIntervalTimerRunning: Bool = false
    @Published var intervalTimeRemaining: Int = 0
    @Published var currentRound: Int = 1
    @Published var isWorkPhase: Bool = true
    @Published var currentIntervalPreset: IntervalPreset?

    // History
    @Published var workoutHistory: [WorkoutSession] = []

    // MARK: - Private

    private var restTimer: Timer?
    private var intervalTimer: Timer?
    private var workoutStartTime: Date?
    private let haptics = UIImpactFeedbackGenerator(style: .medium)
    private let heavyHaptics = UIImpactFeedbackGenerator(style: .heavy)

    // MARK: - Persistence Keys

    private let historyKey = "workoutHistory"
    private let targetRepsKey = "targetReps"
    private let restSecondsKey = "restSeconds"

    // MARK: - Init

    init() {
        loadHistory()
        loadSettings()
    }

    // MARK: - Workout Session

    func startWorkout() {
        workoutStarted = true
        currentSetNumber = 1
        completedSets = []
        workoutStartTime = Date()
        saveSettings()
        heavyHaptics.impactOccurred()
    }

    func completeSet(reps: Int) {
        let set = WorkoutSet(reps: reps)
        completedSets.append(set)
        heavyHaptics.impactOccurred()

        // Start rest timer
        startRestTimer(seconds: restSeconds)
    }

    func endWorkout() {
        // Save to history if any sets completed
        if !completedSets.isEmpty, let startTime = workoutStartTime {
            let session = WorkoutSession(
                exercise: Exercise(name: "Workout", defaultReps: targetReps, defaultSets: completedSets.count, defaultRestSeconds: restSeconds),
                sets: completedSets,
                startedAt: startTime,
                completedAt: Date(),
                totalRestTime: 0
            )
            workoutHistory.insert(session, at: 0)
            saveHistory()
        }

        // Reset state
        workoutStarted = false
        currentSetNumber = 1
        completedSets = []
        workoutStartTime = nil
        stopRestTimer()
    }

    // MARK: - Rest Timer

    func startRestTimer(seconds: Int) {
        stopRestTimer()
        isResting = true
        restTimeRemaining = seconds

        restTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self = self else { return }
                if self.restTimeRemaining > 0 {
                    self.restTimeRemaining -= 1
                    if self.restTimeRemaining <= 3 && self.restTimeRemaining > 0 {
                        self.haptics.impactOccurred()
                    }
                } else {
                    self.heavyHaptics.impactOccurred()
                    self.restTimerEnded()
                }
            }
        }
    }

    private func restTimerEnded() {
        restTimer?.invalidate()
        restTimer = nil
        isResting = false
        restTimeRemaining = 0
        currentSetNumber += 1
    }

    func stopRestTimer() {
        restTimer?.invalidate()
        restTimer = nil
        isResting = false
        restTimeRemaining = 0
    }

    func skipRest() {
        stopRestTimer()
        currentSetNumber += 1
    }

    func addRestTime(_ seconds: Int) {
        restTimeRemaining += seconds
        // Also increase future rest duration
        restSeconds += seconds
        saveSettings()
        haptics.impactOccurred()
    }

    // MARK: - Interval Timer

    func startIntervalTimer(preset: IntervalPreset) {
        stopIntervalTimer()

        currentIntervalPreset = preset
        currentRound = 1
        isWorkPhase = true
        intervalTimeRemaining = preset.workSeconds
        isIntervalTimerRunning = true

        heavyHaptics.impactOccurred()

        intervalTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.tickIntervalTimer()
            }
        }
    }

    private func tickIntervalTimer() {
        guard let preset = currentIntervalPreset else { return }

        if intervalTimeRemaining > 0 {
            intervalTimeRemaining -= 1

            // Countdown haptics for last 3 seconds
            if intervalTimeRemaining <= 3 && intervalTimeRemaining > 0 {
                haptics.impactOccurred()
            }
        } else {
            // Phase complete
            heavyHaptics.impactOccurred()

            if isWorkPhase {
                // Switch to rest
                isWorkPhase = false
                intervalTimeRemaining = preset.restSeconds
            } else {
                // Rest complete, check if more rounds
                if currentRound < preset.rounds {
                    currentRound += 1
                    isWorkPhase = true
                    intervalTimeRemaining = preset.workSeconds
                } else {
                    // Workout complete
                    stopIntervalTimer()
                }
            }
        }
    }

    func stopIntervalTimer() {
        intervalTimer?.invalidate()
        intervalTimer = nil
        isIntervalTimerRunning = false
        currentIntervalPreset = nil
    }

    // MARK: - Persistence

    private func saveHistory() {
        if let encoded = try? JSONEncoder().encode(workoutHistory) {
            UserDefaults.standard.set(encoded, forKey: historyKey)
        }
    }

    private func loadHistory() {
        if let data = UserDefaults.standard.data(forKey: historyKey),
           let decoded = try? JSONDecoder().decode([WorkoutSession].self, from: data) {
            workoutHistory = decoded
        }
    }

    private func saveSettings() {
        UserDefaults.standard.set(targetReps, forKey: targetRepsKey)
        UserDefaults.standard.set(restSeconds, forKey: restSecondsKey)
    }

    private func loadSettings() {
        if UserDefaults.standard.object(forKey: targetRepsKey) != nil {
            targetReps = UserDefaults.standard.integer(forKey: targetRepsKey)
        }
        if UserDefaults.standard.object(forKey: restSecondsKey) != nil {
            restSeconds = UserDefaults.standard.integer(forKey: restSecondsKey)
        }
    }

    func clearHistory() {
        workoutHistory.removeAll()
        saveHistory()
    }

    // MARK: - Helpers

    func formatTime(_ seconds: Int) -> String {
        let mins = seconds / 60
        let secs = seconds % 60
        return String(format: "%d:%02d", mins, secs)
    }
}
