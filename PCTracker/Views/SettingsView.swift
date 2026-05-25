//
//
//  SettingsView.swift
//  PCTracker
//
//  Created by John on 2026-02-26.
//
import Foundation
import SwiftData
import SwiftUI
import CloudKit
import UniformTypeIdentifiers

// MARK: - CSV Export Helper
class CSVExporter {
    
    /// Converts a stored CAD value to the current display currency for export.
    private static func displayPrice(_ storedValue: Double, code: String) -> String {
        let displayed = CurrencyFormatter.displayAmount(storedValue, displayCode: code)
        return String(format: "%.2f", displayed)
    }
    
    static func generateInventoryCSV(cards: [Cards], sealedProducts: [SealedProduct], currencyCode: String) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .short
        
        var csv = "Type,Name,Number,Card Set,Condition/Graded,Buy Price (\(currencyCode)),Market Price (\(currencyCode)),Purchase Date\n"
        
        // Add cards
        for card in cards {
            let conditionText = card.graded ? (card.gradeLevel.map { "PSA \($0)" } ?? "GRADED") : card.condition
            let buyPrice = displayPrice(card.buyPrice, code: currencyCode)
            let marketPrice = card.marketPrice.map { displayPrice($0, code: currencyCode) } ?? ""
            let dateStr = dateFormatter.string(from: card.purchaseDate)
            let number = card.number ?? ""
            let cardSet = card.cardSet ?? ""
            
            csv += "Card,\"\(card.name)\",\"\(number)\",\"\(cardSet)\",\"\(conditionText)\",\(buyPrice),\(marketPrice),\(dateStr)\n"
        }
        
        // Add sealed products
        for product in sealedProducts {
            let buyPrice = displayPrice(product.buyPrice, code: currencyCode)
            let dateStr = dateFormatter.string(from: product.purchaseDate)
            let expansion = product.expansion ?? ""
            
            csv += "Sealed Product,\"\(product.name)\",,,\"\(expansion)\",\(buyPrice),,\(dateStr)\n"
        }
        
        return csv
    }
    
    static func generateArchiveCSV(cards: [Cards], sealedProducts: [SealedProduct], miscExpenses: [MiscExpense], currencyCode: String) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .short
        
        var csv = "Type,Name,Number,Card Set,Condition/Graded,Buy Price (\(currencyCode)),Sale Price (\(currencyCode)),Profit (\(currencyCode)),Purchase Date,Sale Date\n"
        
        // Add sold cards
        for card in cards {
            let conditionText = card.graded ? (card.gradeLevel.map { "PSA \($0)" } ?? "GRADED") : card.condition
            let buyPrice = displayPrice(card.buyPrice, code: currencyCode)
            let salePrice = card.salePrice.map { displayPrice($0, code: currencyCode) } ?? "0.00"
            let profit = card.profit.map { displayPrice($0, code: currencyCode) } ?? "0.00"
            let dateStr = dateFormatter.string(from: card.purchaseDate)
            let saleDateStr = card.saleDate.map { dateFormatter.string(from: $0) } ?? ""
            let number = card.number ?? ""
            let cardSet = card.cardSet ?? ""
            
            csv += "Card,\"\(card.name)\",\"\(number)\",\"\(cardSet)\",\"\(conditionText)\",\(buyPrice),\(salePrice),\(profit),\(dateStr),\(saleDateStr)\n"
        }
        
        // Add sold sealed products
        for product in sealedProducts {
            let buyPrice = displayPrice(product.buyPrice, code: currencyCode)
            let salePrice = product.salePrice.map { displayPrice($0, code: currencyCode) } ?? "0.00"
            let profit = product.profit.map { displayPrice($0, code: currencyCode) } ?? "0.00"
            let dateStr = dateFormatter.string(from: product.purchaseDate)
            let saleDateStr = product.saleDate.map { dateFormatter.string(from: $0) } ?? ""
            let expansion = product.expansion ?? ""
            
            csv += "Sealed Product,\"\(product.name)\",,,\"\(expansion)\",\(buyPrice),\(salePrice),\(profit),\(dateStr),\(saleDateStr)\n"
        }
        
        // Add misc expenses
        csv += "\nMisc Expenses\n"
        csv += "Description,Cost (\(currencyCode)),Purchase Date,Notes\n"
        for expense in miscExpenses {
            let cost = displayPrice(expense.cost, code: currencyCode)
            let dateStr = dateFormatter.string(from: expense.purchaseDate)
            let notes = expense.notes?.replacingOccurrences(of: "\"", with: "\"\"") ?? ""
            
            csv += "\"\(expense.itemDescription)\",\(cost),\(dateStr),\"\(notes)\"\n"
        }
        
        return csv
    }
}

// MARK: - Settings View
struct SettingsView: View {
    @Binding var selectedTab: Int
    
    @Query private var allCards: [Cards]
    @Query private var allSealedProducts: [SealedProduct]
    @Query private var miscExpenses: [MiscExpense]
    
    @AppStorage("isDarkMode") private var isDarkMode: Bool = true
    @AppStorage("currencyCode") private var currencyCode: String = "CAD"
    @AppStorage("usdToCadRate") private var usdToCadRate: Double = 1.35
    @AppStorage("usdToCadRateUpdatedAt") private var usdToCadRateUpdatedAt: Double = 0
    @State private var rapidApiKey: String = ""
    @State private var showingExportSheet = false
    @State private var showingShareSheet = false
    @State private var exportType: ExportType = .inventory
    @State private var csvData: String = ""
    @State private var csvFileURL: URL?
    @State private var iCloudStatus: String = "Checking..."
    
    @State private var showingImporter = false
    @State private var importError: String?
    @State private var importInProgress = false
    @Environment(\.modelContext) private var modelContext
    @State private var importedCount: Int = 0

    
    enum ExportType {
        case inventory
        case archive
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                VStack(alignment: .leading, spacing: 4) {
                    Text("Settings")
                        .font(.manrope(24, weight: .bold))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)
                .padding(.top, 8)
                .background(Color.themeBackground)
                
                List {
                    Section {
                    HStack {
                        Text("User")
                        Spacer()
                        Text("Guest")
                            .foregroundColor(.themeSecondaryText)
                    }
                    .listRowBackground(Color.themeRowBackground)
                } header: {
                    Text("Account")
                        .textCase(nil)
                }
                
                Section {
                    HStack {
                        Text("Status")
                        Spacer()
                        Text(iCloudStatus)
                            .foregroundColor(.themeSecondaryText)
                    }
                    .listRowBackground(Color.themeRowBackground)
                } header: {
                    Text("iCloud Sync")
                        .textCase(nil)
                }
                
                Section {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Currency")
                            .font(.manrope(.subheadline, weight: .medium))
                            .foregroundColor(.themeSecondaryText)

                        Picker("Currency", selection: $currencyCode) {
                            Text("USD").tag("USD")
                            Text("CAD").tag("CAD")
                        }
                        .pickerStyle(.segmented)
                    }
                    .listRowBackground(Color.themeRowBackground)

                    HStack {
                        Text("USD to CAD Rate")
                        Spacer()
                        Text(usdToCadRate, format: .number.precision(.fractionLength(4)))
                            .foregroundColor(.themeSecondaryText)
                    }
                    .listRowBackground(Color.themeRowBackground)

                    if usdToCadRateUpdatedAt > 0 {
                        HStack {
                            Text("Rate Updated")
                            Spacer()
                            Text(Date(timeIntervalSince1970: usdToCadRateUpdatedAt), format: .dateTime.month().day().year().hour().minute())
                                .foregroundColor(.themeSecondaryText)
                        }
                        .listRowBackground(Color.themeRowBackground)
                    }

                    Toggle("Dark Mode", isOn: $isDarkMode)
                        .listRowBackground(Color.themeRowBackground)
                } header: {
                    Text("Display")
                        .textCase(nil)
                }
                
                Section {
                    if rapidApiKey.isEmpty {
                        SecureField("RapidAPI Key", text: $rapidApiKey)
                            .font(.manrope(.body))
                            .listRowBackground(Color.themeRowBackground)
                    } else {
                        HStack {
                            Text("API Key")
                            Spacer()
                            Text("Configured")
                                .foregroundColor(.themeSecondaryText)
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                                .font(.caption)
                        }
                        .listRowBackground(Color.themeRowBackground)
                        
                        Button("Clear API Key", role: .destructive) {
                            rapidApiKey = ""
                        }
                        .font(.manrope(.body))
                        .listRowBackground(Color.themeRowBackground)
                    }
                    
                    Text("Used for graded card prices via eBay sold listings. Get a free key at rapidapi.com")
                        .font(.manrope(.caption, weight: .regular))
                        .foregroundColor(.themeSecondaryText)
                        .listRowBackground(Color.themeRowBackground)
                } header: {
                    Text("eBay Price Lookup")
                        .textCase(nil)
                }
                
                Section {
                    if importInProgress {
                        HStack {
                            Spacer()
                            ProgressView {
                                Text("Importing...")
                            }
                            Spacer()
                        }
                        .listRowBackground(Color.themeRowBackground)
                    } else {
                        Button("Import CSV") {
                            showingImporter = true
                        }
                        .foregroundColor(.themeGold)
                        .listRowBackground(Color.themeRowBackground)
                    }
                } header: {
                    Text("Import")
                        .textCase(nil)
                }
                
                Section {
                    Button("Export Inventory to CSV") {
                        exportType = .inventory
                        generateCSV()
                    }
                    .foregroundColor(.themeGold)
                    .listRowBackground(Color.themeRowBackground)
                    
                    Button("Export Archive to CSV") {
                        exportType = .archive
                        generateCSV()
                    }
                    .foregroundColor(.themeGold)
                    .listRowBackground(Color.themeRowBackground)
                } header: {
                    Text("Export")
                        .textCase(nil)
                }
                
                Section {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.themeSecondaryText)
                    }
                    .listRowBackground(Color.themeRowBackground)
                } header: {
                    Text("About")
                        .textCase(nil)
                }
                }
                .contentMargins(.top, 8)
                .listSectionSpacing(12)
                .scrollContentBackground(.hidden)
                .background(Color.themeBackground)
                
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .navigationBar)
        .tint(.themeGold)
        .preferredColorScheme(isDarkMode ? .dark : .light)
        .sheet(isPresented: $showingShareSheet) {
            if let url = csvFileURL {
                ShareSheet(activityItems: [url])
            }
        }
            .fileImporter(
                isPresented: $showingImporter,
                allowedContentTypes: [.commaSeparatedText],
                allowsMultipleSelection: false
            ) { result in
                handleImport(result: result)
            }
            .alert("Import Error", isPresented: .constant(importError != nil), actions: {
                Button("OK") {
                    importError = nil
                }
            }, message: {
                Text(importError ?? "")
            })
            .alert("Import Complete", isPresented: .constant(importedCount > 0 && !importInProgress), actions: {
                Button("OK") {
                    importedCount = 0
                }
            }, message: {
                Text("Imported \(importedCount) rows.")
            })
            .onAppear {
                checkiCloudStatus()
                // Load API key from Keychain
                rapidApiKey = KeychainHelper.load(for: "rapidApiKey") ?? ""
                // Migrate from UserDefaults if present
                if rapidApiKey.isEmpty, let legacyKey = UserDefaults.standard.string(forKey: "rapidApiKey"), !legacyKey.isEmpty {
                    KeychainHelper.save(legacyKey, for: "rapidApiKey")
                    UserDefaults.standard.removeObject(forKey: "rapidApiKey")
                    rapidApiKey = legacyKey
                }
            }
            .onChange(of: rapidApiKey) { _, newValue in
                if newValue.isEmpty {
                    KeychainHelper.delete(for: "rapidApiKey")
                } else {
                    KeychainHelper.save(newValue, for: "rapidApiKey")
                }
            }
        }
    }

    private func checkiCloudStatus() {
        // CloudKit is currently disabled
        // To enable: Configure iCloud capability in Xcode project settings
        iCloudStatus = "Local Storage Only"
        
        /* Uncomment when CloudKit is configured:
        // Skip CloudKit check in previews
        #if targetEnvironment(simulator)
        if ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1" {
            iCloudStatus = "Preview Mode"
            return
        }
        #endif
        
        CKContainer.default().accountStatus { status, error in
            DispatchQueue.main.async {
                if error != nil {
                    iCloudStatus = "Error"
                    return
                }
                
                switch status {
                case .available:
                    iCloudStatus = "Connected ✓"
                case .noAccount:
                    iCloudStatus = "Not Signed In"
                case .restricted:
                    iCloudStatus = "Restricted"
                case .couldNotDetermine:
                    iCloudStatus = "Unknown"
                case .temporarilyUnavailable:
                    iCloudStatus = "Temporarily Unavailable"
                @unknown default:
                    iCloudStatus = "Unknown"
                }
            }
        }
        */
    }
    
    private func generateCSV() {
        switch exportType {
        case .inventory:
            let inventoryCards = allCards.filter { $0.salePrice == nil }
            let inventoryProducts = allSealedProducts.filter { $0.salePrice == nil }
            csvData = CSVExporter.generateInventoryCSV(cards: inventoryCards, sealedProducts: inventoryProducts, currencyCode: currencyCode)
        case .archive:
            let archivedCards = allCards.filter { $0.salePrice != nil }
            let archivedProducts = allSealedProducts.filter { $0.salePrice != nil }
            csvData = CSVExporter.generateArchiveCSV(cards: archivedCards, sealedProducts: archivedProducts, miscExpenses: miscExpenses, currencyCode: currencyCode)
        }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd_HHmmss"
        let typeLabel = exportType == .inventory ? "Inventory" : "Archive"
        let fileName = "PCTracker_\(typeLabel)_\(formatter.string(from: Date())).csv"
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        
        do {
            try csvData.write(to: tempURL, atomically: true, encoding: .utf8)
            csvFileURL = tempURL
            showingShareSheet = true
        } catch {
            #if DEBUG
            print("Failed to write CSV file: \(error)")
            #endif
        }
    }
    
    private func handleImport(result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            
            // Start accessing the security-scoped resource
            guard url.startAccessingSecurityScopedResource() else {
                importError = "Unable to access the file. Please try again."
                return
            }
            
            Task {
                importInProgress = true
                defer {
                    // Stop accessing the security-scoped resource after import completes
                    url.stopAccessingSecurityScopedResource()
                    importInProgress = false
                }
                
                do {
                    let content = try String(contentsOf: url, encoding: .utf8)
                    if let header = content.components(separatedBy: "\n").first?.lowercased() {
                        if header.contains("sale price") {
                            try await CSVImporter.importArchiveCSV(from: url, into: modelContext)
                        } else {
                            try await CSVImporter.importInventoryCSV(from: url, into: modelContext)
                        }
                    }
                    importError = nil
                    
                    // Count imported rows - non-empty lines, excluding header
                    let rows = content.components(separatedBy: "\n").filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
                    importedCount = max(0, rows.count - 1)
                } catch {
                    importError = error.localizedDescription
                }
            }
        case .failure(let error):
            importError = error.localizedDescription
        }
    }
}

// MARK: - Share Sheet for iOS
struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#Preview {
    SettingsView(selectedTab: .constant(4))
        .modelContainer(previewContainer)
}
