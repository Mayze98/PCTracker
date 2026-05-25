//
//  AddSalePriceView.swift
//  PCTracker
//
//  Created by John on 2026-03-08.
//

import SwiftUI
import SwiftData

// MARK: - Add Sale Price View
struct AddSalePriceView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @AppStorage("currencyCode") private var currencyCode: String = "CAD"
    
    let item: SellableItem
    @State private var salePrice: String = ""
    @State private var saleDate: Date = Date()
    @State private var showError: Bool = false
    
    enum SellableItem {
        case card(Cards)
        case product(SealedProduct)
        
        var name: String {
            switch self {
            case .card(let card):
                return card.name
            case .product(let product):
                return product.name
            }
        }
        
        var buyPrice: Double {
            switch self {
            case .card(let card):
                return card.buyPrice
            case .product(let product):
                return product.buyPrice
            }
        }
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Item")
                            .font(.manrope(.caption, weight: .medium))
                            .foregroundColor(.themeSecondaryText)
                        Text(item.name)
                            .font(.manrope(.headline, weight: .semiBold))
                    }
                    .padding(.vertical, 4)
                    .listRowBackground(Color.themeRowBackground)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Buy Price")
                            .font(.manrope(.caption, weight: .medium))
                            .foregroundColor(.themeSecondaryText)
                        Text(CurrencyFormatter.convertedString(item.buyPrice, code: currencyCode))
                            .font(.manrope(.headline, weight: .semiBold))
                    }
                    .padding(.vertical, 4)
                    .listRowBackground(Color.themeRowBackground)
                }
                
                Section {
                    HStack {
                        Text(CurrencyFormatter.symbol(for: currencyCode))
                            .foregroundColor(.themeSecondaryText)
                        TextField("0.00", text: $salePrice)
                            .keyboardType(.decimalPad)
                    }
                    .listRowBackground(Color.themeRowBackground)
                    
                    DatePicker("Sale Date", selection: $saleDate, displayedComponents: .date)
                        .environment(\.colorScheme, .dark)
                        .listRowBackground(Color.themeRowBackground)
                    
                    if let price = Double(salePrice), price > 0 {
                        let displayBuyPrice = CurrencyFormatter.displayAmount(item.buyPrice, displayCode: currencyCode)
                        let profit = price - displayBuyPrice
                        HStack {
                            Text("Profit")
                            Spacer()
                            Text(CurrencyFormatter.signedString(profit, code: currencyCode, minFraction: 2, maxFraction: 2))
                                .foregroundColor(profit >= 0 ? .themeGold : .themeLoss)
                                .bold()
                        }
                        .listRowBackground(Color.themeRowBackground)
                    }
                } header: {
                    Text("Sale Information")
                        .textCase(nil)
                        .foregroundColor(.themeSecondaryText)
                }
                
                if showError {
                    Section {
                        Text("Please enter a valid sale price")
                            .foregroundColor(.red)
                            .listRowBackground(Color.themeRowBackground)
                    }
                }
            }
            .foregroundColor(.themePrimaryText)
            .scrollContentBackground(.hidden)
            .background(Color.themeBackground)
            .navigationTitle("Mark as Sold")
            .navigationBarTitleDisplayMode(.inline)
            .tint(.themeGold)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveSalePrice()
                    }
                    .bold()
                }
            }
        }
    }
    
    private func saveSalePrice() {
        guard let price = Double(salePrice), price > 0 else {
            showError = true
            return
        }
        
        let storedPrice = CurrencyFormatter.toStorageAmount(price, fromCode: currencyCode)
        
        switch item {
        case .card(let card):
            card.salePrice = storedPrice
            card.saleDate = saleDate
        case .product(let product):
            product.salePrice = storedPrice
            product.saleDate = saleDate
        }
        
        // Save context
        do {
            try modelContext.save()
        } catch {
            #if DEBUG
            print("Error saving sale price: \(error)")
            #endif
        }
        
        dismiss()
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    guard let container = try? ModelContainer(for: Cards.self, SealedProduct.self, configurations: config) else {
        fatalError("Preview ModelContainer failed to initialize")
    }
    
    let sampleCard = Cards(name: "Pikachu", number: "25", graded: false, condition: "NM", buyPrice: 10.00)
    
    return AddSalePriceView(item: .card(sampleCard))
        .modelContainer(container)
}
