//
//  ContentView.swift
//  PCTracker
//
//  Created by John on 2026-02-26.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tabItem {
                    Label("Home", systemImage: "house")
                }
                .tag(0)
            
            InventoryView()
                .tabItem {
                    Label("Inventory", systemImage: "cube.box")
                }
                .tag(1)
            
            AddCardView()
                .tabItem {
                    Label("Add", systemImage: "plus.circle.fill")
                }
                .tag(2)
            
            ArchivedView()
                .tabItem {
                    Label("Archived", systemImage: "archivebox")
                }
                .tag(3)
            
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape")
                }
                .tag(4)
        }
        .tint(.adaptiveBlueOrange) // Blue in light mode, Orange in dark mode
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Cards.self, SealedProduct.self, MiscExpense.self], inMemory: true)
}
