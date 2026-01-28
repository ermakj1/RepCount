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
    @State private var displayedCount: Int = 20

    private var displayedWorkouts: [WorkoutSession] {
        Array(manager.workoutHistory.prefix(displayedCount))
    }

    private var hasMore: Bool {
        displayedCount < manager.workoutHistory.count
    }

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
                ForEach(displayedWorkouts) { session in
                    WorkoutHistoryRow(session: session)
                }
                .onDelete { indexSet in
                    // Convert indices from displayed workouts to full history
                    let indicesToDelete = IndexSet(indexSet.map { $0 })
                    manager.workoutHistory.remove(atOffsets: indicesToDelete)
                }

                // Load More button
                if hasMore {
                    Button {
                        displayedCount += 20
                    } label: {
                        HStack {
                            Spacer()
                            Text("Load More (\(manager.workoutHistory.count - displayedCount) remaining)")
                                .font(.subheadline)
                            Spacer()
                        }
                    }
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
                Text("\(session.sets.count) sets")
                    .font(.headline)

                Spacer()

                Text(formattedDate)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 16) {
                Label("\(session.totalReps) total reps", systemImage: "repeat")
                Label(formattedDuration, systemImage: "clock")
            }
            .font(.caption)
            .foregroundStyle(.secondary)

            // Show individual sets
            Text(setsBreakdown)
                .font(.caption2)
                .foregroundStyle(.tertiary)
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

    private var setsBreakdown: String {
        session.sets.map { "\($0.reps)" }.joined(separator: " + ") + " reps"
    }
}

#Preview {
    HistoryView()
        .environmentObject(WorkoutManager())
}
