//
//  TrackCardView.swift
//  PCTracker
//
//  Created by John on 2026-02-26.
//
import SwiftUI
import SwiftData

// MARK: - Add Card View
struct AddCardView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var showingAddCard = false
    @State private var showingAddProduct = false
    @State private var showingAddMisc = false

    
    var body: some View {
        NavigationView {
            VStack {
                Button(action: {
                    showingAddCard = true
                }) {
                    Text("\(Image(systemName: "plus.circle")) Add card")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.adaptiveBlueOrange)
                        .cornerRadius(12)
                }
                .padding(.horizontal)
                .padding(.top, 32)
                .padding(.bottom, 16)

                Button(action: {
                    showingAddProduct = true
                }) {
                    Text("\(Image(systemName: "plus.circle")) Add sealed product")
                        .font(.system(size:17, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.adaptiveBlueOrange)
                        .cornerRadius(12)
                }
                .padding(.horizontal)
                .padding(.bottom, 16)
                Button(action: {
                    showingAddMisc = true
                }) {
                    Text("\(Image(systemName: "plus.circle")) Add misc expense")
                        .font(.system(size:17, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.adaptiveBlueOrange)
                        .cornerRadius(12)
                }
                .padding(.horizontal)
                .padding(.bottom, 16)
                
                Spacer()

            }
            .navigationTitle("Add Inventory")
            .sheet(isPresented: $showingAddCard) {
                AddCardFormView(modelContext: modelContext, onSave: {
                    showingAddCard = false
                })
            }
            .sheet(isPresented: $showingAddProduct) {
                AddSealedFormView(modelContext: modelContext, onSave: {
                    showingAddProduct = false
                })
            }
            .sheet(isPresented: $showingAddMisc) {
                AddMiscFormView(modelContext: modelContext, onSave: {
                    showingAddMisc = false
                })
            }
        }
    }
}

// MARK: - Add Card Form View
struct AddCardFormView: View {
    @Environment(\.dismiss) private var dismiss
    let modelContext: ModelContext
    var onSave: () -> Void
    
    @State private var name: String = ""
    @State private var number: String = ""
    @State private var graded: Bool = false
    @State private var condition: String = "NM"
    @State private var buyPrice: String = ""
    @State private var salePrice: String = ""
    @State private var hasSalePrice: Bool = false
    @State private var purchaseDate: Date = Date()
    
    let conditions = ["NM", "LP", "MP", "HP", "DMG"]
    
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Date"){
                    DatePicker("Purchase Date", selection: $purchaseDate, displayedComponents: .date)
                }
                Section("Card Information") {
                    TextField("Card Name", text: $name)
                        .autocorrectionDisabled()
                        .autocapitalization(.none)
                    TextField("Card Number", text: $number)
                        .autocorrectionDisabled()
                        .autocapitalization(.none)
                }
                
                Section("Condition") {
                    Toggle("Graded", isOn: $graded)
                    
                    if !graded {
                        Picker("Condition", selection: $condition) {
                            ForEach(conditions, id: \.self) { cond in
                                Text(cond).tag(cond)
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
                            .frame(maxWidth: 100)
                    }
                    
                    Toggle("Has Sale Price", isOn: $hasSalePrice)
                    
                    if hasSalePrice {
                        HStack {
                            Text("Sale Price")
                            Spacer()
                            Text("$")
                                .foregroundColor(.secondary)
                            TextField("0.00", text: $salePrice)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                                .frame(maxWidth: 100)
                        }
                    }
                }
            }
            .navigationTitle("Add Card")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveCard()
                    }
                    .fontWeight(.semibold)
                }
            }
            .alert("Error", isPresented: $showingAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(alertMessage)
            }
        }
    }
    
    //MARK: Save the card
    private func saveCard() {
        // Validate required fields
        guard !name.trimmingCharacters(in: .whitespaces).isEmpty else {
            alertMessage = "Please enter a card name"
            showingAlert = true
            return
        }
        
        // Validate buy price
        guard let buyPriceValue = Double(buyPrice) else {
            alertMessage = "Please enter a valid buy price"
            showingAlert = true
            return
        }
        
        // Validate sale price if provided
        var salePriceValue: Double? = nil
        if hasSalePrice && !salePrice.isEmpty {
            guard let parsedSalePrice = Double(salePrice) else {
                alertMessage = "Please enter a valid sale price"
                showingAlert = true
                return
            }
            salePriceValue = parsedSalePrice
        }
        
        // Prepare card number (optional)
        let cardNumber = number.trimmingCharacters(in: .whitespaces).isEmpty ? nil : number.trimmingCharacters(in: .whitespaces)
        
        // Create the new card
        let newCard = Cards(
            name: name.trimmingCharacters(in: .whitespaces),
            number: cardNumber,
            graded: graded,
            condition: condition,
            buyPrice: buyPriceValue,
            salePrice: salePriceValue,
            purchaseDate: purchaseDate
        )
        
        // Insert into SwiftData
        modelContext.insert(newCard)
        
        // Explicitly save the context
        try? modelContext.save()
        
        // Dismiss and call completion
        dismiss()
        onSave()
    }
}

// MARK: - Add sealed View
struct AddSealedFormView: View {
    @Environment(\.dismiss) private var dismiss
    let modelContext: ModelContext
    var onSave: () -> Void
    
    @State private var name: String = ""
    @State private var expansion: String = ""
    @State private var buyPrice: String = ""
    @State private var salePrice: String = ""
    @State private var hasSalePrice: Bool = false
    @State private var purchaseDate: Date = Date()
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Date"){
                    DatePicker("Purchase Date", selection: $purchaseDate, displayedComponents: .date)
                }
                Section("Product information") {
                    TextField("Name", text: $name)
                        .autocorrectionDisabled()
                        .autocapitalization(.none)
                    TextField("Set", text: $expansion)
                        .autocorrectionDisabled()
                        .autocapitalization(.none)
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
                            .frame(maxWidth: 100)
                    }
                    
                    Toggle("Has Sale Price", isOn: $hasSalePrice)
                    
                    if hasSalePrice {
                        HStack {
                            Text("Sale Price")
                            Spacer()
                            Text("$")
                                .foregroundColor(.secondary)
                            TextField("0.00", text: $salePrice)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                                .frame(maxWidth: 100)
                        }
                    }
                }
            }
            .navigationTitle("Add Sealed")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveSealedProduct()
                    }
                    .fontWeight(.semibold)
                }
            }
            .alert("Error", isPresented: $showingAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(alertMessage)
            }
        }
    }
    
    //MARK: Save the sealed product
    private func saveSealedProduct() {
        // Validate required fields
        guard !name.trimmingCharacters(in: .whitespaces).isEmpty else {
            alertMessage = "Please enter a product name"
            showingAlert = true
            return
        }
        
        // Validate buy price
        guard let buyPriceValue = Double(buyPrice) else {
            alertMessage = "Please enter a valid buy price"
            showingAlert = true
            return
        }
        
        // Validate sale price if provided
        var salePriceValue: Double? = nil
        if hasSalePrice && !salePrice.isEmpty {
            guard let parsedSalePrice = Double(salePrice) else {
                alertMessage = "Please enter a valid sale price"
                showingAlert = true
                return
            }
            salePriceValue = parsedSalePrice
        }
        
        // Create the new sealed product
        let newSealedProduct = SealedProduct(
            name: name.trimmingCharacters(in: .whitespaces),
            expansion: expansion.trimmingCharacters(in: .whitespaces),
            buyPrice: buyPriceValue,
            salePrice: salePriceValue,
            purchaseDate: purchaseDate
        )
        
        // Insert into SwiftData
        modelContext.insert(newSealedProduct)
        
        // Explicitly save the context
        try? modelContext.save()
        
        // Dismiss and call completion
        dismiss()
        onSave()
    }
}


// MARK: - Add sealed View
struct AddMiscFormView: View {
    @Environment(\.dismiss) private var dismiss
    let modelContext: ModelContext
    var onSave: () -> Void
    
    @State private var itemDescription: String = ""
    @State private var cost: String = ""
    @State private var salePrice: String = ""
    @State private var purchaseDate: Date = Date()
    @State private var notes: String = ""
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
//    var itemDescription: String
//    var cost: Double
//    var purchaseDate: Date
//    var notes: String?
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Date"){
                    DatePicker("Purchase Date", selection: $purchaseDate, displayedComponents: .date)
                }
                Section("Misc supplies information") {
                    TextField("Expense", text: $itemDescription)
                        .autocorrectionDisabled()
                        .autocapitalization(.none)
                    TextField("Notes", text: $notes)
                        .autocorrectionDisabled()
                        .autocapitalization(.none)
                }
                Section("Pricing") {
                    HStack {
                        Text("Cost")
                        Spacer()
                        Text("$")
                            .foregroundColor(.secondary)
                        TextField("0.00", text: $cost)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(maxWidth: 100)
                    }
                }
            }
            .navigationTitle("Add misc expense")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveMiscExpense()
                    }
                    .fontWeight(.semibold)
                }
            }
            .alert("Error", isPresented: $showingAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(alertMessage)
            }
        }
    }
    
    //MARK: Save the misc expense
    private func saveMiscExpense() {
        // Validate required fields
        guard !itemDescription.trimmingCharacters(in: .whitespaces).isEmpty else {
            alertMessage = "Please enter a expense description"
            showingAlert = true
            return
        }
        
        // Validate buy price
        guard let buyPriceValue = Double(cost) else {
            alertMessage = "Please enter a valid cost"
            showingAlert = true
            return
        }
        
        // Create the new sealed product
        let newMiscExpense = MiscExpense(
            itemDescription: itemDescription.trimmingCharacters(in: .whitespaces),
            cost: buyPriceValue,
            purchaseDate: purchaseDate,
            notes: notes.trimmingCharacters(in: .whitespaces).isEmpty ? nil : notes.trimmingCharacters(in: .whitespaces)
        )
        
        // Insert into SwiftData
        modelContext.insert(newMiscExpense)
        
        // Explicitly save the context
        try? modelContext.save()
        
        // Dismiss and call completion
        dismiss()
        onSave()
    }
    
}


#Preview {
    AddCardView()
        .modelContainer(for: Cards.self, inMemory: true)
}
