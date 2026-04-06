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
    @AppStorage("currencyCode") private var currencyCode: String = "CAD"
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
    @AppStorage("currencyCode") private var currencyCode: String = "CAD"
    
    @State private var name: String = ""
    @State private var number: String = ""
    @State private var cardSet: String = ""
    @State private var graded: Bool = false
    @State private var condition: String = "NM"
    @State private var buyPrice: String = ""
    @State private var salePrice: String = ""
    @State private var hasSalePrice: Bool = false
    @State private var purchaseDate: Date = Date()
    @State private var saleDate: Date = Date()
    
    let conditions = ["NM", "LP", "MP", "HP", "DMG"]
    
    @State private var photoData: Data?
    @State private var showingCamera = false
    @State private var showingLibraryPicker = false
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var showingSearch = false
    @State private var marketPrice: Double?
    @State private var isLoadingImage = false
    
    var body: some View {
        NavigationStack {
            Form {
                // Search button at the top
                Section {
                    Button {
                        showingSearch = true
                    } label: {
                        HStack {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(.themeGold)
                            Text("Search Card")
                                .font(.manrope(16, weight: .semiBold))
                                .foregroundColor(.themeGold)
                            Spacer()
                            Text("Auto-fill card info")
                                .font(.manrope(13, weight: .regular))
                                .foregroundColor(.themeSecondaryText.opacity(0.6))
                        }
                    }
                    .listRowBackground(Color.themeGold.opacity(0.08))
                }
                
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
                    HStack {
                        Text("Card Set")
                            .foregroundColor(.themePrimaryText)
                        Spacer()
                        TextField("Optional", text: $cardSet)
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
                        Text(CurrencyFormatter.symbol(for: currencyCode))
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
                            Text(CurrencyFormatter.symbol(for: currencyCode))
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
                
                PhotoPickerSection(photoData: $photoData, onLibraryRequested: { showingLibraryPicker = true }, onCameraRequested: { showingCamera = true })
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
            .fullScreenCover(isPresented: $showingCamera) {
                CameraView { data in photoData = data }
                    .ignoresSafeArea()
            }
            .sheet(isPresented: $showingSearch) {
                CardSearchView { result in
                    applySearchResult(result)
                }
            }
            .photosPicker(isPresented: $showingLibraryPicker, selection: $selectedPhotoItem, matching: .images, photoLibrary: .shared())
            .onChange(of: selectedPhotoItem) { _, newItem in
                guard let newItem else { return }
                Task {
                    if let data = try? await newItem.loadTransferable(type: Data.self) {
                        if let uiImage = UIImage(data: data), let compressed = uiImage.jpegData(compressionQuality: 0.7) {
                            await MainActor.run { photoData = compressed }
                        } else {
                            await MainActor.run { photoData = data }
                        }
                    }
                    await MainActor.run { selectedPhotoItem = nil }
                }
            }
        }
    }
    
    // MARK: - Apply Search Result
    private func applySearchResult(_ result: CardSearchResult) {
        name = result.name
        number = result.number
        cardSet = result.setName
        marketPrice = result.marketPrice
        
        // Download card image from API
        if let urlString = result.imageURL, let url = URL(string: urlString) {
            isLoadingImage = true
            Task {
                if let (data, _) = try? await URLSession.shared.data(from: url) {
                    await MainActor.run {
                        photoData = data
                        isLoadingImage = false
                    }
                } else {
                    await MainActor.run {
                        isLoadingImage = false
                    }
                }
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
        let cardSetValue = cardSet.trimmingCharacters(in: .whitespaces).isEmpty ? nil : cardSet.trimmingCharacters(in: .whitespaces)
        
        // Convert prices to storage currency (CAD) if user is entering in USD
        let storedBuyPrice = CurrencyFormatter.toStorageAmount(buyPriceValue, fromCode: currencyCode)
        let storedSalePrice = salePriceValue.map { CurrencyFormatter.toStorageAmount($0, fromCode: currencyCode) }
        
        // Create the new card
        let newCard = Cards(
            name: name.trimmingCharacters(in: .whitespaces),
            number: cardNumber,
            cardSet: cardSetValue,
            graded: graded,
            condition: condition,
            buyPrice: storedBuyPrice,
            salePrice: storedSalePrice,
            saleDate: (hasSalePrice && storedSalePrice != nil) ? saleDate : nil,
            purchaseDate: purchaseDate,
            photoData: photoData,
            marketPrice: marketPrice,
            marketPriceDate: marketPrice != nil ? Date() : nil
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
    @AppStorage("currencyCode") private var currencyCode: String = "CAD"
    
    @State private var name: String = ""
    @State private var expansion: String = ""
    @State private var buyPrice: String = ""
    @State private var salePrice: String = ""
    @State private var hasSalePrice: Bool = false
    @State private var purchaseDate: Date = Date()
    @State private var saleDate: Date = Date()
    @State private var photoData: Data?
    @State private var showingCamera = false
    @State private var showingLibraryPicker = false
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var showingSetSearch = false
    @State private var isLoadingImage = false
    
    var body: some View {
        NavigationStack {
            Form {
                // Search button at the top
                Section {
                    Button {
                        showingSetSearch = true
                    } label: {
                        HStack {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(.themeGold)
                            Text("Search Set")
                                .font(.manrope(16, weight: .semiBold))
                                .foregroundColor(.themeGold)
                            Spacer()
                            Text("Auto-fill set info")
                                .font(.manrope(13, weight: .regular))
                                .foregroundColor(.themeSecondaryText.opacity(0.6))
                        }
                    }
                    .listRowBackground(Color.themeGold.opacity(0.08))
                }
                
                Section {
                    HStack {
                        Text("Name")
                            .foregroundColor(.themePrimaryText)
                        Spacer()
                        TextField("e.g. Booster Box", text: $name)
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
                        Text(CurrencyFormatter.symbol(for: currencyCode))
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
                            Text(CurrencyFormatter.symbol(for: currencyCode))
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
                
                PhotoPickerSection(photoData: $photoData, onLibraryRequested: { showingLibraryPicker = true }, onCameraRequested: { showingCamera = true })
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
            .fullScreenCover(isPresented: $showingCamera) {
                CameraView { data in photoData = data }
                    .ignoresSafeArea()
            }
            .sheet(isPresented: $showingSetSearch) {
                SetSearchView { result in
                    applySetResult(result)
                }
            }
            .photosPicker(isPresented: $showingLibraryPicker, selection: $selectedPhotoItem, matching: .images, photoLibrary: .shared())
            .onChange(of: selectedPhotoItem) { _, newItem in
                guard let newItem else { return }
                Task {
                    if let data = try? await newItem.loadTransferable(type: Data.self) {
                        if let uiImage = UIImage(data: data), let compressed = uiImage.jpegData(compressionQuality: 0.7) {
                            await MainActor.run { photoData = compressed }
                        } else {
                            await MainActor.run { photoData = data }
                        }
                    }
                    await MainActor.run { selectedPhotoItem = nil }
                }
            }
        }
    }
    
    // MARK: - Apply Set Search Result
    private func applySetResult(_ result: SetSearchResult) {
        expansion = result.name
        
        // Download the set logo as the photo
        if let urlString = result.logoURL, let url = URL(string: urlString) {
            isLoadingImage = true
            Task {
                if let (data, _) = try? await URLSession.shared.data(from: url) {
                    await MainActor.run {
                        photoData = data
                        isLoadingImage = false
                    }
                } else {
                    await MainActor.run {
                        isLoadingImage = false
                    }
                }
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
        
        // Convert prices to storage currency (CAD)
        let storedBuyPrice = CurrencyFormatter.toStorageAmount(buyPriceValue, fromCode: currencyCode)
        let storedSalePrice = salePriceValue.map { CurrencyFormatter.toStorageAmount($0, fromCode: currencyCode) }
        
        // Create the new sealed product
        let newSealedProduct = SealedProduct(
            name: name.trimmingCharacters(in: .whitespaces),
            expansion: expansion.trimmingCharacters(in: .whitespaces),
            buyPrice: storedBuyPrice,
            salePrice: storedSalePrice,
            saleDate: (hasSalePrice && storedSalePrice != nil) ? saleDate : nil,
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
    @AppStorage("currencyCode") private var currencyCode: String = "CAD"
    
    @State private var itemDescription: String = ""
    @State private var cost: String = ""
    @State private var salePrice: String = ""
    @State private var purchaseDate: Date = Date()
    @State private var notes: String = ""
    @State private var photoData: Data?
    @State private var showingCamera = false
    @State private var showingLibraryPicker = false
    @State private var selectedPhotoItem: PhotosPickerItem?
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
                        Text(CurrencyFormatter.symbol(for: currencyCode))
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
                
                PhotoPickerSection(photoData: $photoData, onLibraryRequested: { showingLibraryPicker = true }, onCameraRequested: { showingCamera = true })
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
            .fullScreenCover(isPresented: $showingCamera) {
                CameraView { data in photoData = data }
                    .ignoresSafeArea()
            }
            .photosPicker(isPresented: $showingLibraryPicker, selection: $selectedPhotoItem, matching: .images, photoLibrary: .shared())
            .onChange(of: selectedPhotoItem) { _, newItem in
                guard let newItem else { return }
                Task {
                    if let data = try? await newItem.loadTransferable(type: Data.self) {
                        if let uiImage = UIImage(data: data), let compressed = uiImage.jpegData(compressionQuality: 0.7) {
                            await MainActor.run { photoData = compressed }
                        } else {
                            await MainActor.run { photoData = data }
                        }
                    }
                    await MainActor.run { selectedPhotoItem = nil }
                }
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
        
        // Convert to storage currency (CAD)
        let storedCost = CurrencyFormatter.toStorageAmount(buyPriceValue, fromCode: currencyCode)
        
        // Create the new misc expense
        let newMiscExpense = MiscExpense(
            itemDescription: itemDescription.trimmingCharacters(in: .whitespaces),
            cost: storedCost,
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


// MARK: - Card Search View

struct CardSearchView: View {
    @Environment(\.dismiss) private var dismiss
    
    let onSelect: (CardSearchResult) -> Void
    
    @State private var nameText = ""
    @State private var setText = ""
    @State private var numberText = ""
    @State private var showFilters = false
    @State private var results: [CardSearchResult] = []
    @State private var isSearching = false
    @State private var hasSearched = false
    @State private var searchTask: Task<Void, Never>?
    
    private var hasInput: Bool {
        nameText.trimmingCharacters(in: .whitespaces).count >= 3
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.themeBackground.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    VStack(spacing: 8) {
                        HStack(spacing: 10) {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(.themeSecondaryText)
                            
                            TextField("Card name...", text: $nameText)
                                .font(.manrope(16, weight: .medium))
                                .autocorrectionDisabled()
                                .textInputAutocapitalization(.never)
                                .submitLabel(.search)
                                .onSubmit { performSearch() }
                            
                            if !nameText.isEmpty {
                                Button {
                                    nameText = ""
                                    results = []
                                    hasSearched = false
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.themeSecondaryText)
                                }
                            }
                            
                            Button {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    showFilters.toggle()
                                }
                            } label: {
                                Image(systemName: showFilters ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
                                    .foregroundColor(showFilters || !setText.isEmpty || !numberText.isEmpty ? .themeGold : .themeSecondaryText)
                                    .font(.system(size: 20))
                            }
                        }
                        .padding(12)
                        .background(Color.themeRowBackground)
                        .cornerRadius(12)
                        
                        if showFilters {
                            HStack(spacing: 8) {
                                HStack(spacing: 6) {
                                    Text("Set")
                                        .font(.manrope(13, weight: .medium))
                                        .foregroundColor(.themeSecondaryText)
                                    TextField("e.g. Obsidian Flames", text: $setText)
                                        .font(.manrope(14, weight: .medium))
                                        .autocorrectionDisabled()
                                        .textInputAutocapitalization(.never)
                                        .submitLabel(.search)
                                        .onSubmit { performSearch() }
                                }
                                .padding(10)
                                .background(Color.themeRowBackground)
                                .cornerRadius(10)
                                
                                HStack(spacing: 6) {
                                    Text("#")
                                        .font(.manrope(13, weight: .medium))
                                        .foregroundColor(.themeSecondaryText)
                                    TextField("Number", text: $numberText)
                                        .font(.manrope(14, weight: .medium))
                                        .autocorrectionDisabled()
                                        .textInputAutocapitalization(.never)
                                        .submitLabel(.search)
                                        .onSubmit { performSearch() }
                                }
                                .padding(10)
                                .background(Color.themeRowBackground)
                                .cornerRadius(10)
                                .frame(width: 110)
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 8)
                    
                    if isSearching {
                        Spacer()
                        ProgressView()
                            .tint(.themeGold)
                            .scaleEffect(1.2)
                        Text("Searching...")
                            .font(.manrope(14, weight: .medium))
                            .foregroundColor(.themeSecondaryText)
                            .padding(.top, 8)
                        Spacer()
                    } else if results.isEmpty && hasSearched {
                        Spacer()
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 40))
                            .foregroundColor(.themeSecondaryText.opacity(0.3))
                        Text("No cards found")
                            .font(.manrope(16, weight: .medium))
                            .foregroundColor(.themeSecondaryText)
                            .padding(.top, 8)
                        Text("Try a different name or spelling")
                            .font(.manrope(13, weight: .regular))
                            .foregroundColor(.themeSecondaryText.opacity(0.6))
                        Spacer()
                    } else if results.isEmpty {
                        Spacer()
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 40))
                            .foregroundColor(.themeSecondaryText.opacity(0.3))
                        Text("Search for a Pokemon card")
                            .font(.manrope(16, weight: .medium))
                            .foregroundColor(.themeSecondaryText)
                            .padding(.top, 8)
                        Text("English or Japanese (e.g. \"Charizard\" or \"リザードン\")")
                            .font(.manrope(13, weight: .regular))
                            .foregroundColor(.themeSecondaryText.opacity(0.6))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                        Spacer()
                    } else {
                        List {
                            ForEach(results) { result in
                                Button {
                                    onSelect(result)
                                    dismiss()
                                } label: {
                                    SearchResultRow(result: result)
                                }
                                .listRowBackground(Color.themeRowBackground)
                            }
                        }
                        .scrollContentBackground(.hidden)
                        .background(Color.themeBackground)
                    }
                }
            }
            .navigationTitle("Search Cards")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .onChange(of: nameText) { _, _ in debounceSearch() }
            .onChange(of: setText) { _, _ in debounceSearch() }
            .onChange(of: numberText) { _, _ in debounceSearch() }
        }
    }
    
    private func debounceSearch() {
        searchTask?.cancel()
        guard hasInput else {
            results = []
            hasSearched = false
            return
        }
        searchTask = Task {
            try? await Task.sleep(for: .milliseconds(500))
            guard !Task.isCancelled else { return }
            performSearch()
        }
    }
    
    private func performSearch() {
        let name = nameText.trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty else { return }
        
        let setFilter = setText.trimmingCharacters(in: .whitespaces).isEmpty ? nil : setText.trimmingCharacters(in: .whitespaces)
        let numberFilter = numberText.trimmingCharacters(in: .whitespaces).isEmpty ? nil : numberText.trimmingCharacters(in: .whitespaces)
        
        isSearching = true
        Task {
            do {
                let searchResults = try await PokemonTCGService.searchCards(
                    name: name,
                    set: setFilter,
                    number: numberFilter
                )
                await MainActor.run {
                    results = searchResults
                    isSearching = false
                    hasSearched = true
                }
            } catch {
                await MainActor.run {
                    results = []
                    isSearching = false
                    hasSearched = true
                }
            }
        }
    }
}

// MARK: - Set Search View

struct SetSearchView: View {
    @Environment(\.dismiss) private var dismiss
    
    let onSelect: (SetSearchResult) -> Void
    
    @State private var searchText = ""
    @State private var results: [SetSearchResult] = []
    @State private var isSearching = false
    @State private var hasSearched = false
    @State private var searchTask: Task<Void, Never>?
    
    private var hasInput: Bool {
        searchText.trimmingCharacters(in: .whitespaces).count >= 2
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.themeBackground.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    HStack(spacing: 10) {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.themeSecondaryText)
                        
                        TextField("Set name...", text: $searchText)
                            .font(.manrope(16, weight: .medium))
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.never)
                            .submitLabel(.search)
                            .onSubmit { performSearch() }
                        
                        if !searchText.isEmpty {
                            Button {
                                searchText = ""
                                results = []
                                hasSearched = false
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.themeSecondaryText)
                            }
                        }
                    }
                    .padding(12)
                    .background(Color.themeRowBackground)
                    .cornerRadius(12)
                    .padding(.horizontal)
                    .padding(.top, 8)
                    
                    if isSearching {
                        Spacer()
                        ProgressView()
                            .tint(.themeGold)
                            .scaleEffect(1.2)
                        Text("Searching...")
                            .font(.manrope(14, weight: .medium))
                            .foregroundColor(.themeSecondaryText)
                            .padding(.top, 8)
                        Spacer()
                    } else if results.isEmpty && hasSearched {
                        Spacer()
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 40))
                            .foregroundColor(.themeSecondaryText.opacity(0.3))
                        Text("No sets found")
                            .font(.manrope(16, weight: .medium))
                            .foregroundColor(.themeSecondaryText)
                            .padding(.top, 8)
                        Text("Try a different name or spelling")
                            .font(.manrope(13, weight: .regular))
                            .foregroundColor(.themeSecondaryText.opacity(0.6))
                        Spacer()
                    } else if results.isEmpty {
                        Spacer()
                        Image(systemName: "shippingbox")
                            .font(.system(size: 40))
                            .foregroundColor(.themeSecondaryText.opacity(0.3))
                        Text("Search for a Pokemon set")
                            .font(.manrope(16, weight: .medium))
                            .foregroundColor(.themeSecondaryText)
                            .padding(.top, 8)
                        Text("e.g. \"Obsidian Flames\" or \"Prismatic\"")
                            .font(.manrope(13, weight: .regular))
                            .foregroundColor(.themeSecondaryText.opacity(0.6))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                        Spacer()
                    } else {
                        List {
                            ForEach(results) { result in
                                Button {
                                    onSelect(result)
                                    dismiss()
                                } label: {
                                    SetSearchResultRow(result: result)
                                }
                                .listRowBackground(Color.themeRowBackground)
                            }
                        }
                        .scrollContentBackground(.hidden)
                        .background(Color.themeBackground)
                    }
                }
            }
            .navigationTitle("Search Sets")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .onChange(of: searchText) { _, _ in debounceSearch() }
        }
    }
    
    private func debounceSearch() {
        searchTask?.cancel()
        guard hasInput else {
            results = []
            hasSearched = false
            return
        }
        searchTask = Task {
            try? await Task.sleep(for: .milliseconds(500))
            guard !Task.isCancelled else { return }
            performSearch()
        }
    }
    
    private func performSearch() {
        let query = searchText.trimmingCharacters(in: .whitespaces)
        guard !query.isEmpty else { return }
        
        isSearching = true
        Task {
            do {
                let searchResults = try await PokemonTCGService.searchSets(query: query)
                await MainActor.run {
                    results = searchResults
                    isSearching = false
                    hasSearched = true
                }
            } catch {
                await MainActor.run {
                    results = []
                    isSearching = false
                    hasSearched = true
                }
            }
        }
    }
}

// MARK: - Set Search Result Row

struct SetSearchResultRow: View {
    let result: SetSearchResult
    
    var body: some View {
        HStack(spacing: 12) {
            if let urlString = result.logoURL, let url = URL(string: urlString) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 60, height: 40)
                    case .failure:
                        setPlaceholder
                    default:
                        ProgressView()
                            .frame(width: 60, height: 40)
                    }
                }
            } else {
                setPlaceholder
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(result.name)
                    .font(.manrope(.headline, weight: .semiBold))
                    .foregroundColor(.themePrimaryText)
                    .lineLimit(1)
                
                HStack(spacing: 6) {
                    if !result.series.isEmpty {
                        Text(result.series)
                            .font(.manrope(.caption, weight: .medium))
                            .foregroundColor(.themeSecondaryText)
                            .lineLimit(1)
                    }
                    
                    if let totalCards = result.totalCards {
                        Text("·")
                            .foregroundColor(.themeSecondaryText.opacity(0.5))
                        Text("\(totalCards) cards")
                            .font(.manrope(.caption))
                            .foregroundColor(.themeSecondaryText)
                    }
                }
                
                if let releaseDate = result.releaseDate {
                    Text(releaseDate)
                        .font(.manrope(.caption2))
                        .foregroundColor(.themeSecondaryText.opacity(0.6))
                }
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
    
    private var setPlaceholder: some View {
        RoundedRectangle(cornerRadius: 4)
            .fill(Color.themeSecondaryText.opacity(0.2))
            .frame(width: 60, height: 40)
            .overlay(
                Image(systemName: "shippingbox")
                    .foregroundColor(.themeSecondaryText.opacity(0.5))
            )
    }
}

// MARK: - Search Result Row

struct SearchResultRow: View {
    let result: CardSearchResult
    @AppStorage("currencyCode") private var currencyCode: String = "CAD"
    
    var body: some View {
        HStack(spacing: 12) {
            if let urlString = result.imageURL, let url = URL(string: urlString) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 50, height: 70)
                            .cornerRadius(4)
                    case .failure:
                        cardPlaceholder
                    default:
                        ProgressView()
                            .frame(width: 50, height: 70)
                    }
                }
            } else {
                cardPlaceholder
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(result.name)
                    .font(.manrope(.headline, weight: .semiBold))
                    .foregroundColor(.themePrimaryText)
                    .lineLimit(1)
                
                HStack(spacing: 6) {
                    Text("#\(result.number)")
                        .font(.manrope(.caption, weight: .medium))
                        .foregroundColor(.themeSecondaryText)
                    
                    if !result.setName.isEmpty {
                        Text(result.setName)
                            .font(.manrope(.caption))
                            .foregroundColor(.themeSecondaryText)
                            .lineLimit(1)
                    }
                }
            }
            
            Spacer()
            
            if let price = result.marketPrice {
                Text(CurrencyFormatter.convertedString(price, code: currencyCode))
                    .font(.manrope(16, weight: .bold))
                    .foregroundColor(.themeGold)
            }
        }
        .padding(.vertical, 4)
    }
    
    private var cardPlaceholder: some View {
        RoundedRectangle(cornerRadius: 4)
            .fill(Color.themeSecondaryText.opacity(0.2))
            .frame(width: 50, height: 70)
            .overlay(
                Image(systemName: "lanyardcard")
                    .foregroundColor(.themeSecondaryText.opacity(0.5))
            )
    }
}

#Preview {
    AddCardView(selectedTab: .constant(2))
        .modelContainer(previewContainer)
}
