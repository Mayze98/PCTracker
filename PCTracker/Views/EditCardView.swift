//
//  EditCardView.swift
//  PCTracker
//
//  Created by John on 2026-03-08.
//

import SwiftUI
import SwiftData
import PhotosUI

struct EditCardView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @AppStorage("currencyCode") private var currencyCode: String = "CAD"
    
    let card: Cards
    
    @State private var name: String
    @State private var number: String
    @State private var cardSet: String
    @State private var graded: Bool
    @State private var gradeLevel: Int
    @State private var condition: String
    @State private var buyPrice: String
    @State private var salePrice: String
    @State private var saleDate: Date
    @State private var purchaseDate: Date
    @State private var photoData: Data?
    @State private var showingCamera = false
    @State private var showingLibraryPicker = false
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var isFetchingPrice = false
    @State private var priceError: String?
    @State private var ebaySoldItems: [EbaySoldItem] = []
    @State private var showingSearch = false
    @State private var isLoadingImage = false

    init(card: Cards) {
        self.card = card
        let displayCode = UserDefaults.standard.string(forKey: "currencyCode") ?? "CAD"
        _name = State(initialValue: card.name)
        _number = State(initialValue: card.number ?? "")
        _cardSet = State(initialValue: card.cardSet ?? "")
        _graded = State(initialValue: card.graded)
        _gradeLevel = State(initialValue: card.gradeLevel ?? 10)
        _condition = State(initialValue: card.condition)
        _buyPrice = State(initialValue: String(format: "%.2f", CurrencyFormatter.displayAmount(card.buyPrice, displayCode: displayCode)))
        _salePrice = State(initialValue: card.salePrice != nil ? String(format: "%.2f", CurrencyFormatter.displayAmount(card.salePrice!, displayCode: displayCode)) : "")
        _saleDate = State(initialValue: card.saleDate ?? Date())
        _purchaseDate = State(initialValue: card.purchaseDate)
        _photoData = State(initialValue: card.photoData)
    }
    
    let conditions = ["NM", "LP", "MP", "HP", "DMG"]
    
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
                            Text("Update card info")
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
                            ForEach(conditions, id: \.self) { condition in
                                Text(condition).tag(condition)
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
                    HStack {
                        Text("Buy Price")
                        Spacer()
                        Text(CurrencyFormatter.symbol(for: currencyCode))
                            .foregroundColor(.themeSecondaryText)
                        TextField("0.00", text: $buyPrice)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 100)
                    }
                    .listRowBackground(Color.themeRowBackground)
                    
                    HStack {
                        Text("Sale Price")
                        Spacer()
                        Text(CurrencyFormatter.symbol(for: currencyCode))
                            .foregroundColor(.themeSecondaryText)
                        TextField("Optional", text: $salePrice)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 100)
                    }
                    .listRowBackground(Color.themeRowBackground)
                    
                    if !salePrice.isEmpty && Double(salePrice) != nil {
                        DatePicker("Sale Date", selection: $saleDate, displayedComponents: .date)
                            .environment(\.colorScheme, .dark)
                            .listRowBackground(Color.themeRowBackground)
                    }
                    
                    if let buyPriceValue = Double(buyPrice),
                       let salePriceValue = Double(salePrice),
                       salePriceValue > 0 {
                        let profit = salePriceValue - buyPriceValue
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
                    Text("Pricing")
                        .textCase(nil)
                        .foregroundColor(.themeSecondaryText)
                }
                
                Section {
                    if let marketPrice = card.marketPrice {
                        HStack {
                            Text("Market Price")
                            Spacer()
                            Text(CurrencyFormatter.convertedString(marketPrice, code: currencyCode))
                                .foregroundColor(.themeGold)
                                .bold()
                        }
                        .listRowBackground(Color.themeRowBackground)
                        
                        if let marketProfit = card.marketProfit {
                            HStack {
                                Text("Unrealized P/L")
                                Spacer()
                                Text(CurrencyFormatter.convertedSignedString(marketProfit, code: currencyCode))
                                    .foregroundColor(marketProfit >= 0 ? .themeGold : .themeLoss)
                                    .bold()
                            }
                            .listRowBackground(Color.themeRowBackground)
                        }
                        
                        if let date = card.marketPriceDate {
                            HStack {
                                Text("Last Updated")
                                Spacer()
                                Text(date, format: .dateTime.month().day().hour().minute())
                                    .foregroundColor(.themeSecondaryText)
                            }
                            .listRowBackground(Color.themeRowBackground)
                        }
                        
                        HStack {
                            Text("Source")
                            Spacer()
                            Text(card.marketPriceSource == "ebay" ? "eBay avg (5 sold)" : "TCGPlayer")
                                .font(.manrope(.caption, weight: .medium))
                                .foregroundColor(.themeSecondaryText)
                        }
                        .listRowBackground(Color.themeRowBackground)
                    }
                    
                    // eBay last 5 sold items
                    if !ebaySoldItems.isEmpty {
                        ForEach(ebaySoldItems) { item in
                            Button {
                                if let urlString = item.url, let url = URL(string: urlString) {
                                    UIApplication.shared.open(url)
                                }
                            } label: {
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(item.title)
                                        .font(.manrope(.caption, weight: .medium))
                                        .foregroundColor(.themePrimaryText)
                                        .lineLimit(2)
                                    HStack {
                                        Text(CurrencyFormatter.convertedString(item.priceCad, code: currencyCode))
                                            .font(.manrope(.caption, weight: .bold))
                                            .foregroundColor(.themeGold)
                                        Spacer()
                                        Text(item.dateSold)
                                            .font(.manrope(.caption2, weight: .regular))
                                            .foregroundColor(.themeSecondaryText)
                                        Image(systemName: "arrow.up.right.square")
                                            .font(.caption2)
                                            .foregroundColor(.themeSecondaryText)
                                    }
                                }
                            }
                            .listRowBackground(Color.themeRowBackground)
                        }
                    }
                    
                    Button {
                        fetchMarketPrice()
                    } label: {
                        HStack {
                            if isFetchingPrice {
                                ProgressView()
                                    .tint(.themeGold)
                                Text("Fetching...")
                            } else {
                                Image(systemName: "arrow.triangle.2.circlepath")
                                Text(card.marketPrice == nil ? "Check Market Price" : "Refresh Price")
                            }
                        }
                        .foregroundColor(.themeGold)
                    }
                    .disabled(isFetchingPrice)
                    .listRowBackground(Color.themeRowBackground)
                    
                    if let error = priceError {
                        Text(error)
                            .font(.manrope(.caption))
                            .foregroundColor(.themeLoss)
                            .listRowBackground(Color.themeRowBackground)
                    }
                } header: {
                    Text("Market Price")
                        .textCase(nil)
                        .foregroundColor(.themeSecondaryText)
                }
                
                Section {
                    DatePicker("Date", selection: $purchaseDate, displayedComponents: .date)
                        .environment(\.colorScheme, .dark)
                        .listRowBackground(Color.themeRowBackground)
                } header: {
                    Text("Purchase Date")
                        .textCase(nil)
                        .foregroundColor(.themeSecondaryText)
                }
                
                PhotoPickerSection(photoData: $photoData, onLibraryRequested: { showingLibraryPicker = true }, onCameraRequested: { showingCamera = true })
            }
            .foregroundColor(.themePrimaryText)
            .scrollContentBackground(.hidden)
            .background(Color.themeBackground)
            .navigationTitle("Edit Card")
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
                        saveChanges()
                    }
                    .bold()
                    .disabled(name.isEmpty || buyPrice.isEmpty)
                }
            }
            .sheet(isPresented: $showingSearch) {
                CardSearchView { result in
                    applySearchResult(result)
                }
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
    
    private func applySearchResult(_ result: CardSearchResult) {
        name = result.name
        number = result.number
        cardSet = result.setName
        
        // Update market price directly on the card model
        if let price = result.marketPrice {
            card.marketPrice = price
            card.marketPriceDate = Date()
        }
        
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
    
    private func fetchMarketPrice() {
        isFetchingPrice = true
        priceError = nil
        ebaySoldItems = []
        Task {
            do {
                let result = try await PokemonTCGService.fetchMarketPrice(
                    name: name,
                    number: number.isEmpty ? nil : number,
                    cardSet: cardSet.isEmpty ? nil : cardSet,
                    graded: graded,
                    gradeLevel: graded ? gradeLevel : nil,
                    condition: graded ? nil : condition
                )
                await MainActor.run {
                    if let result {
                        card.marketPrice = result.price
                        card.marketPriceDate = Date()
                        card.marketPriceSource = result.source
                        ebaySoldItems = result.ebaySoldItems
                        try? modelContext.save()
                    } else {
                        priceError = "No market price found for this card"
                    }
                    isFetchingPrice = false
                }
            } catch {
                await MainActor.run {
                    priceError = "Failed to fetch price"
                    isFetchingPrice = false
                }
            }
        }
    }
    
    private func saveChanges() {
        guard let buyPriceValue = Double(buyPrice) else { return }
        
        card.name = name
        card.number = number.isEmpty ? nil : number
        card.cardSet = cardSet.isEmpty ? nil : cardSet
        card.graded = graded
        card.gradeLevel = graded ? gradeLevel : nil
        card.condition = graded ? "PSA \(gradeLevel)" : condition
        card.buyPrice = CurrencyFormatter.toStorageAmount(buyPriceValue, fromCode: currencyCode)
        
        // Handle sale price and sale date
        if salePrice.isEmpty {
            card.salePrice = nil
            card.saleDate = nil
        } else if let salePriceValue = Double(salePrice) {
            card.salePrice = CurrencyFormatter.toStorageAmount(salePriceValue, fromCode: currencyCode)
            card.saleDate = saleDate
        }
        
        card.purchaseDate = purchaseDate
        card.photoData = photoData
        
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
    let container = try! ModelContainer(for: Cards.self, SealedProduct.self, MiscExpense.self, configurations: config)
    
    let sampleCard = Cards(name: "Pikachu VMAX", number: "044/185", graded: false, condition: "NM", buyPrice: 45.00, marketPrice: 62.50, marketPriceDate: Date())
    container.mainContext.insert(sampleCard)
    
    return EditCardView(card: sampleCard)
        .modelContainer(container)
}
