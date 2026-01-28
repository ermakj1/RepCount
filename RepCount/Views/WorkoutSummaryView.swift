//
//  WorkoutSummaryView.swift
//  RepCount
//
//  Workout completion summary view
//

import SwiftUI

struct WorkoutSummaryView: View {
    @EnvironmentObject var manager: WorkoutManager

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            // Celebration icon
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 80))
                .foregroundStyle(.green)

            Text("Workout Complete!")
                .font(.largeTitle.bold())

            // Stats
            VStack(spacing: 20) {
                // Total reps
                HStack {
                    Image(systemName: "flame.fill")
                        .font(.title2)
                        .foregroundStyle(.orange)
                    VStack(alignment: .leading) {
                        Text("Total Reps")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Text("\(manager.summaryTotalReps)")
                            .font(.title.bold())
                    }
                    Spacer()
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 12))

                // Elapsed time
                HStack {
                    Image(systemName: "clock.fill")
                        .font(.title2)
                        .foregroundStyle(.blue)
                    VStack(alignment: .leading) {
                        Text("Duration")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Text(formatElapsedTime(manager.summaryElapsedTime))
                            .font(.title.bold())
                    }
                    Spacer()
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 12))

                // Sets completed
                HStack {
                    Image(systemName: "number.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.purple)
                    VStack(alignment: .leading) {
                        Text("Sets Completed")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Text("\(manager.summarySetsCompleted)")
                            .font(.title.bold())
                    }
                    Spacer()
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .padding(.horizontal, 24)

            Spacer()

            // Done button
            Button {
                manager.dismissSummary()
            } label: {
                Text("Done")
                    .font(.title3.bold())
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.blue)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 30)
        }
    }

    private func formatElapsedTime(_ seconds: Int) -> String {
        let hours = seconds / 3600
        let mins = (seconds % 3600) / 60
        let secs = seconds % 60

        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, mins, secs)
        } else {
            return String(format: "%d:%02d", mins, secs)
        }
    }
}

#Preview {
    WorkoutSummaryView()
        .environmentObject(WorkoutManager())
}
