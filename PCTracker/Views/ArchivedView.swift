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
    @Binding var selectedTab: Int
    
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
    
    // Sorting states
    @State private var sortOption: SortOption = .date
    @State private var sortAscending: Bool = false
    
    enum ItemType: String, CaseIterable, Identifiable {
        case cards = "Cards"
        case sealedProducts = "Sealed Products"
        case miscExpenses = "Misc Expenses"
        
        var id: String { rawValue }
    }
    
    enum SortOption: String, CaseIterable, Identifiable {
        case date = "Date"
        case profit = "Profit"
        case buyPrice = "Buy Price"
        case salePrice = "Sale Price"
        case name = "Name"
        
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
        
        // Apply date range filter (using saleDate)
        if useDateFilter {
            soldCards = soldCards.filter { card in
                let dateToCheck = card.saleDate ?? card.purchaseDate
                return dateToCheck >= startDate && dateToCheck <= endDate
            }
        }
        
        // Apply search filter
        if !searchText.isEmpty {
            soldCards = soldCards.filter { card in
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
        
        // Apply sorting
        return soldCards.sorted(by: sortOption.rawValue, ascending: sortAscending)
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
        
        // Apply date range filter (using saleDate)
        if useDateFilter {
            soldProducts = soldProducts.filter { product in
                let dateToCheck = product.saleDate ?? product.purchaseDate
                return dateToCheck >= startDate && dateToCheck <= endDate
            }
        }
        
        // Apply search filter
        if !searchText.isEmpty {
            soldProducts = soldProducts.filter { product in
                product.name.localizedCaseInsensitiveContains(searchText) ||
                (product.expansion?.localizedCaseInsensitiveContains(searchText) ?? false)
            }
        }
        
        // Apply sorting
        return soldProducts.sorted(by: sortOption.rawValue, ascending: sortAscending)
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
        if !searchText.isEmpty {
            expenses = expenses.filter { expense in
                expense.itemDescription.localizedCaseInsensitiveContains(searchText) ||
                (expense.notes?.localizedCaseInsensitiveContains(searchText) ?? false)
            }
        }
        
        // Apply sorting
        return expenses.sorted(by: sortOption.rawValue, ascending: sortAscending)
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
        let cardsProfit = cards.reduce(0.0) { sum, card in
            sum + (card.profit ?? 0)
        }
        let productsProfit = sealedProducts.reduce(0.0) { sum, product in
            sum + (product.profit ?? 0)
        }
        let expensesCost = filteredMiscExpenses.reduce(0.0) { sum, expense in
            sum + expense.cost
        }
        let totalCardAndProductProfit = cardsProfit + productsProfit
        let finalProfit = totalCardAndProductProfit - expensesCost
        return finalProfit
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                VStack(alignment: .leading, spacing: 4) {
                    Text("Archived")
                        .font(.manrope(24, weight: .bold))
                    Text("Total Profit: $\(totalProfit, specifier: "%.2f")")
                        .font(.manrope(15, weight: .medium))
                        .foregroundColor(totalProfit >= 0 ? .themeGold : .themeLoss)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)
                .padding(.top, 8)
                .background(Color.themeBackground)
                
                contentView
            }
                .background(Color.themeBackground)
                .navigationTitle("")
                .navigationBarTitleDisplayMode(.inline)
                .tint(.themeGold)
                .toolbar {
                    toolbarContent
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
    
    @ViewBuilder
    private var contentView: some View {
        if !hasAnyArchivedItems {
            emptyStateView
        } else {
            archiveListView
        }
    }
    
    private var emptyStateView: some View {
        EmptyStateView(
            icon: "archivebox",
            title: "No archived items",
            subtitle: "Items you sold will appear here"
        )
    }
    
    private var archiveListView: some View {
        ScrollViewReader { scrollProxy in
        ZStack(alignment: .bottomTrailing) {
        List {
            // Search
            Section {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.themeSecondaryText)
                    TextField("Search archive", text: $searchText)
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
            .id("archivedTop")

            
            actionButtonsSection
            
            if cards.isEmpty && sealedProducts.isEmpty && filteredMiscExpenses.isEmpty {
                noResultsSection
            }
            
            if !cards.isEmpty {
                cardsSection
            }
            
            if !sealedProducts.isEmpty {
                sealedProductsSection
            }
            
            if !filteredMiscExpenses.isEmpty {
                miscExpensesSection
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
            selectedExpenses.removeAll()
            showingFilters = false
            filterItemType = [.cards, .sealedProducts, .miscExpenses]
            filterConditions = []
            useBuyPriceFilter = false
            minBuyPrice = 0
            maxBuyPrice = 1000
            useProfitFilter = false
            minProfit = -500
            maxProfit = 500
            useDateFilter = false
            startDate = Calendar.current.date(byAdding: .month, value: -1, to: Date()) ?? Date()
            endDate = Date()
            sortOption = .date
            sortAscending = false
        }
        
        // Scroll to top button
        Button {
            withAnimation {
                scrollProxy.scrollTo("archivedTop", anchor: .top)
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
    
    private var actionButtonsSection: some View {
        Section {
            HStack(spacing: 12) {
                selectButton
                filterButton
                sortButton
            }
            .listRowInsets(EdgeInsets())
            .listRowBackground(Color.clear)
        }
    }
    
    private var selectButton: some View {
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
    }
    
    private var filterButton: some View {
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
    }
    
    private var sortButton: some View {
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
    
    private var noResultsSection: some View {
        NoResultsView()
    }
    
    private var cardsSection: some View {
        Section {
            ForEach(cards) { card in
                InventoryCardRow(
                    card: card,
                    isMultiSelectMode: isMultiSelectMode,
                    isSelected: selectedCards.contains(card.id),
                    showProfit: true,
                    onTap: { handleCardTap(card) },
                    onDelete: { modelContext.delete(card) },
                    onEdit: { selectedCard = card }
                )
                .listRowBackground(Color.themeRowBackground)
            }
        } header: {
            Text("Cards")
                .textCase(nil)
        }
    }
    
    private var sealedProductsSection: some View {
        Section {
            ForEach(sealedProducts) { product in
                InventorySealedProductRow(
                    product: product,
                    isMultiSelectMode: isMultiSelectMode,
                    isSelected: selectedProducts.contains(product.id),
                    showProfit: true,
                    onTap: { handleProductTap(product) },
                    onDelete: { modelContext.delete(product) },
                    onEdit: { selectedProduct = product }
                )
                .listRowBackground(Color.themeRowBackground)
            }
        } header: {
            Text("Sealed Products")
                .textCase(nil)
        }
    }
    
    private var miscExpensesSection: some View {
        Section {
            ForEach(filteredMiscExpenses) { expense in
                InventoryMiscExpenseRow(
                    expense: expense,
                    isMultiSelectMode: isMultiSelectMode,
                    isSelected: selectedExpenses.contains(expense.id),
                    onTap: { handleExpenseTap(expense) },
                    onDelete: { modelContext.delete(expense) },
                    onEdit: { selectedExpense = expense }
                )
                .listRowBackground(Color.themeRowBackground)
            }
        } header: {
            Text("Misc Expenses")
                .textCase(nil)
        }
    }
    
    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
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
                .disabled(selectedCards.isEmpty && selectedProducts.isEmpty && selectedExpenses.isEmpty)
            }
        }
    }
    
    private func handleCardTap(_ card: Cards) {
        if isMultiSelectMode {
            if selectedCards.contains(card.id) {
                selectedCards.remove(card.id)
            } else {
                selectedCards.insert(card.id)
            }
        } else {
            selectedCard = card
        }
    }
    
    private func handleProductTap(_ product: SealedProduct) {
        if isMultiSelectMode {
            if selectedProducts.contains(product.id) {
                selectedProducts.remove(product.id)
            } else {
                selectedProducts.insert(product.id)
            }
        } else {
            selectedProduct = product
        }
    }
    
    private func handleExpenseTap(_ expense: MiscExpense) {
        if isMultiSelectMode {
            if selectedExpenses.contains(expense.id) {
                selectedExpenses.remove(expense.id)
            } else {
                selectedExpenses.insert(expense.id)
            }
        } else {
            selectedExpense = expense
        }
    }
}

extension ArchivedView {
    
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
                    .listRowBackground(Color.themeRowBackground)
                }
                
                Section {
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
                                if conditions.contains(condition) {
                                    conditions.remove(condition)
                                } else {
                                    conditions.insert(condition)
                                }
                            } label: {
                                Text(condition)
                                    .font(.manrope(.caption, weight: .medium))
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 8)
                                    .background(conditions.contains(condition) ? Color.themeGold : Color.gray.opacity(0.2))
                                    .foregroundColor(conditions.contains(condition) ? .white : .themePrimaryText)
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
                    Toggle("Filter by Buy Price", isOn: $useBuyPriceFilter)
                        .listRowBackground(Color.themeRowBackground)
                    
                    if useBuyPriceFilter {
                        VStack(alignment: .leading, spacing: 16) {
                            HStack(spacing: 16) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Min")
                                        .font(.manrope(.caption, weight: .medium))
                                        .foregroundColor(.themeSecondaryText)
                                    HStack(spacing: 4) {
                                        Text("$")
                                            .foregroundColor(.themeSecondaryText)
                                        TextField("0", value: $minBuyPrice, format: .number.precision(.fractionLength(0)))
                                            .keyboardType(.numberPad)
                                            .textFieldStyle(.roundedBorder)
                                    }
                                }
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Max")
                                        .font(.manrope(.caption, weight: .medium))
                                        .foregroundColor(.themeSecondaryText)
                                    HStack(spacing: 4) {
                                        Text("$")
                                            .foregroundColor(.themeSecondaryText)
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
                        .listRowBackground(Color.themeRowBackground)
                    }
                }
                
                Section {
                    Toggle("Filter by Profit", isOn: $useProfitFilter)
                        .listRowBackground(Color.themeRowBackground)
                    
                    if useProfitFilter {
                        VStack(alignment: .leading, spacing: 16) {
                            HStack(spacing: 16) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Min")
                                        .font(.manrope(.caption, weight: .medium))
                                        .foregroundColor(.themeSecondaryText)
                                    HStack(spacing: 4) {
                                        Text("$")
                                            .foregroundColor(.themeSecondaryText)
                                        TextField("-500", value: $minProfit, format: .number.precision(.fractionLength(0)))
                                            .keyboardType(.numberPad)
                                            .textFieldStyle(.roundedBorder)
                                    }
                                }
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Max")
                                        .font(.manrope(.caption, weight: .medium))
                                        .foregroundColor(.themeSecondaryText)
                                    HStack(spacing: 4) {
                                        Text("$")
                                            .foregroundColor(.themeSecondaryText)
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
                        .listRowBackground(Color.themeRowBackground)
                    }
                }
                
                Section {
                    Toggle("Filter by Date Range", isOn: $useDateFilter)
                        .listRowBackground(Color.themeRowBackground)
                    
                    if useDateFilter {
                        HStack(spacing: 12) {
                            DatePicker("", selection: $startDate, displayedComponents: .date)
                                .labelsHidden()
                                .environment(\.colorScheme, .dark)
                            
                            Text("to")
                                .foregroundColor(.themeSecondaryText)
                            
                            DatePicker("", selection: $endDate, displayedComponents: .date)
                                .labelsHidden()
                                .environment(\.colorScheme, .dark)
                        }
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
        }
    }
}

#Preview {
    ArchivedView(selectedTab: .constant(3))
        .modelContainer(for: [Cards.self, SealedProduct.self, MiscExpense.self], inMemory: true)
}

