//
//  PhoneConnectivityManager.swift
//  RepCount Watch Watch App
//
//  Handles communication between Watch and iPhone
//

import Foundation
import WatchConnectivity
import Combine

class PhoneConnectivityManager: NSObject, ObservableObject {
    static let shared = PhoneConnectivityManager()

    @Published var isPhoneReachable = false

    // Callbacks for received settings
    var onSettingsReceived: ((Int, Int, Int) -> Void)?

    private override init() {
        super.init()
        if WCSession.isSupported() {
            WCSession.default.delegate = self
            WCSession.default.activate()
        }
    }

    // MARK: - Send Workout to iPhone

    func sendWorkoutToPhone(sets: [Int], targetReps: Int, restSeconds: Int, startTime: Date, endTime: Date) {
        let data: [String: Any] = [
            "type": "workoutComplete",
            "sets": sets,
            "targetReps": targetReps,
            "restSeconds": restSeconds,
            "startTime": startTime.timeIntervalSince1970,
            "endTime": endTime.timeIntervalSince1970
        ]

        // Use transferUserInfo for guaranteed delivery even if phone isn't reachable
        WCSession.default.transferUserInfo(data)

        // Also try direct message if reachable
        if WCSession.default.isReachable {
            WCSession.default.sendMessage(data, replyHandler: nil) { error in
                print("Error sending workout: \(error.localizedDescription)")
            }
        }
    }
}

// MARK: - WCSessionDelegate

extension PhoneConnectivityManager: WCSessionDelegate {
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        DispatchQueue.main.async {
            self.isPhoneReachable = session.isReachable

            // Check for any pending context (settings sent while watch app wasn't running)
            if !session.receivedApplicationContext.isEmpty {
                self.handleReceivedContext(session.receivedApplicationContext)
            }
        }
    }

    func sessionReachabilityDidChange(_ session: WCSession) {
        DispatchQueue.main.async {
            self.isPhoneReachable = session.isReachable
        }
    }

    // Receive settings from iPhone (direct message)
    func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        handleReceivedContext(message)
    }

    // Receive settings from iPhone (background context)
    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
        handleReceivedContext(applicationContext)
    }

    private func handleReceivedContext(_ context: [String: Any]) {
        guard let type = context["type"] as? String, type == "settings" else { return }

        guard let targetReps = context["targetReps"] as? Int,
              let restSeconds = context["restSeconds"] as? Int,
              let targetTotalReps = context["targetTotalReps"] as? Int else {
            return
        }

        DispatchQueue.main.async {
            self.onSettingsReceived?(targetReps, restSeconds, targetTotalReps)
        }
    }
}
