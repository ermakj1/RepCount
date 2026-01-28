//
//  RepCountApp.swift
//  RepCount
//
//  Created by Jeffrey Ermak on 1/22/26.
//

import SwiftUI

@main
struct RepCountApp: App {
    init() {
        // Request notification permission on launch
        NotificationManager.shared.requestPermission()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
