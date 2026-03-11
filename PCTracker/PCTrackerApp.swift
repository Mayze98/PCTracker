//
//  PCTrackerApp.swift
//  PCTracker
//
//  Created by John on 2026-02-26.
//

import SwiftData
import SwiftUI

@main
struct PCTrackerApp: App {
    @AppStorage("isDarkMode") private var isDarkMode: Bool = false
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(isDarkMode ? .dark : .light)
        }
        .modelContainer(sharedModelContainer)
    }
    
    // Shared model container with CloudKit support
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Cards.self,
            SealedProduct.self,
            MiscExpense.self
        ])
        
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false
            // cloudKitDatabase: .automatic  // Commented out - enable after configuring CloudKit
        )
        
        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            // Log the error for debugging
            print("❌ Fatal Error: Could not create ModelContainer")
            print("Error details: \(error)")
            print("Error localized description: \(error.localizedDescription)")
            
            // Fall back to in-memory storage if CloudKit configuration fails
            print("⚠️ Attempting fallback to in-memory storage...")
            do {
                let fallbackConfiguration = ModelConfiguration(
                    schema: schema,
                    isStoredInMemoryOnly: true
                )
                let container = try ModelContainer(for: schema, configurations: [fallbackConfiguration])
                print("✅ Successfully created in-memory ModelContainer")
                return container
            } catch {
                print("❌ Fallback also failed: \(error)")
                fatalError("Could not create ModelContainer even with fallback: \(error)")
            }
        }
    }()
}
