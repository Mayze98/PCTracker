//
//  TrackCardView.swift
//  PCTracker
//
//  Created by John on 2026-02-26.
//
import SwiftUI
import SwiftData
import PhotosUI
import Vision

// MARK: - Add Card View
struct AddCardView: View {
    @Binding var selectedTab: Int
    
    @Environment(\.modelContext) private var modelContext
    @AppStorage("currencyCode") private var currencyCode: String = "CAD"
    @State private var showingAddCard = false
    @State private var showingAddProduct = false
    @State private var showingAddMisc = false
    @State private var showingScanCard = false

    
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
                
                // Scan Card button
                Button(action: {
                    showingScanCard = true
                }) {
                    HStack(spacing: 16) {
                        Image(systemName: "camera.viewfinder")
                            .font(.system(size: 26, weight: .medium))
                            .foregroundColor(.themeGold)
                            .frame(width: 56, height: 56)
                            .background(Color.themeGold.opacity(0.12))
                            .cornerRadius(14)
                        
                        VStack(alignment: .leading, spacing: 5) {
                            Text("Scan Card")
                                .font(.manrope(20, weight: .semiBold))
                                .foregroundColor(.themePrimaryText)
                            Text("Snap a photo to identify")
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
                    .background(Color.themeCardBackground.opacity(0.7))
                    .cornerRadius(16)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.themeGold.opacity(0.12), lineWidth: 1)
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
            .sheet(isPresented: $showingScanCard) {
                ScanCardView(modelContext: modelContext, onSave: {
                    showingScanCard = false
                })
            }
            .onChange(of: selectedTab) { _, _ in
                showingAddCard = false
                showingAddProduct = false
                showingAddMisc = false
                showingScanCard = false
            }
        }
    }
}

// MARK: - Queued Card Model
struct QueuedCard: Identifiable {
    let id = UUID()
    var name: String
    var number: String?
    var cardSet: String?
    var graded: Bool
    var gradeLevel: Int?
    var condition: String
    var buyPrice: Double        // In display currency
    var salePrice: Double?      // In display currency
    var hasSalePrice: Bool
    var saleDate: Date?
    var marketPrice: Double?    // In CAD (from search)
    var purchaseDate: Date
    var photoData: Data?
    var imageURL: String?       // For display in queue
}

// MARK: - Add Card Form View
struct AddCardFormView: View {
    @Environment(\.dismiss) private var dismiss
    let modelContext: ModelContext
    var onSave: () -> Void
    var initialResult: CardSearchResult? = nil
    var initialPhotoData: Data? = nil
    @AppStorage("currencyCode") private var currencyCode: String = "CAD"
    
    @State private var name: String = ""
    @State private var number: String = ""
    @State private var cardSet: String = ""
    @State private var graded: Bool = false
    @State private var gradeLevel: Int = 10
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
    
    // Queue & percentage pricing state
    @State private var cardQueue: [QueuedCard] = []
    @State private var selectedPercentage: Int? = nil
    @State private var customPercentage: String = ""
    @State private var showingDiscardAlert = false
    @State private var referenceBuyPrice: Double? = nil  // base price for percentage calc when no market price
    
    private let percentagePresets = [60, 70, 80, 90]
    
    /// Whether the current form has enough data to be queued/saved
    private var currentFormIsValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty && !buyPrice.isEmpty && Double(buyPrice) != nil
    }
    
    /// Total cards that will be saved (queue + current form if valid)
    private var totalSaveCount: Int {
        cardQueue.count + (currentFormIsValid ? 1 : 0)
    }
    
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
                    
                    if graded {
                        Picker("PSA Grade", selection: $gradeLevel) {
                            ForEach((1...10).reversed(), id: \.self) { grade in
                                Text("PSA \(grade)").tag(grade)
                            }
                        }
                        .listRowBackground(Color.themeRowBackground)
                    } else {
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
                
                // MARK: Pricing Section
                Section {
                    // Market price reference (when available from search)
                    if let mp = marketPrice {
                        HStack {
                            Text("Market Price")
                                .foregroundColor(.themeSecondaryText)
                            Spacer()
                            Text(CurrencyFormatter.convertedString(mp, code: currencyCode))
                                .foregroundColor(.themeGold)
                                .font(.manrope(16, weight: .bold))
                        }
                        .listRowBackground(Color.themeRowBackground)
                    }
                    
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
                    
                    // Percentage pills — always visible
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Buy at percentage")
                            .font(.manrope(13, weight: .medium))
                            .foregroundColor(.themeSecondaryText)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(percentagePresets, id: \.self) { pct in
                                    Button {
                                        applyPercentage(pct)
                                    } label: {
                                        Text("\(pct)%")
                                            .font(.manrope(14, weight: .semiBold))
                                            .padding(.horizontal, 14)
                                            .padding(.vertical, 8)
                                            .background(selectedPercentage == pct ? Color.themeGold : Color.themeGold.opacity(0.12))
                                            .foregroundColor(selectedPercentage == pct ? .black : .themeGold)
                                            .cornerRadius(20)
                                    }
                                    .buttonStyle(.plain)
                                }
                                
                                // Custom percentage
                                Button {
                                    selectedPercentage = -1 // sentinel for custom
                                } label: {
                                    if selectedPercentage == -1 {
                                        HStack(spacing: 4) {
                                            TextField("", text: $customPercentage)
                                                .keyboardType(.numberPad)
                                                .frame(width: 36)
                                                .multilineTextAlignment(.center)
                                                .font(.manrope(14, weight: .semiBold))
                                                .foregroundColor(.black)
                                                .onChange(of: customPercentage) { _, newVal in
                                                    if let pctVal = Double(newVal) {
                                                        applyCustomPercentage(pctVal)
                                                    }
                                                }
                                            Text("%")
                                                .font(.manrope(14, weight: .semiBold))
                                                .foregroundColor(.black)
                                        }
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 8)
                                        .background(Color.themeGold)
                                        .cornerRadius(20)
                                    } else {
                                        Text("Custom")
                                            .font(.manrope(14, weight: .semiBold))
                                            .padding(.horizontal, 14)
                                            .padding(.vertical, 8)
                                            .background(Color.themeGold.opacity(0.12))
                                            .foregroundColor(.themeGold)
                                            .cornerRadius(20)
                                    }
                                }
                                .buttonStyle(.plain)
                            }
                        }
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
                
                // MARK: Add to Queue Button
                Section {
                    Button {
                        addToQueue()
                    } label: {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                            Text("Add to Queue")
                        }
                        .frame(maxWidth: .infinity)
                        .font(.manrope(16, weight: .semiBold))
                        .foregroundColor(currentFormIsValid ? .themeGold : .themeSecondaryText.opacity(0.4))
                    }
                    .disabled(!currentFormIsValid)
                    .listRowBackground(Color.themeGold.opacity(currentFormIsValid ? 0.12 : 0.05))
                }
                
                // MARK: Queue Display
                if !cardQueue.isEmpty {
                    Section {
                        ForEach(cardQueue) { card in
                            HStack(spacing: 12) {
                                VStack(alignment: .leading, spacing: 2) {
                                    HStack(spacing: 6) {
                                        Text(card.name)
                                            .font(.manrope(15, weight: .semiBold))
                                            .foregroundColor(.themePrimaryText)
                                            .lineLimit(1)
                                        if let num = card.number {
                                            Text("#\(num)")
                                                .font(.manrope(13, weight: .medium))
                                                .foregroundColor(.themeSecondaryText)
                                        }
                                    }
                                    HStack(spacing: 4) {
                                        if let set = card.cardSet, !set.isEmpty {
                                            Text(set)
                                                .font(.manrope(13, weight: .regular))
                                                .foregroundColor(.themeSecondaryText)
                                            Text("·")
                                                .foregroundColor(.themeSecondaryText.opacity(0.5))
                                        }
                                        Text(CurrencyFormatter.string(card.buyPrice, code: currencyCode))
                                            .font(.manrope(13, weight: .semiBold))
                                            .foregroundColor(.themeGold)
                                    }
                                }
                                
                                Spacer()
                                
                                Button {
                                    cardQueue.removeAll { $0.id == card.id }
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.themeSecondaryText.opacity(0.5))
                                        .font(.system(size: 20))
                                }
                                .buttonStyle(.plain)
                            }
                            .listRowBackground(Color.themeRowBackground)
                        }
                    } header: {
                        Text("Queue (\(cardQueue.count) \(cardQueue.count == 1 ? "card" : "cards"))")
                            .textCase(nil)
                            .foregroundColor(.themeSecondaryText)
                    }
                }
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
                        if cardQueue.isEmpty {
                            dismiss()
                        } else {
                            showingDiscardAlert = true
                        }
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button(cardQueue.isEmpty ? "Save" : "Save All (\(totalSaveCount))") {
                        saveAll()
                    }
                    .fontWeight(.semibold)
                    .disabled(cardQueue.isEmpty && !currentFormIsValid)
                }
            }
            .alert("Error", isPresented: $showingAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(alertMessage)
            }
            .alert("Discard Queue?", isPresented: $showingDiscardAlert) {
                Button("Discard", role: .destructive) { dismiss() }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("You have \(cardQueue.count) card\(cardQueue.count == 1 ? "" : "s") in the queue that haven't been saved.")
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
            .onAppear {
                if let result = initialResult {
                    applySearchResult(result)
                }
                if let data = initialPhotoData, photoData == nil {
                    photoData = data
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
        selectedPercentage = nil
        customPercentage = ""
        
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
    
    // MARK: - Percentage Helpers
    
    /// Returns the base price for percentage calculations.
    /// Uses market price (converted to display currency) if available, otherwise the current buy price.
    private func percentageBasePrice() -> Double? {
        if let mp = marketPrice {
            return CurrencyFormatter.displayAmount(mp, displayCode: currencyCode)
        }
        // No market price — use the current buy price as the base (capture it before modifying)
        if let ref = referenceBuyPrice {
            return ref
        }
        if let current = Double(buyPrice), current > 0 {
            return current
        }
        return nil
    }
    
    private func applyPercentage(_ pct: Int) {
        // Capture the current buy price as reference before first percentage tap (no market price case)
        if marketPrice == nil && referenceBuyPrice == nil {
            if let current = Double(buyPrice), current > 0 {
                referenceBuyPrice = current
            }
        }
        
        selectedPercentage = pct
        customPercentage = ""
        
        if let base = percentageBasePrice() {
            buyPrice = String(format: "%.2f", base * Double(pct) / 100.0)
        }
    }
    
    private func applyCustomPercentage(_ pctVal: Double) {
        // Capture the current buy price as reference before first percentage tap (no market price case)
        if marketPrice == nil && referenceBuyPrice == nil {
            if let current = Double(buyPrice), current > 0 {
                referenceBuyPrice = current
            }
        }
        
        if let base = percentageBasePrice() {
            buyPrice = String(format: "%.2f", base * pctVal / 100.0)
        }
    }
    
    // MARK: - Add to Queue
    private func addToQueue() {
        guard !name.trimmingCharacters(in: .whitespaces).isEmpty else {
            alertMessage = "Please enter a card name"
            showingAlert = true
            return
        }
        
        guard let buyPriceValue = Double(buyPrice) else {
            alertMessage = "Please enter a valid buy price"
            showingAlert = true
            return
        }
        
        var salePriceValue: Double? = nil
        if hasSalePrice && !salePrice.isEmpty {
            guard let parsed = Double(salePrice) else {
                alertMessage = "Please enter a valid sale price"
                showingAlert = true
                return
            }
            salePriceValue = parsed
        }
        
        let queued = QueuedCard(
            name: name.trimmingCharacters(in: .whitespaces),
            number: number.trimmingCharacters(in: .whitespaces).isEmpty ? nil : number.trimmingCharacters(in: .whitespaces),
            cardSet: cardSet.trimmingCharacters(in: .whitespaces).isEmpty ? nil : cardSet.trimmingCharacters(in: .whitespaces),
            graded: graded,
            gradeLevel: graded ? gradeLevel : nil,
            condition: graded ? "PSA \(gradeLevel)" : condition,
            buyPrice: buyPriceValue,
            salePrice: salePriceValue,
            hasSalePrice: hasSalePrice,
            saleDate: (hasSalePrice && salePriceValue != nil) ? saleDate : nil,
            marketPrice: marketPrice,
            purchaseDate: purchaseDate,
            photoData: photoData
        )
        
        cardQueue.append(queued)
        resetFormForNextCard()
    }
    
    // MARK: - Reset Form (keeps shared fields)
    private func resetFormForNextCard() {
        name = ""
        number = ""
        cardSet = ""
        buyPrice = ""
        salePrice = ""
        hasSalePrice = false
        photoData = nil
        marketPrice = nil
        selectedPercentage = nil
        customPercentage = ""
        referenceBuyPrice = nil
        isLoadingImage = false
        // Keep: purchaseDate, graded, gradeLevel, condition, saleDate
    }
    
    // MARK: - Save All
    private func saveAll() {
        // If current form has valid data, add it to queue first
        if currentFormIsValid {
            addToQueue()
        }
        
        guard !cardQueue.isEmpty else {
            alertMessage = "No cards to save"
            showingAlert = true
            return
        }
        
        for card in cardQueue {
            let storedBuyPrice = CurrencyFormatter.toStorageAmount(card.buyPrice, fromCode: currencyCode)
            let storedSalePrice = card.salePrice.map { CurrencyFormatter.toStorageAmount($0, fromCode: currencyCode) }
            
            let newCard = Cards(
                name: card.name,
                number: card.number,
                cardSet: card.cardSet,
                graded: card.graded,
                gradeLevel: card.gradeLevel,
                condition: card.condition,
                buyPrice: storedBuyPrice,
                salePrice: storedSalePrice,
                saleDate: card.saleDate,
                purchaseDate: card.purchaseDate,
                photoData: card.photoData,
                marketPrice: card.marketPrice,
                marketPriceDate: card.marketPrice != nil ? Date() : nil
            )
            
            modelContext.insert(newCard)
        }
        
        try? modelContext.save()
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

// MARK: - Scan Card View

struct ScanCardView: View {
    @Environment(\.dismiss) private var dismiss
    let modelContext: ModelContext
    var onSave: () -> Void
    @AppStorage("currencyCode") private var currencyCode: String = "CAD"
    
    @State private var capturedPhoto: Data?
    @State private var showingCamera = true
    @State private var recognizedName: String = ""
    @State private var recognizedNumber: String = ""
    @State private var searchResults: [CardSearchResult] = []
    @State private var isProcessing = false
    @State private var hasSearched = false
    @State private var showingAddForm = false
    @State private var showingManualSearch = false
    @State private var selectedResult: CardSearchResult?
    @State private var debugOCRText: String = ""  // Temporary debug
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.themeBackground.ignoresSafeArea()
                
                if capturedPhoto == nil && !showingCamera {
                    // Camera was cancelled
                    VStack(spacing: 16) {
                        Image(systemName: "camera.viewfinder")
                            .font(.system(size: 48))
                            .foregroundColor(.themeSecondaryText.opacity(0.3))
                        Text("No photo taken")
                            .font(.manrope(16, weight: .medium))
                            .foregroundColor(.themeSecondaryText)
                        Button("Try Again") {
                            showingCamera = true
                        }
                        .font(.manrope(16, weight: .semiBold))
                        .foregroundColor(.themeGold)
                    }
                } else if isProcessing {
                    VStack(spacing: 16) {
                        ProgressView()
                            .tint(.themeGold)
                            .scaleEffect(1.5)
                        Text("Scanning card...")
                            .font(.manrope(16, weight: .medium))
                            .foregroundColor(.themeSecondaryText)
                        Text("Reading text and searching")
                            .font(.manrope(13, weight: .regular))
                            .foregroundColor(.themeSecondaryText.opacity(0.6))
                    }
                } else if capturedPhoto != nil {
                    // Show results
                    scanResultsContent
                }
            }
            .navigationTitle("Scan Card")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .fullScreenCover(isPresented: $showingCamera) {
                CameraView { data in
                    capturedPhoto = data
                    processImage(data)
                }
                .ignoresSafeArea()
            }
            .onChange(of: showingCamera) { _, isShowing in
                // If camera was dismissed without a photo, leave capturedPhoto nil
            }
            .sheet(isPresented: $showingAddForm) {
                if let result = selectedResult {
                    AddCardFormView(
                        modelContext: modelContext,
                        onSave: {
                            showingAddForm = false
                            dismiss()
                            onSave()
                        },
                        initialResult: result,
                        initialPhotoData: capturedPhoto
                    )
                } else {
                    // Enter manually — blank form with just the photo
                    AddCardFormView(
                        modelContext: modelContext,
                        onSave: {
                            showingAddForm = false
                            dismiss()
                            onSave()
                        },
                        initialPhotoData: capturedPhoto
                    )
                }
            }
            .sheet(isPresented: $showingManualSearch) {
                CardSearchView { result in
                    selectedResult = result
                    showingManualSearch = false
                    showingAddForm = true
                }
            }
        }
    }
    
    // MARK: - Scan Results Content
    
    private var scanResultsContent: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Captured photo preview
                if let data = capturedPhoto, let uiImage = UIImage(data: data) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxHeight: 180)
                        .cornerRadius(12)
                        .padding(.horizontal)
                }
                
                // Recognized text — editable
                VStack(alignment: .leading, spacing: 8) {
                    Text("Recognized name")
                        .font(.manrope(13, weight: .medium))
                        .foregroundColor(.themeSecondaryText)
                    
                    HStack(spacing: 8) {
                        TextField("Card name...", text: $recognizedName)
                            .font(.manrope(16, weight: .medium))
                            .padding(12)
                            .background(Color.themeRowBackground)
                            .cornerRadius(10)
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.never)
                        
                        Button {
                            performSearch()
                        } label: {
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.black)
                                .padding(12)
                                .background(Color.themeGold)
                                .cornerRadius(10)
                        }
                        .disabled(recognizedName.trimmingCharacters(in: .whitespaces).count < 2)
                    }
                    
                    if !recognizedNumber.isEmpty {
                        HStack(spacing: 4) {
                            Text("Card #:")
                                .font(.manrope(12, weight: .medium))
                                .foregroundColor(.themeSecondaryText)
                            Text(recognizedNumber)
                                .font(.manrope(12, weight: .semiBold))
                                .foregroundColor(.themeGold)
                        }
                    }
                }
                .padding(.horizontal)
                
                // Debug OCR output
                if !debugOCRText.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("OCR Debug (score | text)")
                            .font(.manrope(11, weight: .bold))
                            .foregroundColor(.themeGold)
                        Text(debugOCRText)
                            .font(.system(size: 9, design: .monospaced))
                            .foregroundColor(.themeSecondaryText)
                    }
                    .padding(8)
                    .background(Color.themeRowBackground)
                    .cornerRadius(8)
                    .padding(.horizontal)
                }
                
                // Results list
                if !searchResults.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Matches")
                            .font(.manrope(13, weight: .medium))
                            .foregroundColor(.themeSecondaryText)
                            .padding(.horizontal)
                        
                        VStack(spacing: 0) {
                            ForEach(searchResults) { result in
                                Button {
                                    selectedResult = result
                                    showingAddForm = true
                                } label: {
                                    SearchResultRow(result: result)
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 10)
                                }
                                .buttonStyle(.plain)
                                
                                if result.id != searchResults.last?.id {
                                    Divider()
                                        .background(Color.themeSecondaryText.opacity(0.15))
                                        .padding(.horizontal, 16)
                                }
                            }
                        }
                        .background(Color.themeRowBackground)
                        .cornerRadius(12)
                        .padding(.horizontal)
                    }
                } else if hasSearched {
                    VStack(spacing: 8) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 32))
                            .foregroundColor(.themeSecondaryText.opacity(0.3))
                        Text("No matches found")
                            .font(.manrope(16, weight: .medium))
                            .foregroundColor(.themeSecondaryText)
                        Text("Try editing the name above and re-searching")
                            .font(.manrope(13, weight: .regular))
                            .foregroundColor(.themeSecondaryText.opacity(0.6))
                    }
                    .padding(.vertical, 20)
                }
                
                // Fallback options
                VStack(spacing: 10) {
                    if hasSearched {
                        Text("Can't find it?")
                            .font(.manrope(13, weight: .medium))
                            .foregroundColor(.themeSecondaryText)
                    }
                    
                    HStack(spacing: 12) {
                        Button {
                            showingManualSearch = true
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "magnifyingglass")
                                Text("Search Manually")
                            }
                            .font(.manrope(14, weight: .semiBold))
                            .foregroundColor(.themeGold)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(Color.themeGold.opacity(0.12))
                            .cornerRadius(10)
                        }
                        
                        Button {
                            selectedResult = nil
                            showingAddForm = true
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "square.and.pencil")
                                Text("Enter Manually")
                            }
                            .font(.manrope(14, weight: .semiBold))
                            .foregroundColor(.themeSecondaryText)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(Color.themeRowBackground)
                            .cornerRadius(10)
                        }
                    }
                }
                .padding(.top, 8)
                .padding(.horizontal)
            }
            .padding(.vertical, 16)
        }
    }
    
    // MARK: - Process Captured Image
    
    private func processImage(_ imageData: Data) {
        isProcessing = true
        Task {
            let texts = await recognizeText(from: imageData)
            
            // Build debug info showing all OCR results with positions and sizes
            let maxH = texts.map { $0.boundingBox.height }.max() ?? 1.0
            let maxY = texts.map { $0.boundingBox.midY }.max() ?? 1.0
            let heightThreshold = maxH * 0.25
            let debugLines = texts
                .sorted { $0.boundingBox.midY > $1.boundingBox.midY }
                .map { item in
                    let sizeScore = maxH > 0 ? item.boundingBox.height / maxH : 0
                    let posScore = maxY > 0 ? item.boundingBox.midY / maxY : 0
                    let total = (sizeScore * 0.7) + (posScore * 0.3)
                    let tooSmall = item.boundingBox.height < heightThreshold ? " [TINY]" : ""
                    return String(format: "%.2f (s%.2f p%.2f) H%.3f%@ | %@",
                                  total, sizeScore, posScore,
                                  item.boundingBox.height, tooSmall,
                                  item.text)
                }
            
            let (name, number) = extractCardInfo(from: texts)
            
            await MainActor.run {
                recognizedName = name
                recognizedNumber = number ?? ""
                debugOCRText = debugLines.joined(separator: "\n")
            }
            
            // Auto-search if we got a name
            if !name.isEmpty {
                await searchForCard(name: name, number: number)
            }
            
            await MainActor.run {
                isProcessing = false
                hasSearched = true
            }
        }
    }
    
    private func performSearch() {
        let name = recognizedName.trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty else { return }
        
        isProcessing = true
        hasSearched = false
        Task {
            let numberFilter = recognizedNumber.trimmingCharacters(in: .whitespaces).isEmpty ? nil : recognizedNumber.trimmingCharacters(in: .whitespaces)
            await searchForCard(name: name, number: numberFilter)
            await MainActor.run {
                isProcessing = false
                hasSearched = true
            }
        }
    }
    
    private func searchForCard(name: String, number: String?) async {
        do {
            let results = try await PokemonTCGService.searchCards(
                name: name,
                set: nil,
                number: number
            )
            await MainActor.run {
                searchResults = results
            }
        } catch {
            await MainActor.run {
                searchResults = []
            }
        }
    }
    
    // MARK: - OCR Text Recognition
    
    /// Recognized text with its bounding box position in Vision coordinates (0,0 = bottom-left)
    private struct RecognizedTextItem {
        let text: String
        let boundingBox: CGRect  // Vision coordinates: origin bottom-left, Y increases upward
    }
    
    private func recognizeText(from imageData: Data) async -> [RecognizedTextItem] {
        guard let image = UIImage(data: imageData),
              let cgImage = image.cgImage else { return [] }
        
        return await withCheckedContinuation { continuation in
            let request = VNRecognizeTextRequest { request, error in
                guard let observations = request.results as? [VNRecognizedTextObservation] else {
                    continuation.resume(returning: [])
                    return
                }
                let items = observations.compactMap { obs -> RecognizedTextItem? in
                    guard let candidate = obs.topCandidates(1).first else { return nil }
                    return RecognizedTextItem(text: candidate.string, boundingBox: obs.boundingBox)
                }
                continuation.resume(returning: items)
            }
            request.recognitionLevel = .accurate
            request.recognitionLanguages = ["en", "ja"]
            
            let handler = VNImageRequestHandler(cgImage: cgImage)
            try? handler.perform([request])
        }
    }
    
    // MARK: - Card Info Extraction
    
    private func extractCardInfo(from items: [RecognizedTextItem]) -> (name: String, number: String?) {
        var name = ""
        var number: String? = nil
        
        // --- Card number: look for "41/146" pattern, prefer lower items ---
        let sortedByYAsc = items.sorted { $0.boundingBox.midY < $1.boundingBox.midY }
        for item in sortedByYAsc {
            if let match = item.text.range(of: #"\d{1,3}\s*/\s*\d{1,3}"#, options: .regularExpression) {
                number = String(item.text[match]).replacingOccurrences(of: " ", with: "")
                break
            }
        }
        
        // --- Card name extraction ---
        // Strategy: The card name is BOTH one of the largest text elements AND near the top.
        // We combine font size (bounding box height) and position to find it.
        // This handles: variable card framing, illustrator names (small text),
        // and ability/attack names (lower position).
        
        let nameSkipPatterns = [
            #"(?i)\d+\s*HP"#,          // Contains "250 HP" or "HP 130"
            #"(?i)HP\s*\d+"#,
            #"(?i)^BASIC$"#,
            #"(?i)STAGE\s*\d"#,        // "Stage 1", "STAGE2", "STAGE 2"
            #"^\d+\s*/\s*\d+"#,        // Card number "41/146"
            #"(?i)Illus"#,             // Illustrator (anywhere in text)
            #"(?i)Weakness"#,
            #"(?i)Resistance"#,
            #"(?i)Retreat"#,
            #"(?i)^Pokémon"#,
            #"(?i)^Pokemon"#,
            #"^\d+$"#,
            #"^©"#,
            #"(?i)^TRAINER$"#,
            #"(?i)^SUPPORTER$"#,
            #"(?i)^ITEM$"#,
            #"(?i)^ENERGY$"#,
            #"^V$"#,
            #"(?i)^ex$"#,
            #"(?i)^VMAX$"#,
            #"(?i)^VSTAR$"#,
            #"^\w$"#,                  // Single character
            #"(?i)^Evolves\s"#,
            #"(?i)^NO\.\s*\d"#,
            #"(?i)^Ability"#,
            #"(?i)^Once\s"#,
            #"(?i)^This\s"#,
            #"(?i)^If\s"#,
            #"(?i)^You\s"#,
            #"(?i)^Your\s"#,
            #"(?i)^When\s"#,
            #"(?i)^During\s"#,
            #"(?i)^Put\s"#,
            #"(?i)^Attach"#,
            #"(?i)^Search"#,
            #"(?i)^Discard"#,
            #"(?i)^Draw\s"#,
            #"(?i)^Flip\s"#,
            #"(?i)^Choose"#,
            #"(?i)^Heal\s"#,
            #"(?i)^Switch"#,
            #"(?i)^Shuffle"#,
            #"(?i)^Look\s"#,
            #"(?i)\d+\s*damage"#,
            #"(?i)\d+\s*lbs"#,
            #"(?i)^HT:"#,
            #"(?i)^WT:"#,
            #"(?i)^It\s"#,
            #"(?i)^The\s"#,
            #"(?i)^A\s"#,
            #"(?i)^An\s"#,
            #"(?i)rule"#,
            #"(?i)^x\d"#,             // "x2" multiplier
            #"^\d+\s*$"#,             // Just numbers
            #"(?i)^compressed"#,
            #"(?i)Graphics$"#,        // "5ban Graphics" etc.
        ]
        
        // Find the tallest text element to establish a baseline for filtering
        let globalMaxH = items.map { $0.boundingBox.height }.max() ?? 1.0
        
        // Filter to valid candidates
        var candidates: [(text: String, item: RecognizedTextItem)] = []
        for item in items {
            let trimmed = item.text.trimmingCharacters(in: .whitespaces)
            if trimmed.count < 2 { continue }
            
            // Skip tiny text — anything less than 25% of the tallest text height
            // is fine print (illustrator names, copyright, set info, etc.)
            if globalMaxH > 0 && item.boundingBox.height < globalMaxH * 0.25 { continue }
            
            // Skip long sentences (more than 4 words are descriptions, not names)
            let wordCount = trimmed.components(separatedBy: .whitespaces).filter { !$0.isEmpty }.count
            if wordCount > 4 { continue }
            
            let shouldSkip = nameSkipPatterns.contains { pattern in
                trimmed.range(of: pattern, options: .regularExpression) != nil
            }
            if shouldSkip { continue }
            
            candidates.append((text: trimmed, item: item))
        }
        
        // Score: the card name is the LARGEST text that's also near the TOP.
        // Use bounding box height as primary signal (the name is always in the biggest font)
        // with position as tiebreaker.
        if !candidates.isEmpty {
            let maxH = candidates.map { $0.item.boundingBox.height }.max() ?? 1.0
            let maxY = candidates.map { $0.item.boundingBox.midY }.max() ?? 1.0
            
            let scored = candidates.map { c -> (text: String, score: Double) in
                let sizeNorm = maxH > 0 ? c.item.boundingBox.height / maxH : 0
                let posNorm = maxY > 0 ? c.item.boundingBox.midY / maxY : 0
                // Size is the dominant factor — the card name is always the biggest text
                let score = (sizeNorm * 0.7) + (posNorm * 0.3)
                return (text: c.text, score: score)
            }
            
            if let best = scored.max(by: { $0.score < $1.score }) {
                name = best.text
            }
        }
        
        return (name, number)
    }
}

#Preview {
    AddCardView(selectedTab: .constant(2))
        .modelContainer(previewContainer)
}
