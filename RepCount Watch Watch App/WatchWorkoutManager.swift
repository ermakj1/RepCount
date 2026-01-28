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
    @Published var elapsedSeconds: Int = 0

    // Workout summary (shown after ending)
    @Published var showingSummary: Bool = false
    @Published var summaryTotalReps: Int = 0
    @Published var summaryElapsedTime: Int = 0
    @Published var summarySetsCompleted: Int = 0

    // Rest timer
    @Published var isResting: Bool = false
    @Published var restTimeRemaining: Int = 0

    // Pause state
    @Published var isPaused: Bool = false
    private var pausedRestTimeRemaining: Int = 0

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
    private var elapsedTimer: Timer?
    private var workoutStartTime: Date?

    // Timer precision: track elapsed time using Date snapshots
    private var elapsedTimerStartDate: Date?
    private var accumulatedElapsedTime: TimeInterval = 0

    // Timer precision: track rest timer using Date snapshots
    private var restTimerStartDate: Date?
    private var restTimerTargetSeconds: Int = 0

    // Persistence keys
    private let targetRepsKey = "watch_targetReps"
    private let restSecondsKey = "watch_restSeconds"
    private let targetTotalRepsKey = "watch_targetTotalReps"

    // MARK: - Init

    init() {
        loadSettings()
        setupPhoneConnectivity()
    }

    private func setupPhoneConnectivity() {
        PhoneConnectivityManager.shared.onSettingsReceived = { [weak self] targetReps, restSeconds, targetTotalReps in
            self?.targetReps = targetReps
            self?.restSeconds = restSeconds
            self?.targetTotalReps = targetTotalReps
            self?.saveSettings()
        }
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
        elapsedSeconds = 0
        accumulatedElapsedTime = 0
        workoutStartTime = Date()
        saveSettings()
        playHaptic(.start)
        startElapsedTimer()
    }

    private func startElapsedTimer() {
        elapsedTimer?.invalidate()
        elapsedTimerStartDate = Date()

        elapsedTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self = self, let startDate = self.elapsedTimerStartDate else { return }
                let currentElapsed = Date().timeIntervalSince(startDate) + self.accumulatedElapsedTime
                self.elapsedSeconds = Int(currentElapsed)
            }
        }
    }

    private func stopElapsedTimer() {
        // Accumulate elapsed time before stopping
        if let startDate = elapsedTimerStartDate {
            accumulatedElapsedTime += Date().timeIntervalSince(startDate)
        }
        elapsedTimerStartDate = nil
        elapsedTimer?.invalidate()
        elapsedTimer = nil
    }

    func completeSet(reps: Int) {
        completedSets.append(reps)
        playHaptic(.success)

        // Start rest timer
        startRestTimer(seconds: restSeconds)
    }

    func endWorkout() {
        // Store summary data before resetting
        summaryTotalReps = completedReps
        summaryElapsedTime = elapsedSeconds
        summarySetsCompleted = completedSets.count

        // Send workout to iPhone if any sets completed
        if !completedSets.isEmpty, let startTime = workoutStartTime {
            PhoneConnectivityManager.shared.sendWorkoutToPhone(
                sets: completedSets,
                targetReps: targetReps,
                restSeconds: restSeconds,
                startTime: startTime,
                endTime: Date()
            )
        }

        // Stop timers
        stopRestTimer()
        stopElapsedTimer()

        // Reset workout state
        workoutStarted = false
        currentSetNumber = 1
        completedSets = []
        elapsedSeconds = 0
        workoutStartTime = nil
        playHaptic(.stop)

        // Show summary if any work was done
        if summaryTotalReps > 0 {
            showingSummary = true
        }
    }

    func dismissSummary() {
        showingSummary = false
        summaryTotalReps = 0
        summaryElapsedTime = 0
        summarySetsCompleted = 0
    }

    // MARK: - Rest Timer

    func startRestTimer(seconds: Int) {
        stopRestTimer()
        isResting = true
        restTimeRemaining = seconds
        restTimerStartDate = Date()
        restTimerTargetSeconds = seconds

        restTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self = self, let startDate = self.restTimerStartDate else { return }
                let elapsed = Date().timeIntervalSince(startDate)
                let remaining = self.restTimerTargetSeconds - Int(elapsed)
                let previousRemaining = self.restTimeRemaining

                if remaining > 0 {
                    self.restTimeRemaining = remaining
                    // Haptic feedback for last 3 seconds (only trigger once per second)
                    if remaining <= 3 && remaining != previousRemaining {
                        self.playHaptic(.click)
                    }
                } else {
                    self.restTimeRemaining = 0
                    self.playHaptic(.notification)
                    self.restTimerEnded()
                }
            }
        }
    }

    private func restTimerEnded() {
        restTimer?.invalidate()
        restTimer = nil
        restTimerStartDate = nil
        restTimerTargetSeconds = 0
        isResting = false
        restTimeRemaining = 0
        currentSetNumber += 1
    }

    func stopRestTimer() {
        restTimer?.invalidate()
        restTimer = nil
        restTimerStartDate = nil
        restTimerTargetSeconds = 0
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
        restTimerTargetSeconds += seconds
        restSeconds += seconds
        saveSettings()
        playHaptic(.click)
    }

    // MARK: - Pause/Resume

    func pauseWorkout() {
        guard !isPaused else { return }
        isPaused = true
        playHaptic(.click)

        // Stop elapsed timer (accumulates time automatically)
        stopElapsedTimer()

        // If resting, save remaining time and stop rest timer
        if isResting {
            pausedRestTimeRemaining = restTimeRemaining
            restTimer?.invalidate()
            restTimer = nil
        }
    }

    func resumeWorkout() {
        guard isPaused else { return }
        isPaused = false
        playHaptic(.click)

        // Resume elapsed timer
        startElapsedTimer()

        // If was resting, resume rest timer from saved time
        if isResting && pausedRestTimeRemaining > 0 {
            restTimerStartDate = Date()
            restTimerTargetSeconds = pausedRestTimeRemaining
            restTimeRemaining = pausedRestTimeRemaining
            pausedRestTimeRemaining = 0

            restTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
                Task { @MainActor in
                    guard let self = self, let startDate = self.restTimerStartDate else { return }
                    let elapsed = Date().timeIntervalSince(startDate)
                    let remaining = self.restTimerTargetSeconds - Int(elapsed)
                    let previousRemaining = self.restTimeRemaining

                    if remaining > 0 {
                        self.restTimeRemaining = remaining
                        if remaining <= 3 && remaining != previousRemaining {
                            self.playHaptic(.click)
                        }
                    } else {
                        self.restTimeRemaining = 0
                        self.playHaptic(.notification)
                        self.restTimerEnded()
                    }
                }
            }
        }
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
