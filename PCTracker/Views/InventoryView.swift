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
    @Environment(\.modelContext) private var modelContext
    @Query private var allCards: [Cards]
    @Query private var allSealedProducts: [SealedProduct]
    
    @State private var selectedCard: Cards?
    @State private var selectedProduct: SealedProduct?
    @State private var searchText: String = ""
    @State private var isMultiSelectMode: Bool = false
    @State private var selectedCards: Set<Cards.ID> = []
    @State private var selectedProducts: Set<SealedProduct.ID> = []
    @State private var showingDeleteConfirmation: Bool = false
    @State private var showingFilters: Bool = false
    
    // Filter state
    @State private var filterItemType: Set<ItemType> = [.cards, .sealedProducts]
    @State private var filterConditions: Set<String> = []
    @State private var filterGradedOnly: Bool = false
    @State private var filterDateRange: ClosedRange<Date>?
    @State private var usePriceFilter: Bool = false
    @State private var minPrice: Double = 0
    @State private var maxPrice: Double = 1000
    
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
                card.buyPrice >= minPrice && card.buyPrice <= maxPrice
            }
        }
        
        // Apply search
        guard !searchText.isEmpty else { return inventoryCards }
        
        return inventoryCards.filter { card in
            card.name.localizedCaseInsensitiveContains(searchText) ||
            (card.number?.localizedCaseInsensitiveContains(searchText) ?? false) ||
            card.condition.localizedCaseInsensitiveContains(searchText) ||
            (card.graded && "graded".localizedCaseInsensitiveContains(searchText))
        }
    }
    
    private var sealedProducts: [SealedProduct] {
        var inventoryProducts = allSealedProducts.filter { $0.salePrice == nil }
        
        // Apply item type filter
        if !filterItemType.contains(.sealedProducts) {
            inventoryProducts = []
        }
        
        // Apply price filter
        if usePriceFilter {
            inventoryProducts = inventoryProducts.filter { product in
                product.buyPrice >= minPrice && product.buyPrice <= maxPrice
            }
        }
        
        // Apply search
        guard !searchText.isEmpty else { return inventoryProducts }
        
        return inventoryProducts.filter { product in
            product.name.localizedCaseInsensitiveContains(searchText) ||
            (product.expansion?.localizedCaseInsensitiveContains(searchText) ?? false)
        }
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
            Group {
                if !hasAnyItems {
                    // Truly empty inventory - no items at all
                    VStack {
                        Spacer()
                        Image(systemName: "cube.box")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        Text("No Items Yet")
                            .font(.headline)
                            .padding(.top, 8)
                        Text("Add items to get started")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                } else {
                    List {
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
                                    }
                                    .font(.subheadline)
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
                                        if activeFilterCount > 0 {
                                            Text("\(activeFilterCount)")
                                                .font(.caption2)
                                                .foregroundColor(.white)
                                                .padding(.horizontal, 6)
                                                .padding(.vertical, 2)
                                                .background(Color.adaptiveBlueOrange)
                                                .clipShape(Capsule())
                                        }
                                    }
                                    .font(.subheadline)
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
                            Section {
                                VStack(spacing: 8) {
                                    Image(systemName: "magnifyingglass")
                                        .font(.system(size: 40))
                                        .foregroundColor(.gray)
                                    Text("No Results")
                                        .font(.headline)
                                        .foregroundColor(.secondary)
                                    Text("Try adjusting your search or filters")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 40)
                            }
                        }
                        
                        // Cards Section
                        if !cards.isEmpty {
                            Section("Cards") {
                                ForEach(cards) { card in
                                    HStack {
                                        if isMultiSelectMode {
                                            Image(systemName: selectedCards.contains(card.id) ? "checkmark.circle.fill" : "circle")
                                                .foregroundColor(selectedCards.contains(card.id) ? .blue : .gray)
                                                .imageScale(.large)
                                        }
                                        
                                        VStack(alignment: .leading, spacing: 4) {
                                            HStack {
                                                Text(card.name)
                                                    .font(.headline)
                                                Spacer()
                                                let conditionColor = Color.conditionColor(for: card.condition, isGraded: card.graded)
                                                Text(card.graded ? "GRADED" : card.condition)
                                                    .font(.caption2)
                                                    .padding(.horizontal, 6)
                                                    .padding(.vertical, 2)
                                                    .background(conditionColor.opacity(0.2))
                                                    .foregroundColor(conditionColor)
                                                    .cornerRadius(4)
                                            }
                                            Text("#\(card.number ?? "")")
                                                .font(.subheadline)
                                                .foregroundColor(.secondary)
                                            HStack {
                                                Text("Buy: $\(card.buyPrice, format: .number.precision(.fractionLength(2)))")
                                                    .font(.subheadline)
                                                Text("\(card.purchaseDate, format: .dateTime.month().day().year())")
                                                    .font(.caption)
                                                    .foregroundColor(.secondary)
                                            }
                                        }
                                    }
                                    .padding(.vertical, 4)
                                    .contentShape(Rectangle())
                                    .onTapGesture {
                                        if isMultiSelectMode {
                                            if selectedCards.contains(card.id) {
                                                selectedCards.remove(card.id)
                                            } else {
                                                selectedCards.insert(card.id)
                                            }
                                        } else {
                                            // Edit the card
                                            selectedCard = card
                                        }
                                    }
                                    .contextMenu {
                                        if !isMultiSelectMode {
                                            Button {
                                                selectedCard = card
                                            } label: {
                                                Label("Edit Details", systemImage: "pencil")
                                            }
                                            
                                            Divider()
                                            
                                            Button(role: .destructive) {
                                                modelContext.delete(card)
                                            } label: {
                                                Label("Delete", systemImage: "trash")
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        
                        // Sealed Products Section
                        if !sealedProducts.isEmpty {
                            Section("Sealed Products") {
                                ForEach(sealedProducts) { product in
                                    HStack {
                                        if isMultiSelectMode {
                                            Image(systemName: selectedProducts.contains(product.id) ? "checkmark.circle.fill" : "circle")
                                                .foregroundColor(selectedProducts.contains(product.id) ? .blue : .gray)
                                                .imageScale(.large)
                                        }
                                        
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(product.name)
                                                .font(.headline)
                                            Text(product.expansion ?? "")
                                                .font(.subheadline)
                                                .foregroundColor(.secondary)
                                            HStack {
                                                Text("Buy: $\(product.buyPrice, format: .number.precision(.fractionLength(2)))")
                                                    .font(.subheadline)
                                                Text("\(product.purchaseDate, format: .dateTime.month().day().year())")
                                                    .font(.caption)
                                                    .foregroundColor(.secondary)
                                            }
                                        }
                                    }
                                    .padding(.vertical, 4)
                                    .contentShape(Rectangle())
                                    .onTapGesture {
                                        if isMultiSelectMode {
                                            if selectedProducts.contains(product.id) {
                                                selectedProducts.remove(product.id)
                                            } else {
                                                selectedProducts.insert(product.id)
                                            }
                                        } else {
                                            // Edit the product
                                            selectedProduct = product
                                        }
                                    }
                                    .contextMenu {
                                        if !isMultiSelectMode {
                                            Button {
                                                selectedProduct = product
                                            } label: {
                                                Label("Edit Details", systemImage: "pencil")
                                            }
                                            
                                            Divider()
                                            
                                            Button(role: .destructive) {
                                                modelContext.delete(product)
                                            } label: {
                                                Label("Delete", systemImage: "trash")
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Inventory : $\(totalCards + totalProducts, format: .number.precision(.fractionLength(2)))")
            .searchable(text: $searchText, prompt: "Search inventory")
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
                            .font(.subheadline)
                            .foregroundColor(.secondary)
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
                }
                
                Section("Item Type") {
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
                    }
                }
                
                Section("Condition") {
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
                                    .font(.caption)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 8)
                                    .background(filterConditions.contains(condition) ? Color.adaptiveBlueOrange : Color.gray.opacity(0.2))
                                    .foregroundColor(filterConditions.contains(condition) ? .white : .primary)
                                    .cornerRadius(8)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 4)
                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                }
                
                Section {
                    Toggle("Filter by Price Range", isOn: $usePriceFilter)
                    
                    if usePriceFilter {
                        VStack(alignment: .leading, spacing: 16) {
                            HStack(spacing: 16) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Min")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    HStack(spacing: 4) {
                                        Text("$")
                                            .foregroundColor(.secondary)
                                        TextField("0", value: $minPrice, format: .number.precision(.fractionLength(0)))
                                            .keyboardType(.numberPad)
                                            .textFieldStyle(.roundedBorder)
                                    }
                                }
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Max")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    HStack(spacing: 4) {
                                        Text("$")
                                            .foregroundColor(.secondary)
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
                    
                    if useDateFilter {
                        HStack(spacing: 12) {
                            DatePicker("", selection: $startDate, displayedComponents: .date)
                                .labelsHidden()
                                .onChange(of: startDate) { _, newValue in
                                    filterDateRange = newValue...endDate
                                }
                            
                            Text("to")
                                .foregroundColor(.secondary)
                            
                            DatePicker("", selection: $endDate, displayedComponents: .date)
                                .labelsHidden()
                                .onChange(of: endDate) { _, newValue in
                                    filterDateRange = startDate...newValue
                                }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
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
    InventoryView()
        .modelContainer(for: [Cards.self, SealedProduct.self, MiscExpense.self], inMemory: true)
}
