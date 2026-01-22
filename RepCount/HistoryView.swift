//
//  HistoryView.swift
//  RepCount
//
//  Workout history and statistics
//

import SwiftUI

struct HistoryView: View {
    @EnvironmentObject var manager: WorkoutManager
    @State private var showClearConfirmation = false

    var body: some View {
        NavigationStack {
            Group {
                if manager.workoutHistory.isEmpty {
                    emptyState
                } else {
                    historyList
                }
            }
            .navigationTitle("History")
            .toolbar {
                if !manager.workoutHistory.isEmpty {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            showClearConfirmation = true
                        } label: {
                            Image(systemName: "trash")
                        }
                    }
                }
            }
            .confirmationDialog("Clear History", isPresented: $showClearConfirmation) {
                Button("Clear All History", role: .destructive) {
                    manager.clearHistory()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This will permanently delete all workout history.")
            }
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "clock.badge.questionmark")
                .font(.system(size: 60))
                .foregroundStyle(.secondary)

            Text("No Workouts Yet")
                .font(.title2)
                .fontWeight(.semibold)

            Text("Complete a workout to see it here")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - History List

    private var historyList: some View {
        List {
            // Summary section
            Section {
                summaryCard
            }

            // Workout list
            Section("Recent Workouts") {
                ForEach(manager.workoutHistory) { session in
                    WorkoutHistoryRow(session: session)
                }
                .onDelete { indexSet in
                    manager.workoutHistory.remove(atOffsets: indexSet)
                }
            }
        }
    }

    // MARK: - Summary Card

    private var summaryCard: some View {
        VStack(spacing: 16) {
            HStack {
                StatBox(
                    title: "Total Workouts",
                    value: "\(manager.workoutHistory.count)",
                    icon: "flame.fill",
                    color: .orange
                )

                StatBox(
                    title: "Total Reps",
                    value: "\(totalReps)",
                    icon: "repeat",
                    color: .blue
                )
            }

            HStack {
                StatBox(
                    title: "Total Sets",
                    value: "\(totalSets)",
                    icon: "square.stack.3d.up.fill",
                    color: .green
                )

                StatBox(
                    title: "This Week",
                    value: "\(workoutsThisWeek)",
                    icon: "calendar",
                    color: .purple
                )
            }
        }
        .padding(.vertical, 8)
    }

    // MARK: - Computed Stats

    private var totalReps: Int {
        manager.workoutHistory.reduce(0) { $0 + $1.totalReps }
    }

    private var totalSets: Int {
        manager.workoutHistory.reduce(0) { $0 + $1.sets.count }
    }

    private var workoutsThisWeek: Int {
        let calendar = Calendar.current
        let weekAgo = calendar.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        return manager.workoutHistory.filter { $0.startedAt > weekAgo }.count
    }
}

// MARK: - Stat Box

struct StatBox: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)

            Text(value)
                .font(.title)
                .fontWeight(.bold)

            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(color.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Workout History Row

struct WorkoutHistoryRow: View {
    let session: WorkoutSession

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(session.exercise.name)
                    .font(.headline)

                Spacer()

                Text(formattedDate)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 16) {
                Label("\(session.sets.count) sets", systemImage: "square.stack")
                Label("\(session.totalReps) reps", systemImage: "repeat")
                Label(formattedDuration, systemImage: "clock")
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }

    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: session.startedAt)
    }

    private var formattedDuration: String {
        let mins = Int(session.duration) / 60
        let secs = Int(session.duration) % 60
        return String(format: "%d:%02d", mins, secs)
    }
}

#Preview {
    HistoryView()
        .environmentObject(WorkoutManager())
}
