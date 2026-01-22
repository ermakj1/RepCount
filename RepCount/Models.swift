//
//  Models.swift
//  RepCount
//
//  Data models for workout tracking
//

import Foundation

// MARK: - Exercise

struct Exercise: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var defaultReps: Int
    var defaultSets: Int
    var defaultRestSeconds: Int

    init(id: UUID = UUID(), name: String, defaultReps: Int = 10, defaultSets: Int = 3, defaultRestSeconds: Int = 60) {
        self.id = id
        self.name = name
        self.defaultReps = defaultReps
        self.defaultSets = defaultSets
        self.defaultRestSeconds = defaultRestSeconds
    }

    static let presets: [Exercise] = [
        Exercise(name: "Push-ups", defaultReps: 10, defaultSets: 3, defaultRestSeconds: 60),
        Exercise(name: "Squats", defaultReps: 15, defaultSets: 3, defaultRestSeconds: 60),
        Exercise(name: "Lunges", defaultReps: 12, defaultSets: 3, defaultRestSeconds: 45),
        Exercise(name: "Burpees", defaultReps: 10, defaultSets: 3, defaultRestSeconds: 90),
        Exercise(name: "Plank", defaultReps: 1, defaultSets: 3, defaultRestSeconds: 60),
        Exercise(name: "Jumping Jacks", defaultReps: 20, defaultSets: 3, defaultRestSeconds: 30),
        Exercise(name: "Mountain Climbers", defaultReps: 20, defaultSets: 3, defaultRestSeconds: 45),
        Exercise(name: "Sit-ups", defaultReps: 15, defaultSets: 3, defaultRestSeconds: 45),
        Exercise(name: "Pull-ups", defaultReps: 8, defaultSets: 3, defaultRestSeconds: 90),
        Exercise(name: "Dips", defaultReps: 10, defaultSets: 3, defaultRestSeconds: 60),
    ]
}

// MARK: - Workout Set

struct WorkoutSet: Identifiable, Codable {
    let id: UUID
    var reps: Int
    var completedAt: Date

    init(id: UUID = UUID(), reps: Int, completedAt: Date = Date()) {
        self.id = id
        self.reps = reps
        self.completedAt = completedAt
    }
}

// MARK: - Workout Session

struct WorkoutSession: Identifiable, Codable {
    let id: UUID
    var exercise: Exercise
    var sets: [WorkoutSet]
    var startedAt: Date
    var completedAt: Date?
    var totalRestTime: TimeInterval

    init(id: UUID = UUID(), exercise: Exercise, sets: [WorkoutSet] = [], startedAt: Date = Date(), completedAt: Date? = nil, totalRestTime: TimeInterval = 0) {
        self.id = id
        self.exercise = exercise
        self.sets = sets
        self.startedAt = startedAt
        self.completedAt = completedAt
        self.totalRestTime = totalRestTime
    }

    var totalReps: Int {
        sets.reduce(0) { $0 + $1.reps }
    }

    var duration: TimeInterval {
        let end = completedAt ?? Date()
        return end.timeIntervalSince(startedAt)
    }

    var isComplete: Bool {
        completedAt != nil
    }
}

// MARK: - Interval Timer Preset

struct IntervalPreset: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var workSeconds: Int
    var restSeconds: Int
    var rounds: Int

    init(id: UUID = UUID(), name: String, workSeconds: Int, restSeconds: Int, rounds: Int) {
        self.id = id
        self.name = name
        self.workSeconds = workSeconds
        self.restSeconds = restSeconds
        self.rounds = rounds
    }

    var totalDuration: TimeInterval {
        TimeInterval((workSeconds + restSeconds) * rounds)
    }

    static let presets: [IntervalPreset] = [
        IntervalPreset(name: "Tabata", workSeconds: 20, restSeconds: 10, rounds: 8),
        IntervalPreset(name: "HIIT 30/30", workSeconds: 30, restSeconds: 30, rounds: 10),
        IntervalPreset(name: "HIIT 45/15", workSeconds: 45, restSeconds: 15, rounds: 8),
        IntervalPreset(name: "EMOM", workSeconds: 50, restSeconds: 10, rounds: 10),
        IntervalPreset(name: "Boxing Rounds", workSeconds: 180, restSeconds: 60, rounds: 3),
    ]
}
