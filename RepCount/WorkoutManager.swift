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
    @Published var targetTotalReps: Int = 100

    // Workout state
    @Published var workoutStarted: Bool = false
    @Published var currentSetNumber: Int = 1
    @Published var completedSets: [WorkoutSet] = []
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
    private var elapsedTimer: Timer?
    private var workoutStartTime: Date?
    private let haptics = UIImpactFeedbackGenerator(style: .medium)
    private let heavyHaptics = UIImpactFeedbackGenerator(style: .heavy)

    // Timer precision: track elapsed time using Date snapshots
    private var elapsedTimerStartDate: Date?
    private var accumulatedElapsedTime: TimeInterval = 0

    // Timer precision: track rest timer using Date snapshots
    private var restTimerStartDate: Date?
    private var restTimerTargetSeconds: Int = 0

    // MARK: - Computed

    var completedReps: Int {
        completedSets.reduce(0) { $0 + $1.reps }
    }

    var progressPercent: Double {
        guard targetTotalReps > 0 else { return 0 }
        return min(1.0, Double(completedReps) / Double(targetTotalReps))
    }

    var isGoalComplete: Bool {
        completedReps >= targetTotalReps
    }

    // MARK: - Persistence Keys

    private let historyKey = "workoutHistory"
    private let targetRepsKey = "targetReps"
    private let restSecondsKey = "restSeconds"
    private let targetTotalRepsKey = "targetTotalReps"

    // MARK: - Init

    init() {
        loadHistory()
        loadSettings()
        setupWatchConnectivity()
    }

    private func setupWatchConnectivity() {
        // Initialize connectivity manager
        _ = WatchConnectivityManager.shared

        // Listen for workouts from Watch
        NotificationCenter.default.addObserver(
            forName: .workoutReceivedFromWatch,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            if let session = notification.userInfo?["session"] as? WorkoutSession {
                self?.workoutHistory.insert(session, at: 0)
                self?.saveHistory()
            }
        }
    }

    private func syncSettingsToWatch() {
        WatchConnectivityManager.shared.sendSettingsToWatch(
            targetReps: targetReps,
            restSeconds: restSeconds,
            targetTotalReps: targetTotalReps
        )
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
        heavyHaptics.impactOccurred()

        // Keep screen on during workout
        UIApplication.shared.isIdleTimerDisabled = true

        // Start elapsed time timer
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
        let set = WorkoutSet(reps: reps)
        completedSets.append(set)
        heavyHaptics.impactOccurred()

        // Start rest timer
        startRestTimer(seconds: restSeconds)
    }

    func endWorkout() {
        // Store summary data before resetting
        summaryTotalReps = completedReps
        summaryElapsedTime = elapsedSeconds
        summarySetsCompleted = completedSets.count

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

        // Stop timers
        stopRestTimer()
        stopElapsedTimer()

        // Reset workout state
        workoutStarted = false
        currentSetNumber = 1
        completedSets = []
        elapsedSeconds = 0
        workoutStartTime = nil

        // Allow screen to sleep again
        UIApplication.shared.isIdleTimerDisabled = false

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

        // Schedule background notification
        NotificationManager.shared.scheduleRestTimerNotification(seconds: seconds, setNumber: currentSetNumber)

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
                        self.haptics.impactOccurred()
                    }
                } else {
                    self.restTimeRemaining = 0
                    self.heavyHaptics.impactOccurred()
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

        // Cancel notification since we're handling it in-app
        NotificationManager.shared.cancelRestTimerNotification()
    }

    func stopRestTimer() {
        restTimer?.invalidate()
        restTimer = nil
        restTimerStartDate = nil
        restTimerTargetSeconds = 0
        isResting = false
        restTimeRemaining = 0

        // Cancel background notification
        NotificationManager.shared.cancelRestTimerNotification()
    }

    func skipRest() {
        stopRestTimer()
        currentSetNumber += 1
        haptics.impactOccurred()
    }

    func addRestTime(_ seconds: Int) {
        restTimeRemaining += seconds
        restTimerTargetSeconds += seconds
        // Also increase future rest duration
        restSeconds += seconds
        saveSettings()
        haptics.impactOccurred()
    }

    // MARK: - Pause/Resume

    func pauseWorkout() {
        guard !isPaused else { return }
        isPaused = true
        haptics.impactOccurred()

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
        haptics.impactOccurred()

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
                            self.haptics.impactOccurred()
                        }
                    } else {
                        self.restTimeRemaining = 0
                        self.heavyHaptics.impactOccurred()
                        self.restTimerEnded()
                    }
                }
            }
        }
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
        UserDefaults.standard.set(targetTotalReps, forKey: targetTotalRepsKey)

        // Sync to Watch
        syncSettingsToWatch()
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
