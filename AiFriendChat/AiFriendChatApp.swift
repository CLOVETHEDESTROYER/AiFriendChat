//
//  AiFriendChatApp.swift
//  AiFriendChat
//
//  Created by Carlos Alvarez on 10/19/24.
//

import SwiftUI
import SwiftData

@main
struct AiFriendChatApp: App {
    @StateObject private var authViewModel = AuthViewModel()

    let container: ModelContainer = {
        do {
            let schema = Schema([
                CallSchedule.self,
                CallHistory.self,
                SavedPrompt.self
            ])
            let modelConfiguration = ModelConfiguration(schema: schema)
            
            return try ModelContainer(for: schema, configurations: modelConfiguration)
        } catch {
            print("SwiftData Container Error: \(error)")
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()
    
    init() {
        // Initialize theme settings
        _ = ThemeManager.shared
        ThemeManager.applyTheme()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authViewModel)
                .preferredColorScheme(.dark)
                .background(ThemeManager.shared.backgroundColor)
        }
        .modelContainer(container)
    }
}
