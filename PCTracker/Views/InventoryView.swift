//
//  InventoryView.swift
//  PCTracker
//
//  Created by John on 2026-02-26.
//
import SwiftData
import SwiftUI

// MARK: - Inventory View
struct InventoryView: View {
    @Binding var selectedTab: Int
    
    @Environment(\.modelContext) private var modelContext
    @Query private var allCards: [Cards]
    @Query private var allSealedProducts: [SealedProduct]
    @AppStorage("currencyCode") private var currencyCode: String = "CAD"
    
    @State private var selectedCard: Cards?
    @State private var selectedProduct: SealedProduct?
    @State private var searchText: String = ""
    @State private var isMultiSelectMode: Bool = false
    @State private var selectedCards: Set<Cards.ID> = []
    @State private var selectedProducts: Set<SealedProduct.ID> = []
    @State private var showingDeleteConfirmation: Bool = false
    @State private var showingFilters: Bool = false
    @State private var isRefreshingPrices = false
    @State private var refreshProgress: (current: Int, total: Int) = (0, 0)
    
    // Filter state
    @State private var filterItemType: Set<ItemType> = [.cards, .sealedProducts]
    @State private var filterConditions: Set<String> = []
    @State private var filterGradedOnly: Bool = false
    @State private var filterDateRange: ClosedRange<Date>?
    @State private var usePriceFilter: Bool = false
    @State private var minPrice: Double = 0
    @State private var maxPrice: Double = 1000
    
    // Sort states
    @State private var sortOption: SortOption = .date
    @State private var sortAscending: Bool = false
    @State private var showingSaveError = false
    @State private var saveErrorMessage = ""
    
    enum SortOption: String, CaseIterable, Identifiable {
        case buyPrice = "Buy Price"
        case marketPrice = "Market Price"
        case name = "Name"
        case date = "Date"
        
        var id: String { rawValue }
    }
    
    enum ItemType: String, CaseIterable, Identifiable {
        case cards = "Cards"
        case sealedProducts = "Sealed Products"
        
        var id: String { rawValue }
    }
    
    private var activeFilterCount: Int {
        var count = 0
        if filterItemType.count < ItemType.allCases.count { count += 1 }
        if !filterConditions.isEmpty { count += 1 }
        if filterGradedOnly { count += 1 }
        if filterDateRange != nil { count += 1 }
        if usePriceFilter { count += 1 }
        return count
    }
    
    private func sortCards(_ cards: [Cards]) -> [Cards] {
        cards.sorted { lhs, rhs in
            switch sortOption {
            case .buyPrice:
                return sortAscending ? lhs.buyPrice < rhs.buyPrice : lhs.buyPrice > rhs.buyPrice
            case .marketPrice:
                return sortAscending ? (lhs.marketPrice ?? 0) < (rhs.marketPrice ?? 0) : (lhs.marketPrice ?? 0) > (rhs.marketPrice ?? 0)
            case .name:
                return sortAscending ? lhs.name < rhs.name : lhs.name > rhs.name
            case .date:
                return sortAscending ? lhs.purchaseDate < rhs.purchaseDate : lhs.purchaseDate > rhs.purchaseDate
            }
        }
    }
    
    private func sortSealedProducts(_ products: [SealedProduct]) -> [SealedProduct] {
        products.sorted { lhs, rhs in
            switch sortOption {
            case .buyPrice, .marketPrice:
                return sortAscending ? lhs.buyPrice < rhs.buyPrice : lhs.buyPrice > rhs.buyPrice
            case .name:
                return sortAscending ? lhs.name < rhs.name : lhs.name > rhs.name
            case .date:
                return sortAscending ? lhs.purchaseDate < rhs.purchaseDate : lhs.purchaseDate > rhs.purchaseDate
            }
        }
    }

    // Filter out items that have been sold (have a salePrice)
    private var cards: [Cards] {
        var inventoryCards = allCards.filter { $0.salePrice == nil }
        
        // Apply item type filter
        if !filterItemType.contains(.cards) {
            inventoryCards = []
        }
        
        // Apply filters
        if !filterConditions.isEmpty {
            inventoryCards = inventoryCards.filter { card in
                // Check if "GRADED" is selected and card is graded
                if filterConditions.contains("GRADED") && card.graded {
                    return true
                }
                // Check if card's condition matches any selected condition (but not if it's graded)
                if !card.graded && filterConditions.contains(card.condition) {
                    return true
                }
                return false
            }
        }
        if filterGradedOnly {
            inventoryCards = inventoryCards.filter { $0.graded }
        }
        if let dateRange = filterDateRange {
            inventoryCards = inventoryCards.filter { dateRange.contains($0.purchaseDate) }
        }
        if usePriceFilter {
            inventoryCards = inventoryCards.filter { card in
                let displayPrice = CurrencyFormatter.displayAmount(card.buyPrice, displayCode: currencyCode)
                return displayPrice >= minPrice && displayPrice <= maxPrice
            }
        }
        
        // Apply search
        guard !searchText.isEmpty else { 
            return sortCards(inventoryCards)
        }
        
        let filteredCards = inventoryCards.filter { card in
            card.name.localizedCaseInsensitiveContains(searchText) ||
            (card.number?.localizedCaseInsensitiveContains(searchText) ?? false) ||
            (card.cardSet?.localizedCaseInsensitiveContains(searchText) ?? false) ||
            card.condition.localizedCaseInsensitiveContains(searchText) ||
            (card.graded && "graded".localizedCaseInsensitiveContains(searchText))
        }
        
        return sortCards(filteredCards)
    }
    
    private var sealedProducts: [SealedProduct] {
        var inventoryProducts = allSealedProducts.filter { $0.salePrice == nil }
        
        // Apply item type filter
        if !filterItemType.contains(.sealedProducts) {
            inventoryProducts = []
        }
        
        // Apply date range filter
        if let dateRange = filterDateRange {
            inventoryProducts = inventoryProducts.filter { dateRange.contains($0.purchaseDate) }
        }
        
        // Apply price filter
        if usePriceFilter {
            inventoryProducts = inventoryProducts.filter { product in
                let displayPrice = CurrencyFormatter.displayAmount(product.buyPrice, displayCode: currencyCode)
                return displayPrice >= minPrice && displayPrice <= maxPrice
            }
        }
        
        // Apply search
        guard !searchText.isEmpty else { 
            return sortSealedProducts(inventoryProducts)
        }
        
        let filteredProducts = inventoryProducts.filter { product in
            product.name.localizedCaseInsensitiveContains(searchText) ||
            (product.expansion?.localizedCaseInsensitiveContains(searchText) ?? false)
        }
        
        return sortSealedProducts(filteredProducts)
    }

    private var totalCards: Double {
        cards.reduce(0.0) { $0 + $1.buyPrice }
    }
    
    private var totalProducts: Double {
        sealedProducts.reduce(0.0) { $0 + $1.buyPrice }
    }
    
    private var hasAnyItems: Bool {
        !allCards.isEmpty || !allSealedProducts.isEmpty
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Inventory")
                            .font(.manrope(24, weight: .bold))
                        Spacer()
                        if isRefreshingPrices {
                            HStack(spacing: 4) {
                                ProgressView()
                                    .tint(.themeGold)
                                Text("\(refreshProgress.current)/\(refreshProgress.total)")
                                    .font(.manrope(.caption))
                                    .foregroundColor(.themeSecondaryText)
                            }
                        } else {
                            Button {
                                refreshAllPrices()
                            } label: {
                                Image(systemName: "arrow.triangle.2.circlepath")
                                    .font(.system(size: 16))
                                    .foregroundColor(.themeGold)
                            }
                        }
                    }
                    Text(CurrencyFormatter.convertedString(totalCards + totalProducts, code: currencyCode))
                        .font(.manrope(15, weight: .medium))
                        .foregroundColor(.themeSecondaryText)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)
                .padding(.top, 8)
                .background(Color.themeBackground)
                
                if !hasAnyItems {
                    EmptyStateView(
                        icon: "cube.box",
                        title: "No Items Yet",
                        subtitle: "Add items to get started"
                    )
                } else {
                    ScrollViewReader { scrollProxy in
                    ZStack(alignment: .bottomTrailing) {
                    List {
                        // Search

                        Section {
                            HStack {
                                Image(systemName: "magnifyingglass")
                                    .foregroundColor(.themeSecondaryText)
                                TextField("Search inventory", text: $searchText)
                                    .font(.manrope(.body))
                                if !searchText.isEmpty {
                                    Button {
                                        searchText = ""
                                    } label: {
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundColor(.themeSecondaryText)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .listRowBackground(Color.themeRowBackground)
                        }
                        .id("inventoryTop")

                        
                        // Action Buttons
                        Section {
                            HStack(spacing: 12) {
                                Button {
                                    withAnimation {
                                        isMultiSelectMode = true
                                    }
                                } label: {
                                    HStack {
                                        Image(systemName: "checkmark.circle")
                                        Text("Select")
                                            .font(.manrope(.subheadline, weight: .medium))
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 10)
                                    .background(Color.adaptiveBlueOrange.opacity(0.1))
                                    .foregroundColor(.adaptiveBlueOrange)
                                    .cornerRadius(8)
                                }
                                .buttonStyle(.plain)
                                
                                Button {
                                    showingFilters.toggle()
                                } label: {
                                    HStack {
                                        Image(systemName: "line.3.horizontal.decrease.circle")
                                        Text("Filter")
                                            .font(.manrope(.subheadline, weight: .medium))
                                        if activeFilterCount > 0 {
                                            Text("\(activeFilterCount)")
                                                .font(.manrope(.caption2, weight: .bold))
                                                .foregroundColor(.white)
                                                .padding(.horizontal, 6)
                                                .padding(.vertical, 2)
                                                .background(Color.adaptiveBlueOrange)
                                                .clipShape(Capsule())
                                        }
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 10)
                                    .background(Color.adaptiveBlueOrange.opacity(0.1))
                                    .foregroundColor(.adaptiveBlueOrange)
                                    .cornerRadius(8)
                                }
                                .buttonStyle(.plain)
                                
                                Menu {
                                    Picker("Sort By", selection: $sortOption) {
                                        ForEach(SortOption.allCases) { option in
                                            Text(option.rawValue).tag(option)
                                        }
                                    }
                                    
                                    Divider()
                                    
                                    Button {
                                        sortAscending.toggle()
                                    } label: {
                                        Label(
                                            sortAscending ? "Ascending" : "Descending",
                                            systemImage: sortAscending ? "arrow.up" : "arrow.down"
                                        )
                                    }
                                    
                                    Divider()
                                    
                                    Button(role: .destructive) {
                                        sortOption = .date
                                        sortAscending = false
                                    } label: {
                                        Label("Clear Sorting", systemImage: "xmark.circle")
                                    }
                                } label: {
                                    HStack {
                                        Image(systemName: "arrow.up.arrow.down")
                                        Text("Sort")
                                            .font(.manrope(.subheadline, weight: .medium))
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 10)
                                    .background(Color.adaptiveBlueOrange.opacity(0.1))
                                    .foregroundColor(.adaptiveBlueOrange)
                                    .cornerRadius(8)
                                }
                                .buttonStyle(.plain)
                            }
                            .listRowInsets(EdgeInsets())
                            .listRowBackground(Color.clear)
                        }
                        
                        // No Results Message
                        if cards.isEmpty && sealedProducts.isEmpty {
                            NoResultsView()
                        }
                        
                        // Cards Section
                        if !cards.isEmpty {
                            Section {
                                ForEach(cards) { card in
                                    InventoryCardRow(
                                        card: card,
                                        isMultiSelectMode: isMultiSelectMode,
                                        isSelected: selectedCards.contains(card.id),
                                        showProfit: false,
                                        onTap: {
                                            if isMultiSelectMode {
                                                if selectedCards.contains(card.id) {
                                                    selectedCards.remove(card.id)
                                                } else {
                                                    selectedCards.insert(card.id)
                                                }
                                            } else {
                                                selectedCard = card
                                            }
                                        },
                                        onDelete: {
                                            modelContext.delete(card)
                                        },
                                        onEdit: {
                                            selectedCard = card
                                        }
                                    )
                                    .listRowBackground(Color.themeRowBackground)
                                }
                            } header: {
                                Text("Cards")
                                    .textCase(nil)
                            }
                        }
                        
                        // Sealed Products Section
                        if !sealedProducts.isEmpty {
                            Section {
                                ForEach(sealedProducts) { product in
                                    InventorySealedProductRow(
                                        product: product,
                                        isMultiSelectMode: isMultiSelectMode,
                                        isSelected: selectedProducts.contains(product.id),
                                        showProfit: false,
                                        onTap: {
                                            if isMultiSelectMode {
                                                if selectedProducts.contains(product.id) {
                                                    selectedProducts.remove(product.id)
                                                } else {
                                                    selectedProducts.insert(product.id)
                                                }
                                            } else {
                                                selectedProduct = product
                                            }
                                        },
                                        onDelete: {
                                            modelContext.delete(product)
                                        },
                                        onEdit: {
                                            selectedProduct = product
                                        }
                                    )
                                    .listRowBackground(Color.themeRowBackground)
                                }
                            } header: {
                                Text("Sealed Products")
                                    .textCase(nil)
                            }
                        }
                    }
                    .contentMargins(.top, 8)
                    .listSectionSpacing(12)
                    .scrollContentBackground(.hidden)
                    .background(Color.themeBackground)
                    .onChange(of: selectedTab) { _, _ in
                        searchText = ""
                        isMultiSelectMode = false
                        selectedCards.removeAll()
                        selectedProducts.removeAll()
                        showingFilters = false
                        filterItemType = [.cards, .sealedProducts]
                        filterConditions = []
                        filterGradedOnly = false
                        filterDateRange = nil
                        usePriceFilter = false
                        minPrice = 0
                        maxPrice = 1000
                        sortOption = .date
                        sortAscending = false
                    }
                    
                    // Scroll to top button
                    Button {
                        withAnimation {
                            scrollProxy.scrollTo("inventoryTop", anchor: .top)
                        }
                    } label: {
                        Image(systemName: "arrow.up")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.themePrimaryText)
                            .frame(width: 44, height: 44)
                            .background(Color.themeCardBackground)
                            .clipShape(Circle())
                            .shadow(color: .black.opacity(0.25), radius: 4, x: 0, y: 2)
                            .overlay(
                                Circle()
                                    .stroke(Color.themeGold.opacity(0.3), lineWidth: 1)
                            )
                    }
                    .padding(.trailing, 20)
                    .padding(.bottom, 20)
                    } // ZStack
                    } // ScrollViewReader
                }
            }
            .background(Color.themeBackground)
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(isMultiSelectMode ? .visible : .hidden, for: .navigationBar)
            .tint(.themeGold)
            .toolbar {
                if isMultiSelectMode {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Cancel") {
                            withAnimation {
                                isMultiSelectMode = false
                                selectedCards.removeAll()
                                selectedProducts.removeAll()
                            }
                        }
                    }
                    
                    ToolbarItem(placement: .status) {
                        Text("\(selectedCards.count + selectedProducts.count) selected")
                            .font(.manrope(.subheadline))
                            .foregroundColor(.themeSecondaryText)
                    }
                    
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(role: .destructive) {
                            showingDeleteConfirmation = true
                        } label: {
                            Image(systemName: "trash")
                                .foregroundColor(.red)
                        }
                        .disabled(selectedCards.isEmpty && selectedProducts.isEmpty)
                    }
                }
            }
            .confirmationDialog(
                "Delete \(selectedCards.count + selectedProducts.count) item(s)?",
                isPresented: $showingDeleteConfirmation,
                titleVisibility: .visible
            ) {
                Button("Delete", role: .destructive) {
                    deleteSelectedItems()
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("This action cannot be undone.")
            }
            .sheet(item: $selectedCard) { card in
                EditCardView(card: card)
                    .presentationDetents([.large])
                    .presentationDragIndicator(.visible)
            }
            .sheet(item: $selectedProduct) { product in
                EditSealedProductView(product: product)
                    .presentationDetents([.large])
                    .presentationDragIndicator(.visible)
            }
            .sheet(isPresented: $showingFilters) {
                InventoryFilterView(
                    itemTypes: $filterItemType,
                    filterConditions: $filterConditions,
                    filterGradedOnly: $filterGradedOnly,
                    filterDateRange: $filterDateRange,
                    usePriceFilter: $usePriceFilter,
                    minPrice: $minPrice,
                    maxPrice: $maxPrice
                )
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
            }
            .alert("Save Error", isPresented: $showingSaveError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(saveErrorMessage)
            }
        }
    }
    
    private func refreshAllPrices() {
        let cardsToRefresh = cards.filter { $0.isMarketPriceStale }
        guard !cardsToRefresh.isEmpty else { return }
        
        isRefreshingPrices = true
        refreshProgress = (0, cardsToRefresh.count)
        
        Task {
            for (index, card) in cardsToRefresh.enumerated() {
                do {
                    let result = try await PokemonTCGService.fetchMarketPrice(
                        name: card.name,
                        number: card.number,
                        cardSet: card.cardSet,
                        graded: card.graded,
                        gradeLevel: card.gradeLevel,
                        condition: card.graded ? nil : card.condition
                    )
                    await MainActor.run {
                        if let result {
                            card.marketPrice = result.price
                            card.marketPriceDate = Date()
                            card.marketPriceSource = result.source
                        }
                        refreshProgress.current = index + 1
                    }
                    // Rate limit: 200ms between requests
                    try await Task.sleep(for: .milliseconds(200))
                } catch {
                    continue
                }
            }
            await MainActor.run {
                do {
                    try modelContext.save()
                } catch {
                    saveErrorMessage = "Failed to save updated prices: \(error.localizedDescription)"
                    showingSaveError = true
                }
                isRefreshingPrices = false
            }
        }
    }
    
    private func deleteSelectedItems() {
        // Delete selected cards
        for cardID in selectedCards {
            if let card = allCards.first(where: { $0.id == cardID }) {
                modelContext.delete(card)
            }
        }
        
        // Delete selected products
        for productID in selectedProducts {
            if let product = allSealedProducts.first(where: { $0.id == productID }) {
                modelContext.delete(product)
            }
        }
        
        // Clear selections and exit multi-select mode
        selectedCards.removeAll()
        selectedProducts.removeAll()
        isMultiSelectMode = false
    }
}

// MARK: - Inventory Filter View
struct InventoryFilterView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var itemTypes: Set<InventoryView.ItemType>
    @Binding var filterConditions: Set<String>
    @Binding var filterGradedOnly: Bool
    @Binding var filterDateRange: ClosedRange<Date>?
    @Binding var usePriceFilter: Bool
    @Binding var minPrice: Double
    @Binding var maxPrice: Double
    @AppStorage("currencyCode") private var currencyCode: String = "CAD"
    
    @State private var useDateFilter: Bool = false
    @State private var startDate: Date = Calendar.current.date(byAdding: .month, value: -1, to: Date()) ?? Date()
    @State private var endDate: Date = Date()
    
    let availableConditions = ["GRADED", "NM", "LP", "MP", "HP", "DMG"]
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Button("Clear All Filters") {
                        itemTypes = Set(InventoryView.ItemType.allCases)
                        filterConditions.removeAll()
                        filterGradedOnly = false
                        filterDateRange = nil
                        useDateFilter = false
                        usePriceFilter = false
                        minPrice = 0
                        maxPrice = 1000
                    }
                    .foregroundColor(.red)
                    .listRowBackground(Color.themeRowBackground)
                }
                
                Section {
                    ForEach(InventoryView.ItemType.allCases) { type in
                        Toggle(type.rawValue, isOn: Binding(
                            get: { itemTypes.contains(type) },
                            set: { isOn in
                                if isOn {
                                    itemTypes.insert(type)
                                } else {
                                    itemTypes.remove(type)
                                }
                            }
                        ))
                        .listRowBackground(Color.themeRowBackground)
                    }
                } header: {
                    Text("Item Type")
                        .textCase(nil)
                }
                
                Section {
                    HStack(spacing: 8) {
                        ForEach(availableConditions, id: \.self) { condition in
                            Button {
                                if filterConditions.contains(condition) {
                                    filterConditions.remove(condition)
                                } else {
                                    filterConditions.insert(condition)
                                }
                            } label: {
                                Text(condition)
                                    .font(.manrope(.caption, weight: .medium))
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 8)
                                    .background(filterConditions.contains(condition) ? Color.adaptiveBlueOrange : Color.gray.opacity(0.2))
                                    .foregroundColor(filterConditions.contains(condition) ? .white : .themePrimaryText)
                                    .cornerRadius(8)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 4)
                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                    .listRowBackground(Color.themeRowBackground)
                } header: {
                    Text("Condition")
                        .textCase(nil)
                }
                
                Section {
                    Toggle("Filter by Price Range", isOn: $usePriceFilter)
                        .listRowBackground(Color.themeRowBackground)
                    
                    if usePriceFilter {
                        VStack(alignment: .leading, spacing: 16) {
                            HStack(spacing: 16) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Min")
                                        .font(.manrope(.caption, weight: .medium))
                                        .foregroundColor(.themeSecondaryText)
                                    HStack(spacing: 4) {
                                        Text(CurrencyFormatter.symbol(for: currencyCode))
                                            .foregroundColor(.themeSecondaryText)
                                        TextField("0", value: $minPrice, format: .number.precision(.fractionLength(0)))
                                            .keyboardType(.numberPad)
                                            .textFieldStyle(.roundedBorder)
                                    }
                                }
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Max")
                                        .font(.manrope(.caption, weight: .medium))
                                        .foregroundColor(.themeSecondaryText)
                                    HStack(spacing: 4) {
                                        Text(CurrencyFormatter.symbol(for: currencyCode))
                                            .foregroundColor(.themeSecondaryText)
                                        TextField("10000", value: $maxPrice, format: .number.precision(.fractionLength(0)))
                                            .keyboardType(.numberPad)
                                            .textFieldStyle(.roundedBorder)
                                    }
                                }
                            }
                            
                            RangeSlider(
                                minValue: $minPrice,
                                maxValue: $maxPrice,
                                bounds: 0...10000,
                                step: 1
                            )
                            .frame(height: 30)
                        }
                        .padding(.vertical, 8)
                        .listRowBackground(Color.themeRowBackground)
                    }
                }
                
                Section {
                    Toggle("Filter by Date Range", isOn: $useDateFilter)
                        .onChange(of: useDateFilter) { _, newValue in
                            if newValue {
                                filterDateRange = startDate...endDate
                            } else {
                                filterDateRange = nil
                            }
                        }
                        .listRowBackground(Color.themeRowBackground)
                    
                    if useDateFilter {
                        HStack(spacing: 12) {
                            DatePicker("", selection: $startDate, displayedComponents: .date)
                                .labelsHidden()
                                .environment(\.colorScheme, .dark)
                                .onChange(of: startDate) { _, newValue in
                                    filterDateRange = newValue...endDate
                                }
                            
                            Text("to")
                                .foregroundColor(.themeSecondaryText)
                            
                            DatePicker("", selection: $endDate, displayedComponents: .date)
                                .labelsHidden()
                                .environment(\.colorScheme, .dark)
                                .onChange(of: endDate) { _, newValue in
                                    filterDateRange = startDate...newValue
                                }
                        }
                        .padding(.vertical, 4)
                        .listRowBackground(Color.themeRowBackground)
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color.themeBackground)
            .tint(.themeGold)
            .navigationTitle("Filters")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                useDateFilter = filterDateRange != nil
                if let range = filterDateRange {
                    startDate = range.lowerBound
                    endDate = range.upperBound
                }
            }
        }
    }
}

#Preview {
    InventoryView(selectedTab: .constant(1))
        .modelContainer(previewContainer)
}
