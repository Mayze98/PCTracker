//
//  EditSealedProductView.swift
//  PCTracker
//
//  Created by John on 2026-03-08.
//

import SwiftUI
import SwiftData
import PhotosUI

struct EditSealedProductView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @AppStorage("currencyCode") private var currencyCode: String = "CAD"
    
    let product: SealedProduct
    
    @State private var name: String
    @State private var expansion: String
    @State private var buyPrice: String
    @State private var salePrice: String
    @State private var saleDate: Date
    @State private var purchaseDate: Date
    @State private var photoData: Data?
    @State private var showingCamera = false
    @State private var showingLibraryPicker = false
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var showingSetSearch = false
    @State private var isLoadingImage = false

    init(product: SealedProduct) {
        self.product = product
        let displayCode = UserDefaults.standard.string(forKey: "currencyCode") ?? "CAD"
        _name = State(initialValue: product.name)
        _expansion = State(initialValue: product.expansion ?? "")
        _buyPrice = State(initialValue: String(format: "%.2f", CurrencyFormatter.displayAmount(product.buyPrice, displayCode: displayCode)))
        _salePrice = State(initialValue: product.salePrice.map { String(format: "%.2f", CurrencyFormatter.displayAmount($0, displayCode: displayCode)) } ?? "")
        _saleDate = State(initialValue: product.saleDate ?? Date())
        _purchaseDate = State(initialValue: product.purchaseDate)
        _photoData = State(initialValue: product.photoData)
    }
    
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
                            Text("Update set info")
                                .font(.manrope(13, weight: .regular))
                                .foregroundColor(.themeSecondaryText.opacity(0.6))
                        }
                    }
                    .listRowBackground(Color.themeGold.opacity(0.08))
                }
                
                Section {
                    HStack {
                        Text("Product Name")
                            .foregroundColor(.themePrimaryText)
                        Spacer()
                        TextField("", text: $name)
                            .multilineTextAlignment(.trailing)
                            .autocorrectionDisabled()
                            .autocapitalization(.none)
                    }
                    .listRowBackground(Color.themeRowBackground)
                    HStack {
                        Text("Expansion")
                            .foregroundColor(.themePrimaryText)
                        Spacer()
                        TextField("", text: $expansion)
                            .multilineTextAlignment(.trailing)
                            .autocorrectionDisabled()
                            .autocapitalization(.none)
                    }
                    .listRowBackground(Color.themeRowBackground)
                } header: {
                    Text("Product Information")
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
            .navigationTitle("Edit Product")
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
            .sheet(isPresented: $showingSetSearch) {
                SetSearchView { result in
                    applySetResult(result)
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
    
    private func applySetResult(_ result: SetSearchResult) {
        expansion = result.name
        
        // Download set logo image
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
    
    private func saveChanges() {
        guard let buyPriceValue = Double(buyPrice) else { return }
        
        product.name = name
        product.expansion = expansion.isEmpty ? nil : expansion
        product.buyPrice = CurrencyFormatter.toStorageAmount(buyPriceValue, fromCode: currencyCode)
        
        // Handle sale price and sale date
        if salePrice.isEmpty {
            product.salePrice = nil
            product.saleDate = nil
        } else if let salePriceValue = Double(salePrice) {
            product.salePrice = CurrencyFormatter.toStorageAmount(salePriceValue, fromCode: currencyCode)
            product.saleDate = saleDate
        }
        
        product.purchaseDate = purchaseDate
        product.photoData = photoData
        
        do {
            try modelContext.save()
        } catch {
            #if DEBUG
            print("Error saving product: \(error)")
            #endif
        }
        
        dismiss()
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    guard let container = try? ModelContainer(for: SealedProduct.self, configurations: config) else {
        fatalError("Preview ModelContainer failed to initialize")
    }
    
    let sampleProduct = SealedProduct(name: "Booster Box", expansion: "Base Set", buyPrice: 500.00)
    container.mainContext.insert(sampleProduct)
    
    return EditSealedProductView(product: sampleProduct)
        .modelContainer(container)
}
