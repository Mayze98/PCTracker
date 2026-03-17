//
//
//  SettingsView.swift
//  PCTracker
//
//  Created by John on 2026-02-26.
//
import SwiftData
import SwiftUI
import CloudKit
import UniformTypeIdentifiers

// MARK: - CSV Export Helper
class CSVExporter {
    static func generateInventoryCSV(cards: [Cards], sealedProducts: [SealedProduct]) -> String {
        var csv = "Type,Name,Number,Condition/Graded,Buy Price,Purchase Date\n"
        
        // Add cards
        for card in cards {
            let conditionText = card.graded ? "GRADED" : card.condition
            let buyPrice = card.buyPrice
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .short
            let dateStr = dateFormatter.string(from: card.purchaseDate)
            let number = card.number ?? ""
            
            csv += "Card,\"\(card.name)\",\"\(number)\",\"\(conditionText)\",\(buyPrice),\(dateStr)\n"
        }
        
        // Add sealed products
        for product in sealedProducts {
            let buyPrice = product.buyPrice
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .short
            let dateStr = dateFormatter.string(from: product.purchaseDate)
            let expansion = product.expansion ?? ""
            
            csv += "Sealed Product,\"\(product.name) - \(expansion)\",,N/A,\(buyPrice),\(dateStr)\n"
        }
        
        return csv
    }
    
    static func generateArchiveCSV(cards: [Cards], sealedProducts: [SealedProduct], miscExpenses: [MiscExpense]) -> String {
        var csv = "Type,Name,Number,Condition/Graded,Buy Price,Sale Price,Profit,Purchase Date\n"
        
        // Add sold cards
        for card in cards {
            let conditionText = card.graded ? "GRADED" : card.condition
            let buyPrice = card.buyPrice
            let salePrice = card.salePrice ?? 0.0
            let profit = card.profit ?? 0
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .short
            let dateStr = dateFormatter.string(from: card.purchaseDate)
            let number = card.number ?? ""
            
            csv += "Card,\"\(card.name)\",\"\(number)\",\"\(conditionText)\",\(buyPrice),\(salePrice),\(profit),\(dateStr)\n"
        }
        
        // Add sold sealed products
        for product in sealedProducts {
            let buyPrice = product.buyPrice
            let salePrice = product.salePrice ?? 0.0
            let profit = product.profit ?? 0
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .short
            let dateStr = dateFormatter.string(from: product.purchaseDate)
            let expansion = product.expansion ?? ""
            
            csv += "Sealed Product,\"\(product.name) - \(expansion)\",,N/A,\(buyPrice),\(salePrice),\(profit),\(dateStr)\n"
        }
        
        // Add misc expenses
        csv += "\nMisc Expenses\n"
        csv += "Description,Cost,Purchase Date,Notes\n"
        for expense in miscExpenses {
            let cost = expense.cost
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .short
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
    @State private var showingExportSheet = false
    @State private var showingShareSheet = false
    @State private var exportType: ExportType = .inventory
    @State private var csvData: String = ""
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
                    HStack {
                        Text("Currency")
                        Spacer()
                        Text("CAD")
                            .foregroundColor(.themeSecondaryText)
                    }
                    .listRowBackground(Color.themeRowBackground)
                    Toggle("Dark Mode", isOn: $isDarkMode)
                        .listRowBackground(Color.themeRowBackground)
                } header: {
                    Text("Display")
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
                ShareSheet(activityItems: [csvData])
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
            csvData = CSVExporter.generateInventoryCSV(cards: inventoryCards, sealedProducts: inventoryProducts)
        case .archive:
            let archivedCards = allCards.filter { $0.salePrice != nil }
            let archivedProducts = allSealedProducts.filter { $0.salePrice != nil }
            csvData = CSVExporter.generateArchiveCSV(cards: archivedCards, sealedProducts: archivedProducts, miscExpenses: miscExpenses)
        }
        
        showingShareSheet = true
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
        let fileName = "PCTracker_Export_\(Date.now).csv"
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        
        if let csvString = activityItems.first as? String {
            try? csvString.write(to: tempURL, atomically: true, encoding: .utf8)
            let controller = UIActivityViewController(activityItems: [tempURL], applicationActivities: nil)
            return controller
        }
        
        return UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#Preview {
    SettingsView(selectedTab: .constant(4))
        .modelContainer(for: [Cards.self, SealedProduct.self, MiscExpense.self], inMemory: true)
}

