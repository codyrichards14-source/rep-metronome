//
//  rep_metronomeApp.swift
//  rep metronome
//
//  Created by The Richards on 3/29/26.
//

import SwiftUI

@main
struct rep_metronomeApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var store = AppStore()
    @StateObject private var notificationManager = NotificationManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(store)
                .environmentObject(notificationManager)
        }
    }
}
