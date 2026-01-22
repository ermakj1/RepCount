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

    // Current workout
    @Published var currentSession: WorkoutSession?
    @Published var currentReps: Int = 0
    @Published var currentSetNumber: Int = 1

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
    private let haptics = UIImpactFeedbackGenerator(style: .medium)
    private let heavyHaptics = UIImpactFeedbackGenerator(style: .heavy)

    // MARK: - Persistence Keys

    private let historyKey = "workoutHistory"

    // MARK: - Init

    init() {
        loadHistory()
    }

    // MARK: - Rep Counting

    func incrementRep() {
        currentReps += 1
        haptics.impactOccurred()
    }

    func decrementRep() {
        if currentReps > 0 {
            currentReps -= 1
            haptics.impactOccurred()
        }
    }

    func resetReps() {
        currentReps = 0
    }

    // MARK: - Workout Session

    func startWorkout(exercise: Exercise) {
        currentSession = WorkoutSession(exercise: exercise)
        currentReps = 0
        currentSetNumber = 1
    }

    func completeSet() {
        guard var session = currentSession else { return }

        let set = WorkoutSet(reps: currentReps)
        session.sets.append(set)
        currentSession = session

        heavyHaptics.impactOccurred()

        if currentSetNumber < session.exercise.defaultSets {
            currentSetNumber += 1
            currentReps = 0
            startRestTimer(seconds: session.exercise.defaultRestSeconds)
        } else {
            finishWorkout()
        }
    }

    func finishWorkout() {
        guard var session = currentSession else { return }

        session.completedAt = Date()
        workoutHistory.insert(session, at: 0)
        saveHistory()

        currentSession = nil
        currentReps = 0
        currentSetNumber = 1
        stopRestTimer()
    }

    func cancelWorkout() {
        currentSession = nil
        currentReps = 0
        currentSetNumber = 1
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
                    self.stopRestTimer()
                }
            }
        }
    }

    func stopRestTimer() {
        restTimer?.invalidate()
        restTimer = nil
        isResting = false
        restTimeRemaining = 0
    }

    func skipRest() {
        stopRestTimer()
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

    func pauseIntervalTimer() {
        intervalTimer?.invalidate()
        intervalTimer = nil
    }

    func resumeIntervalTimer() {
        guard currentIntervalPreset != nil, isIntervalTimerRunning else { return }

        intervalTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.tickIntervalTimer()
            }
        }
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
