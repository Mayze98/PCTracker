//
//  ArchivedView.swift
//  PCTracker
//
//  Created by John on 2026-02-26.
//
import SwiftData
import SwiftUI

// MARK: - Archived View
struct ArchivedView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var allCards: [Cards]
    @Query private var allSealedProducts: [SealedProduct]
    @Query private var miscExpenses: [MiscExpense]
    
    @State private var selectedCard: Cards?
    @State private var selectedProduct: SealedProduct?
    @State private var selectedExpense: MiscExpense?
    @State private var searchText: String = ""
    @State private var isMultiSelectMode: Bool = false
    @State private var selectedCards: Set<Cards.ID> = []
    @State private var selectedProducts: Set<SealedProduct.ID> = []
    @State private var selectedExpenses: Set<MiscExpense.ID> = []
    @State private var showingDeleteConfirmation: Bool = false
    
    // Filter states
    @State private var showingFilters: Bool = false
    @State private var filterItemType: Set<ItemType> = [.cards, .sealedProducts, .miscExpenses]
    @State private var filterConditions: Set<String> = []
    @State private var useBuyPriceFilter: Bool = false
    @State private var minBuyPrice: Double = 0
    @State private var maxBuyPrice: Double = 1000
    @State private var useProfitFilter: Bool = false
    @State private var minProfit: Double = -500
    @State private var maxProfit: Double = 500
    @State private var useDateFilter: Bool = false
    @State private var startDate: Date = Calendar.current.date(byAdding: .month, value: -1, to: Date()) ?? Date()
    @State private var endDate: Date = Date()
    
    enum ItemType: String, CaseIterable, Identifiable {
        case cards = "Cards"
        case sealedProducts = "Sealed Products"
        case miscExpenses = "Misc Expenses"
        
        var id: String { rawValue }
    }
    
    // Filter to show only items that have been sold (have a salePrice)
    private var cards: [Cards] {
        var soldCards = allCards.filter { $0.salePrice != nil }
        
        // Apply item type filter
        if !filterItemType.contains(.cards) {
            soldCards = []
        }
        
        // Apply condition filter
        if !filterConditions.isEmpty {
            soldCards = soldCards.filter { card in
                filterConditions.contains(card.graded ? "GRADED" : card.condition)
            }
        }
        
        // Apply buy price range filter
        if useBuyPriceFilter {
            soldCards = soldCards.filter { card in
                let buyPrice = card.buyPrice
                return buyPrice >= minBuyPrice && buyPrice <= maxBuyPrice
            }
        }
        
        // Apply profit range filter
        if useProfitFilter {
            soldCards = soldCards.filter { card in
                if let profit = card.profit {
                    return profit >= minProfit && profit <= maxProfit
                }
                return false
            }
        }
        
        // Apply date range filter
        if useDateFilter {
            soldCards = soldCards.filter { card in
                card.purchaseDate >= startDate && card.purchaseDate <= endDate
            }
        }
        
        // Apply search filter
        guard !searchText.isEmpty else { return soldCards }
        
        return soldCards.filter { card in
            let searchLower = searchText.lowercased()
            
            // Search by name, number
            if card.name.localizedCaseInsensitiveContains(searchText) ||
               (card.number?.localizedCaseInsensitiveContains(searchText) ?? false) {
                return true
            }
            
            // Search by graded
            if card.graded && "graded".localizedCaseInsensitiveContains(searchText) {
                return true
            }
            
            // Search by condition (both abbreviation and full text)
            let conditionMatches: [String: [String]] = [
                "M": ["m", "mint"],
                "NM": ["nm", "near mint", "nearmint"],
                "LP": ["lp", "light", "lightly played", "lightlyplayed"],
                "MP": ["mp", "moderate", "moderately played", "moderatelyplayed"],
                "HP": ["hp", "heavy", "heavily played", "heavilyplayed"],
                "DMG": ["dmg", "damaged", "damage"]
            ]
            
            if let possibleMatches = conditionMatches[card.condition] {
                for match in possibleMatches {
                    if match.contains(searchLower) || searchLower.contains(match) {
                        return true
                    }
                }
            }
            
            return false
        }
    }
    
    private var sealedProducts: [SealedProduct] {
        var soldProducts = allSealedProducts.filter { $0.salePrice != nil }
        
        // Apply item type filter
        if !filterItemType.contains(.sealedProducts) {
            soldProducts = []
        }
        
        // Apply buy price range filter
        if useBuyPriceFilter {
            soldProducts = soldProducts.filter { product in
                let buyPrice = product.buyPrice
                return buyPrice >= minBuyPrice && buyPrice <= maxBuyPrice
            }
        }
        
        // Apply profit range filter
        if useProfitFilter {
            soldProducts = soldProducts.filter { product in
                if let profit = product.profit {
                    return profit >= minProfit && profit <= maxProfit
                }
                return false
            }
        }
        
        // Apply date range filter
        if useDateFilter {
            soldProducts = soldProducts.filter { product in
                product.purchaseDate >= startDate && product.purchaseDate <= endDate
            }
        }
        
        // Apply search filter
        guard !searchText.isEmpty else { return soldProducts }
        
        return soldProducts.filter { product in
            product.name.localizedCaseInsensitiveContains(searchText) ||
            (product.expansion?.localizedCaseInsensitiveContains(searchText) ?? false)
        }
    }
    
    private var filteredMiscExpenses: [MiscExpense] {
        var expenses = miscExpenses
        
        // Apply item type filter
        if !filterItemType.contains(.miscExpenses) {
            expenses = []
        }
        
        // Apply price range filter
        if useBuyPriceFilter {
            expenses = expenses.filter { expense in
                expense.cost >= minBuyPrice && expense.cost <= maxBuyPrice
            }
        }
        
        // Apply date range filter
        if useDateFilter {
            expenses = expenses.filter { expense in
                expense.purchaseDate >= startDate && expense.purchaseDate <= endDate
            }
        }
        
        // Apply search filter
        guard !searchText.isEmpty else { return expenses }
        
        return expenses.filter { expense in
            expense.itemDescription.localizedCaseInsensitiveContains(searchText) ||
            (expense.notes?.localizedCaseInsensitiveContains(searchText) ?? false)
        }
    }
    
    private var activeFilterCount: Int {
        var count = 0
        if filterItemType.count < ItemType.allCases.count { count += 1 }
        if !filterConditions.isEmpty { count += 1 }
        if useBuyPriceFilter { count += 1 }
        if useProfitFilter { count += 1 }
        if useDateFilter { count += 1 }
        return count
    }
    
    // Check if there are any archived items at all (before filtering)
    private var hasAnyArchivedItems: Bool {
        !allCards.filter({ $0.salePrice != nil }).isEmpty ||
        !allSealedProducts.filter({ $0.salePrice != nil }).isEmpty ||
        !miscExpenses.isEmpty
    }
    
    private var totalProfit: Double {
        let cardsProfit = cards.reduce(0.0) { $0 + ($1.profit ?? 0) }
        let productsProfit = sealedProducts.reduce(0.0) { $0 + ($1.profit ?? 0) }
        let expensesCost = miscExpenses.reduce(0.0) { $0 + $1.cost }
        return cardsProfit + productsProfit - expensesCost
    }

    var body: some View {
        NavigationView {
            Group {
                if !hasAnyArchivedItems {
                    // Truly empty archive - no items at all
                    VStack {
                        Spacer()
                        Image(systemName: "archivebox")
                            .font(.system(size: 60))
                            .foregroundColor(.secondary)
                            .padding(.bottom, 16)
                        Text("No archived items")
                            .font(.system(size: 22, weight: .semibold))
                        Text("Items you sold will appear here")
                            .foregroundColor(.secondary)
                            .padding(.top, 4)
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
                        if cards.isEmpty && sealedProducts.isEmpty && filteredMiscExpenses.isEmpty {
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
                                                Text("Buy: $\(Double(truncating: card.buyPrice as NSNumber), specifier: "%.2f")")
                                                    .font(.subheadline)
                                                if let salePrice = card.salePrice {
                                                    Text("• Sale: $\(Double(truncating: salePrice as NSNumber), specifier: "%.2f")")
                                                        .font(.subheadline)
                                                    if let profit = card.profit {
                                                        Text("• \(profit >= 0 ? "+" : "")$\(Double(truncating: profit as NSNumber), specifier: "%.2f")")
                                                            .font(.subheadline)
                                                            .foregroundColor(profit >= 0 ? .green : .red)
                                                    }
                                                }
                                            }
                                            Text("\(card.purchaseDate, format: .dateTime.month().day().year())")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
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
                                                Text("Buy: $\(Double(truncating: product.buyPrice as NSNumber), specifier: "%.2f")")
                                                    .font(.subheadline)
                                                if let salePrice = product.salePrice {
                                                    Text("• Sale: $\(Double(truncating: salePrice as NSNumber), specifier: "%.2f")")
                                                        .font(.subheadline)
                                                    if let profit = product.profit {
                                                        Text("• \(profit >= 0 ? "+" : "")$\(Double(truncating: profit as NSNumber), specifier: "%.2f")")
                                                            .font(.subheadline)
                                                            .foregroundColor(profit >= 0 ? .green : .red)
                                                    }
                                                }
                                            }
                                            Text("\(product.purchaseDate, format: .dateTime.month().day().year())")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
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
                        
                        // Misc Expenses Section
                        if !filteredMiscExpenses.isEmpty {
                            Section("Misc Expenses") {
                                ForEach(filteredMiscExpenses) { expense in
                                    HStack {
                                        if isMultiSelectMode {
                                            Image(systemName: selectedExpenses.contains(expense.id) ? "checkmark.circle.fill" : "circle")
                                                .foregroundColor(selectedExpenses.contains(expense.id) ? .blue : .gray)
                                                .imageScale(.large)
                                        }
                                        
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(expense.itemDescription)
                                                .font(.headline)
                                            if let notes = expense.notes, !notes.isEmpty {
                                                Text(notes)
                                                    .font(.subheadline)
                                                    .foregroundColor(.secondary)
                                                    .lineLimit(2)
                                            }
                                            HStack {
                                                Text("Cost: $\(Double(truncating: expense.cost as NSNumber), specifier: "%.2f")")
                                                    .font(.subheadline)
                                                    .foregroundColor(.red)
                                                Text("• \(expense.purchaseDate, format: .dateTime.month().day().year())")
                                                    .font(.caption)
                                                    .foregroundColor(.secondary)
                                            }
                                        }
                                    }
                                    .padding(.vertical, 4)
                                    .contentShape(Rectangle())
                                    .onTapGesture {
                                        if isMultiSelectMode {
                                            if selectedExpenses.contains(expense.id) {
                                                selectedExpenses.remove(expense.id)
                                            } else {
                                                selectedExpenses.insert(expense.id)
                                            }
                                        } else {
                                            // Edit the expense
                                            selectedExpense = expense
                                        }
                                    }
                                    .contextMenu {
                                        if !isMultiSelectMode {
                                            Button {
                                                selectedExpense = expense
                                            } label: {
                                                Label("Edit Details", systemImage: "pencil")
                                            }
                                            
                                            Divider()
                                            
                                            Button(role: .destructive) {
                                                modelContext.delete(expense)
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
            .navigationTitle("Total Profit : $\(totalProfit, specifier: "%.2f")")
            .searchable(text: $searchText, prompt: "Search archive")
            .toolbar {
                if isMultiSelectMode {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Cancel") {
                            withAnimation {
                                isMultiSelectMode = false
                                selectedCards.removeAll()
                                selectedProducts.removeAll()
                                selectedExpenses.removeAll()
                            }
                        }
                    }
                    
                    ToolbarItem(placement: .status) {
                        Text("\(selectedCards.count + selectedProducts.count + selectedExpenses.count) selected")
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
                        .disabled(selectedCards.isEmpty && selectedProducts.isEmpty && selectedExpenses.isEmpty)
                    }
                }
            }
            .confirmationDialog(
                "Delete \(selectedCards.count + selectedProducts.count + selectedExpenses.count) item(s)?",
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
            .sheet(item: $selectedExpense) { expense in
                EditMiscExpenseView(expense: expense)
                    .presentationDetents([.large])
                    .presentationDragIndicator(.visible)
            }
            .sheet(isPresented: $showingFilters) {
                ArchivedFilterView(
                    itemTypes: $filterItemType,
                    conditions: $filterConditions,
                    useBuyPriceFilter: $useBuyPriceFilter,
                    minBuyPrice: $minBuyPrice,
                    maxBuyPrice: $maxBuyPrice,
                    useProfitFilter: $useProfitFilter,
                    minProfit: $minProfit,
                    maxProfit: $maxProfit,
                    useDateFilter: $useDateFilter,
                    startDate: $startDate,
                    endDate: $endDate
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
        
        // Delete selected expenses
        for expenseID in selectedExpenses {
            if let expense = miscExpenses.first(where: { $0.id == expenseID }) {
                modelContext.delete(expense)
            }
        }
        
        // Clear selections and exit multi-select mode
        selectedCards.removeAll()
        selectedProducts.removeAll()
        selectedExpenses.removeAll()
        isMultiSelectMode = false
    }
}

// MARK: - Archived Filter View
struct ArchivedFilterView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var itemTypes: Set<ArchivedView.ItemType>
    @Binding var conditions: Set<String>
    @Binding var useBuyPriceFilter: Bool
    @Binding var minBuyPrice: Double
    @Binding var maxBuyPrice: Double
    @Binding var useProfitFilter: Bool
    @Binding var minProfit: Double
    @Binding var maxProfit: Double
    @Binding var useDateFilter: Bool
    @Binding var startDate: Date
    @Binding var endDate: Date
    
    let availableConditions = ["GRADED", "NM", "LP", "MP", "HP", "DMG"]
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Button("Clear All Filters") {
                        itemTypes = Set(ArchivedView.ItemType.allCases)
                        conditions.removeAll()
                        useBuyPriceFilter = false
                        minBuyPrice = 0
                        maxBuyPrice = 1000
                        useProfitFilter = false
                        minProfit = 0
                        maxProfit = 500
                        useDateFilter = false
                        startDate = Calendar.current.date(byAdding: .month, value: -1, to: Date()) ?? Date()
                        endDate = Date()
                    }
                    .foregroundColor(.red)
                }
                
                Section("Item Type") {
                    ForEach(ArchivedView.ItemType.allCases) { type in
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
                                if conditions.contains(condition) {
                                    conditions.remove(condition)
                                } else {
                                    conditions.insert(condition)
                                }
                            } label: {
                                Text(condition)
                                    .font(.caption)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 8)
                                    .background(conditions.contains(condition) ? Color.adaptiveBlueOrange : Color.gray.opacity(0.2))
                                    .foregroundColor(conditions.contains(condition) ? .white : .primary)
                                    .cornerRadius(8)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 4)
                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                }
                
                Section {
                    Toggle("Filter by Buy Price", isOn: $useBuyPriceFilter)
                    
                    if useBuyPriceFilter {
                        VStack(alignment: .leading, spacing: 16) {
                            HStack(spacing: 16) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Min")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    HStack(spacing: 4) {
                                        Text("$")
                                            .foregroundColor(.secondary)
                                        TextField("0", value: $minBuyPrice, format: .number.precision(.fractionLength(0)))
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
                                        TextField("10000", value: $maxBuyPrice, format: .number.precision(.fractionLength(0)))
                                            .keyboardType(.numberPad)
                                            .textFieldStyle(.roundedBorder)
                                    }
                                }
                            }
                            
                            RangeSlider(
                                minValue: $minBuyPrice,
                                maxValue: $maxBuyPrice,
                                bounds: 0...10000,
                                step: 1
                            )
                            .frame(height: 30)
                        }
                        .padding(.vertical, 8)
                    }
                }
                
                Section {
                    Toggle("Filter by Profit", isOn: $useProfitFilter)
                    
                    if useProfitFilter {
                        VStack(alignment: .leading, spacing: 16) {
                            HStack(spacing: 16) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Min")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    HStack(spacing: 4) {
                                        Text("$")
                                            .foregroundColor(.secondary)
                                        TextField("-500", value: $minProfit, format: .number.precision(.fractionLength(0)))
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
                                        TextField("5000", value: $maxProfit, format: .number.precision(.fractionLength(0)))
                                            .keyboardType(.numberPad)
                                            .textFieldStyle(.roundedBorder)
                                    }
                                }
                            }
                            
                            RangeSlider(
                                minValue: $minProfit,
                                maxValue: $maxProfit,
                                bounds: -1000...5000,
                                step: 1
                            )
                            .frame(height: 30)
                        }
                        .padding(.vertical, 8)
                    }
                }
                
                Section {
                    Toggle("Filter by Date Range", isOn: $useDateFilter)
                    
                    if useDateFilter {
                        HStack(spacing: 12) {
                            DatePicker("", selection: $startDate, displayedComponents: .date)
                                .labelsHidden()
                            
                            Text("to")
                                .foregroundColor(.secondary)
                            
                            DatePicker("", selection: $endDate, displayedComponents: .date)
                                .labelsHidden()
                        }
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
        }
    }
}

// MARK: - Range Slider
struct RangeSlider: View {
    @Binding var minValue: Double
    @Binding var maxValue: Double
    let bounds: ClosedRange<Double>
    var step: Double = 0.01
    
    @State private var minOffset: CGFloat = 0
    @State private var maxOffset: CGFloat = 0
    @State private var trackWidth: CGFloat = 0
    
    private let thumbSize: CGFloat = 28
    private let trackHeight: CGFloat = 4
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Background track
                RoundedRectangle(cornerRadius: trackHeight / 2)
                    .fill(Color.gray.opacity(0.2))
                    .frame(height: trackHeight)
                
                // Active track (between thumbs)
                RoundedRectangle(cornerRadius: trackHeight / 2)
                    .fill(Color.adaptiveBlueOrange)
                    .frame(width: max(0, maxOffset - minOffset), height: trackHeight)
                    .offset(x: minOffset)
                
                // Min thumb
                Circle()
                    .fill(Color.white)
                    .frame(width: thumbSize, height: thumbSize)
                    .shadow(color: .black.opacity(0.2), radius: 2, x: 0, y: 1)
                    .overlay(
                        Circle()
                            .stroke(Color.adaptiveBlueOrange, lineWidth: 2)
                    )
                    .offset(x: minOffset - thumbSize / 2)
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { value in
                                let newOffset = max(0, min(maxOffset - thumbSize, value.location.x - thumbSize / 2))
                                minOffset = newOffset
                                let percentage = newOffset / (geometry.size.width - thumbSize)
                                let range = bounds.upperBound - bounds.lowerBound
                                let rawValue = bounds.lowerBound + (range * Double(percentage))
                                minValue = (rawValue / step).rounded() * step
                            }
                    )
                
                // Max thumb
                Circle()
                    .fill(Color.white)
                    .frame(width: thumbSize, height: thumbSize)
                    .shadow(color: .black.opacity(0.2), radius: 2, x: 0, y: 1)
                    .overlay(
                        Circle()
                            .stroke(Color.adaptiveBlueOrange, lineWidth: 2)
                    )
                    .offset(x: maxOffset - thumbSize / 2)
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { value in
                                let newOffset = max(minOffset + thumbSize, min(geometry.size.width, value.location.x - thumbSize / 2))
                                maxOffset = newOffset
                                let percentage = newOffset / (geometry.size.width - thumbSize)
                                let range = bounds.upperBound - bounds.lowerBound
                                let rawValue = bounds.lowerBound + (range * Double(percentage))
                                maxValue = (rawValue / step).rounded() * step
                            }
                    )
            }
            .frame(height: thumbSize)
            .onAppear {
                updateOffsets(width: geometry.size.width)
            }
            .onChange(of: geometry.size.width) { _, newWidth in
                updateOffsets(width: newWidth)
            }
            .onChange(of: minValue) { _, _ in
                updateOffsets(width: geometry.size.width)
            }
            .onChange(of: maxValue) { _, _ in
                updateOffsets(width: geometry.size.width)
            }
        }
    }
    
    private func updateOffsets(width: CGFloat) {
        let range = bounds.upperBound - bounds.lowerBound
        let minPercentage = CGFloat((minValue - bounds.lowerBound) / range)
        let maxPercentage = CGFloat((maxValue - bounds.lowerBound) / range)
        
        trackWidth = width - thumbSize
        minOffset = minPercentage * trackWidth
        maxOffset = maxPercentage * trackWidth
    }
}

#Preview {
    ArchivedView()
        .modelContainer(for: [Cards.self, SealedProduct.self, MiscExpense.self], inMemory: true)
}

