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
            HomeView(selectedTab: $selectedTab)
                .tabItem {
                    Label("Home", systemImage: "house")
                }
                .tag(0)
            
            InventoryView(selectedTab: $selectedTab)
                .tabItem {
                    Label("Inventory", systemImage: "cube.box")
                }
                .tag(1)
            
            AddCardView(selectedTab: $selectedTab)
                .tabItem {
                    Label("Add", systemImage: "plus.circle.fill")
                }
                .tag(2)
            
            ArchivedView(selectedTab: $selectedTab)
                .tabItem {
                    Label("Archived", systemImage: "archivebox")
                }
                .tag(3)
            
            SettingsView(selectedTab: $selectedTab)
                .tabItem {
                    Label("Settings", systemImage: "gearshape")
                }
                .tag(4)
        }
        .tint(.themeGold)
        .font(.manrope(.body))
        .foregroundColor(.themePrimaryText)
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Cards.self, SealedProduct.self, MiscExpense.self], inMemory: true)
}

