//
//  EditSealedProductView.swift
//  PCTracker
//
//  Created by John on 2026-03-08.
//

import SwiftUI
import SwiftData

struct EditSealedProductView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    let product: SealedProduct
    
    @State private var name: String
    @State private var expansion: String
    @State private var buyPrice: String
    @State private var salePrice: String
    @State private var saleDate: Date
    @State private var purchaseDate: Date
    
    init(product: SealedProduct) {
        self.product = product
        _name = State(initialValue: product.name)
        _expansion = State(initialValue: product.expansion ?? "")
        _buyPrice = State(initialValue: String(format: "%.2f", product.buyPrice))
        _salePrice = State(initialValue: product.salePrice != nil ? String(format: "%.2f", product.salePrice!) : "")
        _saleDate = State(initialValue: product.saleDate ?? Date())
        _purchaseDate = State(initialValue: product.purchaseDate)
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Product Information") {
                    TextField("Product Name", text: $name)
                    TextField("Expansion", text: $expansion)
                }
                .autocorrectionDisabled()
                .autocapitalization(.none)
                
                Section("Pricing") {
                    HStack {
                        Text("Buy Price")
                        Spacer()
                        Text("$")
                            .foregroundColor(.secondary)
                        TextField("0.00", text: $buyPrice)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 100)
                    }
                    
                    HStack {
                        Text("Sale Price")
                        Spacer()
                        Text("$")
                            .foregroundColor(.secondary)
                        TextField("Optional", text: $salePrice)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 100)
                    }
                    
                    if !salePrice.isEmpty && Double(salePrice) != nil {
                        DatePicker("Sale Date", selection: $saleDate, displayedComponents: .date)
                    }
                    
                    if let buyPriceValue = Double(buyPrice),
                       let salePriceValue = Double(salePrice),
                       salePriceValue > 0 {
                        let profit = salePriceValue - buyPriceValue
                        HStack {
                            Text("Profit")
                            Spacer()
                            Text("\(profit >= 0 ? "+" : "")$\(profit, format: .number.precision(.fractionLength(2)))")
                                .foregroundColor(profit >= 0 ? .green : .red)
                                .bold()
                        }
                    }
                }
                
                Section("Purchase Date") {
                    DatePicker("Date", selection: $purchaseDate, displayedComponents: .date)
                }
            }
            .navigationTitle("Edit Product")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveChanges()
                    }
                    .bold()
                    .disabled(name.isEmpty || buyPrice.isEmpty)
                }
            }
        }
    }
    
    private func saveChanges() {
        guard let buyPriceValue = Double(buyPrice) else { return }
        
        product.name = name
        product.expansion = expansion.isEmpty ? nil : expansion
        product.buyPrice = buyPriceValue
        
        // Handle sale price and sale date
        if salePrice.isEmpty {
            product.salePrice = nil
            product.saleDate = nil
        } else if let salePriceValue = Double(salePrice) {
            product.salePrice = salePriceValue
            product.saleDate = saleDate
        }
        
        product.purchaseDate = purchaseDate
        
        do {
            try modelContext.save()
        } catch {
            print("Error saving product: \(error)")
        }
        
        dismiss()
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: SealedProduct.self, configurations: config)
    
    let sampleProduct = SealedProduct(name: "Booster Box", expansion: "Base Set", buyPrice: 500.00)
    container.mainContext.insert(sampleProduct)
    
    return EditSealedProductView(product: sampleProduct)
        .modelContainer(container)
}
