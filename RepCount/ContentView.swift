//
//  ContentView.swift
//  RepCount
//
//  Created by Jeffrey Ermak on 1/22/26.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var manager = WorkoutManager()

    var body: some View {
        TabView {
            CounterView()
                .tabItem {
                    Label("Counter", systemImage: "hand.tap.fill")
                }

            IntervalTimerView()
                .tabItem {
                    Label("Timer", systemImage: "timer")
                }

            HistoryView()
                .tabItem {
                    Label("History", systemImage: "clock.arrow.circlepath")
                }
        }
        .environmentObject(manager)
    }
}

#Preview {
    ContentView()
}
