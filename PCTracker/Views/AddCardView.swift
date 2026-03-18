//
//  TrackCardView.swift
//  PCTracker
//
//  Created by John on 2026-02-26.
//
import SwiftUI
import SwiftData
import PhotosUI

// MARK: - Add Card View
struct AddCardView: View {
    @Binding var selectedTab: Int
    
    @Environment(\.modelContext) private var modelContext
    @State private var showingAddCard = false
    @State private var showingAddProduct = false
    @State private var showingAddMisc = false

    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                VStack(alignment: .leading, spacing: 4) {
                    Text("Add Inventory")
                        .font(.manrope(24, weight: .bold))
                        .foregroundColor(.themePrimaryText)
                    Text("What are you adding today?")
                        .font(.manrope(14, weight: .regular))
                        .foregroundColor(.themeSecondaryText.opacity(0.6))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.bottom, 24)
                
                // Primary action - Cards (most common)
                Button(action: {
                    showingAddCard = true
                }) {
                    HStack(spacing: 16) {
                        Image(systemName: "greetingcard.fill")
                            .font(.system(size: 28, weight: .medium))
                            .foregroundColor(.themeGold)
                            .frame(width: 56, height: 56)
                            .background(Color.themeGold.opacity(0.12))
                            .cornerRadius(14)
                        
                        VStack(alignment: .leading, spacing: 5) {
                            Text("Card")
                                .font(.manrope(20, weight: .semiBold))
                                .foregroundColor(.themePrimaryText)
                            Text("Raw or graded single cards")
                                .font(.manrope(14, weight: .regular))
                                .foregroundColor(.themeSecondaryText.opacity(0.7))
                                .lineLimit(1)
                        }
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.themeSecondaryText.opacity(0.4))
                    }
                    .padding(20)
                    .background(Color.themeCardBackground)
                    .cornerRadius(16)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(
                                LinearGradient(
                                    colors: [Color.themeGold.opacity(0.35), Color.themeGold.opacity(0.08)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
                }
                .buttonStyle(.plain)
                .padding(.bottom, 12)
                
                // Secondary actions in a row
                HStack(spacing: 12) {
                    // Sealed Product
                    Button(action: {
                        showingAddProduct = true
                    }) {
                        VStack(alignment: .leading, spacing: 16) {
                            Image(systemName: "shippingbox.fill")
                                .font(.system(size: 26, weight: .medium))
                                .foregroundColor(.themeGold)
                                .frame(width: 52, height: 52)
                                .background(Color.themeGold.opacity(0.12))
                                .cornerRadius(13)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Sealed")
                                    .font(.manrope(18, weight: .semiBold))
                                    .foregroundColor(.themePrimaryText)
                                Text("Boxes, ETBs, packs")
                                    .font(.manrope(13, weight: .regular))
                                    .foregroundColor(.themeSecondaryText.opacity(0.7))
                                    .lineLimit(1)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(18)
                        .background(Color.themeCardBackground.opacity(0.7))
                        .cornerRadius(16)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.themeGold.opacity(0.12), lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                    
                    // Misc Expense
                    Button(action: {
                        showingAddMisc = true
                    }) {
                        VStack(alignment: .leading, spacing: 16) {
                            Image(systemName: "receipt.fill")
                                .font(.system(size: 26, weight: .medium))
                                .foregroundColor(.themeGold)
                                .frame(width: 52, height: 52)
                                .background(Color.themeGold.opacity(0.12))
                                .cornerRadius(13)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Expense")
                                    .font(.manrope(18, weight: .semiBold))
                                    .foregroundColor(.themePrimaryText)
                                Text("Fees, supplies, grading")
                                    .font(.manrope(13, weight: .regular))
                                    .foregroundColor(.themeSecondaryText.opacity(0.7))
                                    .lineLimit(1)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(18)
                        .background(Color.themeCardBackground.opacity(0.7))
                        .cornerRadius(16)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.themeGold.opacity(0.12), lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                }
                
                Spacer()
            }
            .padding(.horizontal)
            .padding(.top, 8)
            .background(Color.themeBackground)
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(.hidden, for: .navigationBar)
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
            .onChange(of: selectedTab) { _, _ in
                showingAddCard = false
                showingAddProduct = false
                showingAddMisc = false
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
    @State private var saleDate: Date = Date()
    
    let conditions = ["NM", "LP", "MP", "HP", "DMG"]
    
    @State private var photoData: Data?
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack {
                        Text("Card Name")
                            .foregroundColor(.themePrimaryText)
                        Spacer()
                        TextField("", text: $name)
                            .multilineTextAlignment(.trailing)
                            .autocorrectionDisabled()
                            .autocapitalization(.none)
                    }
                    .listRowBackground(Color.themeRowBackground)
                    HStack {
                        Text("Card Number")
                            .foregroundColor(.themePrimaryText)
                        Spacer()
                        TextField("", text: $number)
                            .multilineTextAlignment(.trailing)
                            .autocorrectionDisabled()
                            .autocapitalization(.none)
                    }
                    .listRowBackground(Color.themeRowBackground)
                } header: {
                    Text("Card Information")
                        .textCase(nil)
                        .foregroundColor(.themeSecondaryText)
                }
                
                Section {
                    Toggle("Graded", isOn: $graded)
                        .listRowBackground(Color.themeRowBackground)
                    
                    if !graded {
                        Picker("Condition", selection: $condition) {
                            ForEach(conditions, id: \.self) { cond in
                                Text(cond).tag(cond)
                            }
                        }
                        .pickerStyle(.segmented)
                        .listRowBackground(Color.themeRowBackground)
                    }
                } header: {
                    Text("Condition")
                        .textCase(nil)
                        .foregroundColor(.themeSecondaryText)
                }
                
                Section {
                    DatePicker("Purchase Date", selection: $purchaseDate, displayedComponents: .date)
                        .environment(\.colorScheme, .dark)
                        .listRowBackground(Color.themeRowBackground)
                } header: {
                    Text("Date")
                        .textCase(nil)
                        .foregroundColor(.themeSecondaryText)
                }
                
                Section {
                    HStack {
                        Text("Buy Price")
                        Spacer()
                        Text("$")
                            .foregroundColor(.themeSecondaryText)
                        TextField("0.00", text: $buyPrice)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(maxWidth: 100)
                    }
                    .listRowBackground(Color.themeRowBackground)
                    
                    Toggle("Has Sale Price", isOn: $hasSalePrice)
                        .listRowBackground(Color.themeRowBackground)
                    
                    if hasSalePrice {
                        HStack {
                            Text("Sale Price")
                            Spacer()
                            Text("$")
                                .foregroundColor(.themeSecondaryText)
                            TextField("0.00", text: $salePrice)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                                .frame(maxWidth: 100)
                        }
                        .listRowBackground(Color.themeRowBackground)
                        
                        DatePicker("Sale Date", selection: $saleDate, displayedComponents: .date)
                            .environment(\.colorScheme, .dark)
                            .listRowBackground(Color.themeRowBackground)
                    }
                } header: {
                    Text("Pricing")
                        .textCase(nil)
                        .foregroundColor(.themeSecondaryText)
                }
                
                PhotoPickerSection(photoData: $photoData)
            }
            .foregroundColor(.themePrimaryText)
            .scrollContentBackground(.hidden)
            .background(Color.themeBackground)
            .navigationTitle("Add Card")
            .navigationBarTitleDisplayMode(.inline)
            .tint(.themeGold)
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
            saleDate: (hasSalePrice && salePriceValue != nil) ? saleDate : nil,
            purchaseDate: purchaseDate,
            photoData: photoData
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
    @State private var saleDate: Date = Date()
    @State private var photoData: Data?
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack {
                        Text("Name")
                            .foregroundColor(.themePrimaryText)
                        Spacer()
                        TextField("", text: $name)
                            .multilineTextAlignment(.trailing)
                            .autocorrectionDisabled()
                            .autocapitalization(.none)
                    }
                    .listRowBackground(Color.themeRowBackground)
                    HStack {
                        Text("Set")
                            .foregroundColor(.themePrimaryText)
                        Spacer()
                        TextField("", text: $expansion)
                            .multilineTextAlignment(.trailing)
                            .autocorrectionDisabled()
                            .autocapitalization(.none)
                    }
                    .listRowBackground(Color.themeRowBackground)
                } header: {
                    Text("Product information")
                        .textCase(nil)
                        .foregroundColor(.themeSecondaryText)
                }
                
                Section {
                    DatePicker("Purchase Date", selection: $purchaseDate, displayedComponents: .date)
                        .environment(\.colorScheme, .dark)
                        .listRowBackground(Color.themeRowBackground)
                } header: {
                    Text("Date")
                        .textCase(nil)
                        .foregroundColor(.themeSecondaryText)
                }
                
                Section {
                    HStack {
                        Text("Buy Price")
                        Spacer()
                        Text("$")
                            .foregroundColor(.themeSecondaryText)
                        TextField("0.00", text: $buyPrice)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(maxWidth: 100)
                    }
                    .listRowBackground(Color.themeRowBackground)
                    
                    Toggle("Has Sale Price", isOn: $hasSalePrice)
                        .listRowBackground(Color.themeRowBackground)
                    
                    if hasSalePrice {
                        HStack {
                            Text("Sale Price")
                            Spacer()
                            Text("$")
                                .foregroundColor(.themeSecondaryText)
                            TextField("0.00", text: $salePrice)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                                .frame(maxWidth: 100)
                        }
                        .listRowBackground(Color.themeRowBackground)
                        
                        DatePicker("Sale Date", selection: $saleDate, displayedComponents: .date)
                            .environment(\.colorScheme, .dark)
                            .listRowBackground(Color.themeRowBackground)
                    }
                } header: {
                    Text("Pricing")
                        .textCase(nil)
                        .foregroundColor(.themeSecondaryText)
                }
                
                PhotoPickerSection(photoData: $photoData)
            }
            .foregroundColor(.themePrimaryText)
            .scrollContentBackground(.hidden)
            .background(Color.themeBackground)
            .navigationTitle("Add Sealed")
            .navigationBarTitleDisplayMode(.inline)
            .tint(.themeGold)
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
            saleDate: (hasSalePrice && salePriceValue != nil) ? saleDate : nil,
            purchaseDate: purchaseDate,
            photoData: photoData
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
    @State private var photoData: Data?
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack {
                        Text("Expense")
                            .foregroundColor(.themePrimaryText)
                        Spacer()
                        TextField("", text: $itemDescription)
                            .multilineTextAlignment(.trailing)
                            .autocorrectionDisabled()
                            .autocapitalization(.none)
                    }
                    .listRowBackground(Color.themeRowBackground)
                    HStack {
                        Text("Notes")
                            .foregroundColor(.themePrimaryText)
                        Spacer()
                        TextField("", text: $notes)
                            .multilineTextAlignment(.trailing)
                            .autocorrectionDisabled()
                            .autocapitalization(.none)
                    }
                    .listRowBackground(Color.themeRowBackground)
                } header: {
                    Text("Misc supplies information")
                        .textCase(nil)
                        .foregroundColor(.themeSecondaryText)
                }
                
                Section {
                    DatePicker("Purchase Date", selection: $purchaseDate, displayedComponents: .date)
                        .environment(\.colorScheme, .dark)
                        .listRowBackground(Color.themeRowBackground)
                } header: {
                    Text("Date")
                        .textCase(nil)
                        .foregroundColor(.themeSecondaryText)
                }
                
                Section {
                    HStack {
                        Text("Cost")
                        Spacer()
                        Text("$")
                            .foregroundColor(.themeSecondaryText)
                        TextField("0.00", text: $cost)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(maxWidth: 100)
                    }
                    .listRowBackground(Color.themeRowBackground)
                } header: {
                    Text("Pricing")
                        .textCase(nil)
                        .foregroundColor(.themeSecondaryText)
                }
                
                PhotoPickerSection(photoData: $photoData)
            }
            .foregroundColor(.themePrimaryText)
            .scrollContentBackground(.hidden)
            .background(Color.themeBackground)
            .navigationTitle("Add misc expense")
            .navigationBarTitleDisplayMode(.inline)
            .tint(.themeGold)
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
        
        // Create the new misc expense
        let newMiscExpense = MiscExpense(
            itemDescription: itemDescription.trimmingCharacters(in: .whitespaces),
            cost: buyPriceValue,
            purchaseDate: purchaseDate,
            notes: notes.trimmingCharacters(in: .whitespaces).isEmpty ? nil : notes.trimmingCharacters(in: .whitespaces),
            photoData: photoData
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
    AddCardView(selectedTab: .constant(2))
        .modelContainer(for: Cards.self, inMemory: true)
}
