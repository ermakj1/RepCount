//
//  NotificationManager.swift
//  RepCount
//
//  Manages local notifications for rest timer alerts when app is backgrounded
//

import Foundation
import UserNotifications

@MainActor
class NotificationManager: ObservableObject {
    static let shared = NotificationManager()

    private let notificationCenter = UNUserNotificationCenter.current()
    private let restTimerNotificationId = "rest_timer_complete"

    private init() {}

    // MARK: - Permission

    func requestPermission() {
        notificationCenter.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                print("Notification permission error: \(error.localizedDescription)")
            }
        }
    }

    // MARK: - Rest Timer Notifications

    func scheduleRestTimerNotification(seconds: Int, setNumber: Int) {
        // Cancel any existing notification first
        cancelRestTimerNotification()

        let content = UNMutableNotificationContent()
        content.title = "Rest Complete!"
        content.body = "Time to start Set \(setNumber + 1)"
        content.sound = .default
        content.interruptionLevel = .timeSensitive

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: TimeInterval(seconds), repeats: false)
        let request = UNNotificationRequest(identifier: restTimerNotificationId, content: content, trigger: trigger)

        notificationCenter.add(request) { error in
            if let error = error {
                print("Failed to schedule notification: \(error.localizedDescription)")
            }
        }
    }

    func cancelRestTimerNotification() {
        notificationCenter.removePendingNotificationRequests(withIdentifiers: [restTimerNotificationId])
        notificationCenter.removeDeliveredNotifications(withIdentifiers: [restTimerNotificationId])
    }
}
