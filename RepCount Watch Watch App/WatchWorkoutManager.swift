//
//  WatchWorkoutManager.swift
//  RepCount Watch Watch App
//
//  Manages workout state and timers for Watch
//

import Foundation
import SwiftUI
import WatchKit
import Combine

@MainActor
class WatchWorkoutManager: ObservableObject {

    // MARK: - Published State

    // Setup
    @Published var targetReps: Int = 10
    @Published var restSeconds: Int = 60
    @Published var targetTotalReps: Int = 100

    // Workout state
    @Published var workoutStarted: Bool = false
    @Published var currentSetNumber: Int = 1
    @Published var completedSets: [Int] = []  // Just store rep counts

    // Rest timer
    @Published var isResting: Bool = false
    @Published var restTimeRemaining: Int = 0

    // MARK: - Computed

    var completedReps: Int {
        completedSets.reduce(0, +)
    }

    var progressPercent: Double {
        guard targetTotalReps > 0 else { return 0 }
        return min(1.0, Double(completedReps) / Double(targetTotalReps))
    }

    var isGoalComplete: Bool {
        completedReps >= targetTotalReps
    }

    // MARK: - Private

    private var restTimer: Timer?

    // Persistence keys
    private let targetRepsKey = "watch_targetReps"
    private let restSecondsKey = "watch_restSeconds"
    private let targetTotalRepsKey = "watch_targetTotalReps"

    // MARK: - Init

    init() {
        loadSettings()
    }

    // MARK: - Haptics

    private func playHaptic(_ type: WKHapticType) {
        WKInterfaceDevice.current().play(type)
    }

    // MARK: - Workout Session

    func startWorkout() {
        workoutStarted = true
        currentSetNumber = 1
        completedSets = []
        saveSettings()
        playHaptic(.start)
    }

    func completeSet(reps: Int) {
        completedSets.append(reps)
        playHaptic(.success)

        // Start rest timer
        startRestTimer(seconds: restSeconds)
    }

    func endWorkout() {
        workoutStarted = false
        currentSetNumber = 1
        completedSets = []
        stopRestTimer()
        playHaptic(.stop)
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
                        self.playHaptic(.click)
                    }
                } else {
                    self.playHaptic(.notification)
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
        playHaptic(.click)
    }

    func addRestTime(_ seconds: Int) {
        restTimeRemaining += seconds
        restSeconds += seconds
        saveSettings()
        playHaptic(.click)
    }

    // MARK: - Persistence

    private func saveSettings() {
        UserDefaults.standard.set(targetReps, forKey: targetRepsKey)
        UserDefaults.standard.set(restSeconds, forKey: restSecondsKey)
        UserDefaults.standard.set(targetTotalReps, forKey: targetTotalRepsKey)
    }

    private func loadSettings() {
        if UserDefaults.standard.object(forKey: targetRepsKey) != nil {
            targetReps = UserDefaults.standard.integer(forKey: targetRepsKey)
        }
        if UserDefaults.standard.object(forKey: restSecondsKey) != nil {
            restSeconds = UserDefaults.standard.integer(forKey: restSecondsKey)
        }
        if UserDefaults.standard.object(forKey: targetTotalRepsKey) != nil {
            targetTotalReps = UserDefaults.standard.integer(forKey: targetTotalRepsKey)
        }
    }

    // MARK: - Helpers

    func formatTime(_ seconds: Int) -> String {
        let mins = seconds / 60
        let secs = seconds % 60
        return String(format: "%d:%02d", mins, secs)
    }
}
