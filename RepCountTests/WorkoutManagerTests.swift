//
//  WorkoutManagerTests.swift
//  RepCountTests
//
//  Tests for WorkoutManager state transitions, timer logic, pause/resume, and persistence
//

import Testing
import Foundation
@testable import RepCount

@MainActor
struct WorkoutManagerTests {

    // MARK: - State Transition Tests

    @Test func testStartWorkout_SetsCorrectInitialState() async throws {
        let manager = WorkoutManager()

        manager.targetReps = 10
        manager.restSeconds = 60
        manager.targetTotalReps = 100

        manager.startWorkout()

        #expect(manager.workoutStarted == true)
        #expect(manager.currentSetNumber == 1)
        #expect(manager.completedSets.isEmpty)
        #expect(manager.elapsedSeconds == 0)
        #expect(manager.isPaused == false)
    }

    @Test func testCompleteSet_AddsToCompletedSets() async throws {
        let manager = WorkoutManager()
        manager.startWorkout()

        manager.completeSet(reps: 10)

        #expect(manager.completedSets.count == 1)
        #expect(manager.completedSets.first?.reps == 10)
        #expect(manager.completedReps == 10)
    }

    @Test func testCompleteSet_StartsRestTimer() async throws {
        let manager = WorkoutManager()
        manager.restSeconds = 30
        manager.startWorkout()

        manager.completeSet(reps: 10)

        #expect(manager.isResting == true)
        #expect(manager.restTimeRemaining == 30)
    }

    @Test func testEndWorkout_ShowsSummary() async throws {
        let manager = WorkoutManager()
        manager.startWorkout()
        manager.completeSet(reps: 10)
        manager.completeSet(reps: 12)

        manager.endWorkout()

        #expect(manager.showingSummary == true)
        #expect(manager.summaryTotalReps == 22)
        #expect(manager.summarySetsCompleted == 2)
        #expect(manager.workoutStarted == false)
    }

    @Test func testDismissSummary_ResetsState() async throws {
        let manager = WorkoutManager()
        manager.startWorkout()
        manager.completeSet(reps: 10)
        manager.endWorkout()

        manager.dismissSummary()

        #expect(manager.showingSummary == false)
        #expect(manager.summaryTotalReps == 0)
        #expect(manager.summaryElapsedTime == 0)
        #expect(manager.summarySetsCompleted == 0)
    }

    // MARK: - Timer Logic Tests

    @Test func testElapsedTimeAccuracy() async throws {
        let manager = WorkoutManager()
        manager.startWorkout()

        // Wait 2 seconds
        try await Task.sleep(nanoseconds: 2_000_000_000)

        // Allow for some variance (within 1 second tolerance)
        #expect(manager.elapsedSeconds >= 1)
        #expect(manager.elapsedSeconds <= 3)
    }

    @Test func testRestTimerCountdown() async throws {
        let manager = WorkoutManager()
        manager.restSeconds = 10
        manager.startWorkout()

        manager.completeSet(reps: 10)

        let initialRemaining = manager.restTimeRemaining

        // Wait 2 seconds
        try await Task.sleep(nanoseconds: 2_000_000_000)

        // Rest timer should have decreased
        #expect(manager.restTimeRemaining < initialRemaining)
        #expect(manager.restTimeRemaining >= 7) // Should be around 8 seconds remaining
        #expect(manager.restTimeRemaining <= 9)
    }

    @Test func testSkipRest_IncrementsSetNumber() async throws {
        let manager = WorkoutManager()
        manager.startWorkout()
        manager.completeSet(reps: 10)

        let setNumberBeforeSkip = manager.currentSetNumber

        manager.skipRest()

        #expect(manager.isResting == false)
        #expect(manager.currentSetNumber == setNumberBeforeSkip + 1)
    }

    @Test func testAddRestTime_IncreasesRemaining() async throws {
        let manager = WorkoutManager()
        manager.restSeconds = 30
        manager.startWorkout()
        manager.completeSet(reps: 10)

        let initialRemaining = manager.restTimeRemaining

        manager.addRestTime(10)

        #expect(manager.restTimeRemaining == initialRemaining + 10)
        #expect(manager.restSeconds == 40) // Future rest time also increased
    }

    // MARK: - Pause/Resume Tests

    @Test func testPauseWorkout_StopsTimers() async throws {
        let manager = WorkoutManager()
        manager.startWorkout()

        // Let some time pass
        try await Task.sleep(nanoseconds: 1_000_000_000)
        let elapsedBeforePause = manager.elapsedSeconds

        manager.pauseWorkout()

        #expect(manager.isPaused == true)

        // Wait more time - elapsed should not increase
        try await Task.sleep(nanoseconds: 1_000_000_000)

        #expect(manager.elapsedSeconds == elapsedBeforePause)
    }

    @Test func testResumeWorkout_ContinuesFromPausedTime() async throws {
        let manager = WorkoutManager()
        manager.startWorkout()

        // Let some time pass
        try await Task.sleep(nanoseconds: 1_000_000_000)

        manager.pauseWorkout()
        let elapsedAtPause = manager.elapsedSeconds

        // Wait while paused - shouldn't count
        try await Task.sleep(nanoseconds: 1_000_000_000)

        manager.resumeWorkout()

        #expect(manager.isPaused == false)

        // Wait a bit after resuming
        try await Task.sleep(nanoseconds: 1_000_000_000)

        // Should have continued from pause point
        #expect(manager.elapsedSeconds >= elapsedAtPause + 1)
        #expect(manager.elapsedSeconds <= elapsedAtPause + 2)
    }

    @Test func testPauseDuringRest_PreservesRemaining() async throws {
        let manager = WorkoutManager()
        manager.restSeconds = 30
        manager.startWorkout()
        manager.completeSet(reps: 10)

        // Let rest timer run a bit
        try await Task.sleep(nanoseconds: 1_000_000_000)
        let remainingBeforePause = manager.restTimeRemaining

        manager.pauseWorkout()

        #expect(manager.isPaused == true)

        // Wait while paused
        try await Task.sleep(nanoseconds: 1_000_000_000)

        // Rest timer should not have changed
        #expect(manager.restTimeRemaining == remainingBeforePause)
    }

    // MARK: - Computed Properties Tests

    @Test func testProgressPercent_CalculatesCorrectly() async throws {
        let manager = WorkoutManager()
        manager.targetTotalReps = 100
        manager.startWorkout()

        #expect(manager.progressPercent == 0.0)

        manager.completeSet(reps: 25)
        #expect(manager.progressPercent == 0.25)

        manager.skipRest()
        manager.completeSet(reps: 25)
        #expect(manager.progressPercent == 0.50)
    }

    @Test func testIsGoalComplete_ReturnsTrueWhenReached() async throws {
        let manager = WorkoutManager()
        manager.targetTotalReps = 20
        manager.startWorkout()

        #expect(manager.isGoalComplete == false)

        manager.completeSet(reps: 10)
        #expect(manager.isGoalComplete == false)

        manager.skipRest()
        manager.completeSet(reps: 10)
        #expect(manager.isGoalComplete == true)
    }

    // MARK: - Persistence Tests

    @Test func testSettingsPersistence() async throws {
        let manager = WorkoutManager()

        // Set custom values
        manager.targetReps = 15
        manager.restSeconds = 90
        manager.targetTotalReps = 150

        // Start and end workout to trigger save
        manager.startWorkout()
        manager.endWorkout()

        // Create new manager to test loading
        let newManager = WorkoutManager()

        // Values should be loaded from persistence
        #expect(newManager.targetReps == 15)
        #expect(newManager.restSeconds == 90)
        #expect(newManager.targetTotalReps == 150)
    }

    @Test func testHistorySaveAndLoad() async throws {
        let manager = WorkoutManager()
        let initialHistoryCount = manager.workoutHistory.count

        manager.targetReps = 10
        manager.startWorkout()
        manager.completeSet(reps: 10)
        manager.completeSet(reps: 12)
        manager.endWorkout()
        manager.dismissSummary()

        #expect(manager.workoutHistory.count == initialHistoryCount + 1)

        // Create new manager to verify persistence
        let newManager = WorkoutManager()
        #expect(newManager.workoutHistory.count == initialHistoryCount + 1)
    }

    @Test func testClearHistory_RemovesAllWorkouts() async throws {
        let manager = WorkoutManager()

        // Add a workout
        manager.startWorkout()
        manager.completeSet(reps: 10)
        manager.endWorkout()
        manager.dismissSummary()

        #expect(manager.workoutHistory.count > 0)

        manager.clearHistory()

        #expect(manager.workoutHistory.isEmpty)
    }

    // MARK: - Format Time Tests

    @Test func testFormatTime_FormatsCorrectly() async throws {
        let manager = WorkoutManager()

        #expect(manager.formatTime(0) == "0:00")
        #expect(manager.formatTime(30) == "0:30")
        #expect(manager.formatTime(60) == "1:00")
        #expect(manager.formatTime(90) == "1:30")
        #expect(manager.formatTime(125) == "2:05")
    }
}
