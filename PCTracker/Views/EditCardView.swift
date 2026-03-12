//
//  EditCardView.swift
//  PCTracker
//
//  Created by John on 2026-03-08.
//

import SwiftUI
import SwiftData

struct EditCardView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    let card: Cards
    
    @State private var name: String
    @State private var number: String
    @State private var graded: Bool
    @State private var condition: String
    @State private var buyPrice: String
    @State private var salePrice: String
    @State private var saleDate: Date
    @State private var purchaseDate: Date
    
    init(card: Cards) {
        self.card = card
        _name = State(initialValue: card.name)
        _number = State(initialValue: card.number ?? "")
        _graded = State(initialValue: card.graded)
        _condition = State(initialValue: card.condition)
        _buyPrice = State(initialValue: String(format: "%.2f", card.buyPrice))
        _salePrice = State(initialValue: card.salePrice != nil ? String(format: "%.2f", card.salePrice!) : "")
        _saleDate = State(initialValue: card.saleDate ?? Date())
        _purchaseDate = State(initialValue: card.purchaseDate)
    }
    
    let conditions = ["NM", "LP", "MP", "HP", "DMG"]
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Card Information") {
                    TextField("Card Name", text: $name)
                    TextField("Card Number", text: $number)
                }
                .autocorrectionDisabled()
                .autocapitalization(.none)
                
                Section("Condition") {
                    Toggle("Graded", isOn: $graded)
                    
                    if !graded {
                        Picker("Condition", selection: $condition) {
                            ForEach(conditions, id: \.self) { condition in
                                Text(condition).tag(condition)
                            }
                        }
                        .pickerStyle(.segmented)
                    }
                }
                
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
            .navigationTitle("Edit Card")
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
        
        card.name = name
        card.number = number.isEmpty ? nil : number
        card.graded = graded
        card.condition = graded ? "GRADED" : condition
        card.buyPrice = buyPriceValue
        
        // Handle sale price and sale date
        if salePrice.isEmpty {
            card.salePrice = nil
            card.saleDate = nil
        } else if let salePriceValue = Double(salePrice) {
            card.salePrice = salePriceValue
            card.saleDate = saleDate
        }
        
        card.purchaseDate = purchaseDate
        
        do {
            try modelContext.save()
        } catch {
            print("Error saving card: \(error)")
        }
        
        dismiss()
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Cards.self, configurations: config)
    
    let sampleCard = Cards(name: "Pikachu", number: "25", graded: false, condition: "NM", buyPrice: 10.00)
    container.mainContext.insert(sampleCard)
    
    return EditCardView(card: sampleCard)
        .modelContainer(container)
}
