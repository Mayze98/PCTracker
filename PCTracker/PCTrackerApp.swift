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
    @AppStorage("isDarkMode") private var isDarkMode: Bool = true
    
    init() {
        // Apply Manrope to navigation bar titles globally
        let largeTitleFont = UIFont(name: "Manrope-Bold", size: 34) ?? .systemFont(ofSize: 34, weight: .bold)
        let inlineTitleFont = UIFont(name: "Manrope-SemiBold", size: 17) ?? .systemFont(ofSize: 17, weight: .semibold)
        
        UINavigationBar.appearance().largeTitleTextAttributes = [.font: largeTitleFont]
        UINavigationBar.appearance().titleTextAttributes = [.font: inlineTitleFont]
        
        // Apply Manrope to tab bar labels
        let tabBarFont = UIFont(name: "Manrope-Medium", size: 10) ?? .systemFont(ofSize: 10, weight: .medium)
        UITabBarItem.appearance().setTitleTextAttributes([.font: tabBarFont], for: .normal)
        UITabBarItem.appearance().setTitleTextAttributes([.font: tabBarFont], for: .selected)
        
        // Theme: set toggle tint to gold
        UISwitch.appearance().onTintColor = UIColor(red: 201/255, green: 168/255, blue: 76/255, alpha: 1.0)
        
        // Theme: DatePicker — gold tint
        UIDatePicker.appearance().tintColor = UIColor(red: 201/255, green: 168/255, blue: 76/255, alpha: 1.0)
        
        // Theme: segmented control — white text for unselected, gold for selected
        let gold = UIColor(red: 201/255, green: 168/255, blue: 76/255, alpha: 1.0)
        UISegmentedControl.appearance().setTitleTextAttributes([.foregroundColor: UIColor.white], for: .normal)
        UISegmentedControl.appearance().setTitleTextAttributes([.foregroundColor: gold], for: .selected)
        UISegmentedControl.appearance().selectedSegmentTintColor = UIColor(red: 30/255, green: 38/255, blue: 64/255, alpha: 1.0) // Surface
        
        // Theme: adaptive bar background — Navy (#1A2340) in light, Deep Navy (#141928) in dark
        let barColor = UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark
                ? UIColor(red: 20/255, green: 25/255, blue: 40/255, alpha: 1.0)   // Deep Navy
                : UIColor(red: 26/255, green: 35/255, blue: 64/255, alpha: 1.0)   // Navy
        }
        
        let navBarAppearance = UINavigationBarAppearance()
        navBarAppearance.configureWithOpaqueBackground()
        navBarAppearance.backgroundColor = barColor
        navBarAppearance.titleTextAttributes = [.font: inlineTitleFont, .foregroundColor: UIColor.white]
        navBarAppearance.largeTitleTextAttributes = [.font: largeTitleFont, .foregroundColor: UIColor.white]
        UINavigationBar.appearance().standardAppearance = navBarAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = navBarAppearance
        UINavigationBar.appearance().compactAppearance = navBarAppearance
        
        let tabBarAppearance = UITabBarAppearance()
        tabBarAppearance.configureWithOpaqueBackground()
        tabBarAppearance.backgroundColor = barColor
        UITabBar.appearance().standardAppearance = tabBarAppearance
        UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
    }
    
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
