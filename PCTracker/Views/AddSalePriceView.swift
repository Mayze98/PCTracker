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
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(item.name)
                            .font(.headline)
                    }
                    .padding(.vertical, 4)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Buy Price")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("$\(item.buyPrice, format: .number.precision(.fractionLength(2)))")
                            .font(.headline)
                    }
                    .padding(.vertical, 4)
                }
                
                Section("Sale Information") {
                    HStack {
                        Text("$")
                            .foregroundColor(.secondary)
                        TextField("0.00", text: $salePrice)
                            .keyboardType(.decimalPad)
                    }
                    
                    DatePicker("Sale Date", selection: $saleDate, displayedComponents: .date)
                    
                    if let price = Double(salePrice), price > 0 {
                        let profit = price - item.buyPrice
                        HStack {
                            Text("Profit")
                            Spacer()
                            Text("\(profit >= 0 ? "+" : "")$\(profit, format: .number.precision(.fractionLength(2)))")
                                .foregroundColor(profit >= 0 ? .green : .red)
                                .bold()
                        }
                    }
                }
                
                if showError {
                    Section {
                        Text("Please enter a valid sale price")
                            .foregroundColor(.red)
                    }
                }
            }
            .navigationTitle("Mark as Sold")
            .navigationBarTitleDisplayMode(.inline)
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
        
        switch item {
        case .card(let card):
            card.salePrice = price
            card.saleDate = saleDate
        case .product(let product):
            product.salePrice = price
            product.saleDate = saleDate
        }
        
        // Save context
        do {
            try modelContext.save()
        } catch {
            print("Error saving sale price: \(error)")
        }
        
        dismiss()
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Cards.self, SealedProduct.self, configurations: config)
    
    let sampleCard = Cards(name: "Pikachu", number: "25", graded: false, condition: "NM", buyPrice: 10.00)
    
    return AddSalePriceView(item: .card(sampleCard))
        .modelContainer(container)
}
