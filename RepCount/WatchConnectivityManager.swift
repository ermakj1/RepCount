//
//  WatchConnectivityManager.swift
//  RepCount
//
//  Handles communication between iPhone and Apple Watch
//

import Foundation
import WatchConnectivity
import Combine

class WatchConnectivityManager: NSObject, ObservableObject {
    static let shared = WatchConnectivityManager()

    @Published var isWatchReachable = false

    private override init() {
        super.init()
        if WCSession.isSupported() {
            WCSession.default.delegate = self
            WCSession.default.activate()
        }
    }

    // MARK: - Send Settings to Watch

    func sendSettingsToWatch(targetReps: Int, restSeconds: Int, targetTotalReps: Int) {
        guard WCSession.default.isReachable else {
            // Try application context for background sync
            sendSettingsViaContext(targetReps: targetReps, restSeconds: restSeconds, targetTotalReps: targetTotalReps)
            return
        }

        let message: [String: Any] = [
            "type": "settings",
            "targetReps": targetReps,
            "restSeconds": restSeconds,
            "targetTotalReps": targetTotalReps
        ]

        WCSession.default.sendMessage(message, replyHandler: nil) { error in
            print("Error sending settings: \(error.localizedDescription)")
        }
    }

    private func sendSettingsViaContext(targetReps: Int, restSeconds: Int, targetTotalReps: Int) {
        let context: [String: Any] = [
            "type": "settings",
            "targetReps": targetReps,
            "restSeconds": restSeconds,
            "targetTotalReps": targetTotalReps
        ]

        do {
            try WCSession.default.updateApplicationContext(context)
        } catch {
            print("Error updating context: \(error.localizedDescription)")
        }
    }
}

// MARK: - WCSessionDelegate

extension WatchConnectivityManager: WCSessionDelegate {
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        DispatchQueue.main.async {
            self.isWatchReachable = session.isReachable
        }
    }

    func sessionDidBecomeInactive(_ session: WCSession) {}

    func sessionDidDeactivate(_ session: WCSession) {
        WCSession.default.activate()
    }

    func sessionReachabilityDidChange(_ session: WCSession) {
        DispatchQueue.main.async {
            self.isWatchReachable = session.isReachable
        }
    }

    // Receive workout data from Watch
    func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        guard let type = message["type"] as? String else { return }

        if type == "workoutComplete" {
            DispatchQueue.main.async {
                self.handleWorkoutFromWatch(message)
            }
        }
    }

    func session(_ session: WCSession, didReceiveUserInfo userInfo: [String: Any] = [:]) {
        guard let type = userInfo["type"] as? String else { return }

        if type == "workoutComplete" {
            DispatchQueue.main.async {
                self.handleWorkoutFromWatch(userInfo)
            }
        }
    }

    private func handleWorkoutFromWatch(_ data: [String: Any]) {
        guard let setsData = data["sets"] as? [Int],
              let targetReps = data["targetReps"] as? Int,
              let restSeconds = data["restSeconds"] as? Int,
              let startTime = data["startTime"] as? TimeInterval,
              let endTime = data["endTime"] as? TimeInterval else {
            return
        }

        // Create workout session and add to history
        let sets = setsData.map { WorkoutSet(reps: $0) }
        let exercise = Exercise(name: "Watch Workout", defaultReps: targetReps, defaultSets: sets.count, defaultRestSeconds: restSeconds)
        let session = WorkoutSession(
            exercise: exercise,
            sets: sets,
            startedAt: Date(timeIntervalSince1970: startTime),
            completedAt: Date(timeIntervalSince1970: endTime),
            totalRestTime: 0
        )

        // Add to shared WorkoutManager
        NotificationCenter.default.post(
            name: .workoutReceivedFromWatch,
            object: nil,
            userInfo: ["session": session]
        )
    }
}

// MARK: - Notification

extension Notification.Name {
    static let workoutReceivedFromWatch = Notification.Name("workoutReceivedFromWatch")
}
