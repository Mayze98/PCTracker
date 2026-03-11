//
//  SharedComponents.swift
//  PCTracker
//
//  Shared reusable components
//

import SwiftUI
import SwiftData

// MARK: - Shared Row Views

struct InventoryCardRow: View {
    let card: Cards
    let isMultiSelectMode: Bool
    let isSelected: Bool
    let showProfit: Bool // true for archived, false for inventory
    let onTap: () -> Void
    let onDelete: () -> Void
    let onEdit: () -> Void
    
    var body: some View {
        HStack {
            if isMultiSelectMode {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? .blue : .gray)
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
                
                if let number = card.number {
                    Text("#\(number)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Text("Buy: $\(card.buyPrice, format: .number.precision(.fractionLength(2)))")
                        .font(.subheadline)
                    
                    if showProfit, let salePrice = card.salePrice {
                        Text("Sale: $\(salePrice, format: .number.precision(.fractionLength(2)))")
                            .font(.subheadline)
                        
                        if let profit = card.profit {
                            Text("\(profit >= 0 ? "+" : "")$\(profit, format: .number.precision(.fractionLength(2)))")
                                .font(.subheadline)
                                .foregroundColor(profit >= 0 ? .green : .red)
                            
                            if let roi = card.roi {
                                Text("(\(roi >= 0 ? "+" : "")\(roi, specifier: "%.1f")%)")
                                    .font(.subheadline)
                                    .foregroundColor(roi >= 0 ? .green : .red)
                            }
                        }
                    } else {
                        Text("\(card.purchaseDate, format: .dateTime.month().day().year())")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .onTapGesture(perform: onTap)
        .contextMenu {
            if !isMultiSelectMode {
                Button {
                    onEdit()
                } label: {
                    Label("Edit Details", systemImage: "pencil")
                }
                
                Divider()
                
                Button(role: .destructive) {
                    onDelete()
                } label: {
                    Label("Delete", systemImage: "trash")
                }
            }
        }
    }
}

struct InventorySealedProductRow: View {
    let product: SealedProduct
    let isMultiSelectMode: Bool
    let isSelected: Bool
    let showProfit: Bool
    let onTap: () -> Void
    let onDelete: () -> Void
    let onEdit: () -> Void
    
    var body: some View {
        HStack {
            if isMultiSelectMode {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? .blue : .gray)
                    .imageScale(.large)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(product.name)
                    .font(.headline)
                
                if let expansion = product.expansion {
                    Text(expansion)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Text("Buy: $\(product.buyPrice, format: .number.precision(.fractionLength(2)))")
                        .font(.subheadline)
                    
                    if showProfit, let salePrice = product.salePrice {
                        Text("Sale: $\(salePrice, format: .number.precision(.fractionLength(2)))")
                            .font(.subheadline)
                        
                        if let profit = product.profit {
                            Text("\(profit >= 0 ? "+" : "")$\(profit, format: .number.precision(.fractionLength(2)))")
                                .font(.subheadline)
                                .foregroundColor(profit >= 0 ? .green : .red)
                            
                            if let roi = product.roi {
                                Text("(\(roi >= 0 ? "+" : "")\(roi, specifier: "%.1f")%)")
                                    .font(.subheadline)
                                    .foregroundColor(roi >= 0 ? .green : .red)
                            }
                        }
                    } else {
                        Text("\(product.purchaseDate, format: .dateTime.month().day().year())")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .onTapGesture(perform: onTap)
        .contextMenu {
            if !isMultiSelectMode {
                Button {
                    onEdit()
                } label: {
                    Label("Edit Details", systemImage: "pencil")
                }
                
                Divider()
                
                Button(role: .destructive) {
                    onDelete()
                } label: {
                    Label("Delete", systemImage: "trash")
                }
            }
        }
    }
}

struct InventoryMiscExpenseRow: View {
    let expense: MiscExpense
    let isMultiSelectMode: Bool
    let isSelected: Bool
    let onTap: () -> Void
    let onDelete: () -> Void
    let onEdit: () -> Void
    
    var body: some View {
        HStack {
            if isMultiSelectMode {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? .blue : .gray)
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
                    Text("Cost: $\(expense.cost, format: .number.precision(.fractionLength(2)))")
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
        .onTapGesture(perform: onTap)
        .contextMenu {
            if !isMultiSelectMode {
                Button {
                    onEdit()
                } label: {
                    Label("Edit Details", systemImage: "pencil")
                }
                
                Divider()
                
                Button(role: .destructive) {
                    onDelete()
                } label: {
                    Label("Delete", systemImage: "trash")
                }
            }
        }
    }
}

// MARK: - Action Buttons

struct ActionButtonsBar: View {
    let activeFilterCount: Int
    let onSelectTapped: () -> Void
    let onFilterTapped: () -> Void
    let sortOption: Binding<String>
    let sortAscending: Binding<Bool>
    let sortOptions: [String]
    let onResetSort: () -> Void
    
    var body: some View {
        Section {
            HStack(spacing: 8) {
                selectButton
                filterButton
                sortButton
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .listRowInsets(EdgeInsets())
            .listRowBackground(Color.clear)
        }
    }
    
    private var selectButton: some View {
        Button(action: onSelectTapped) {
            HStack(spacing: 4) {
                Image(systemName: "checkmark.circle")
                    .font(.system(size: 14, weight: .medium))
                Text("Select")
                    .font(.system(size: 13, weight: .medium))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .padding(.horizontal, 8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.adaptiveBlueOrange.opacity(0.08))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.adaptiveBlueOrange.opacity(0.2), lineWidth: 1)
            )
            .foregroundColor(.adaptiveBlueOrange)
        }
        .buttonStyle(.plain)
    }
    
    private var filterButton: some View {
        Button(action: onFilterTapped) {
            HStack(spacing: 4) {
                Image(systemName: activeFilterCount > 0 ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
                    .font(.system(size: 14, weight: .medium))
                Text("Filter")
                    .font(.system(size: 13, weight: .medium))
                if activeFilterCount > 0 {
                    Text("\(activeFilterCount)")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.white)
                        .frame(minWidth: 16, minHeight: 16)
                        .background(Circle().fill(Color.adaptiveBlueOrange))
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .padding(.horizontal, 8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(activeFilterCount > 0 ? Color.adaptiveBlueOrange.opacity(0.12) : Color.adaptiveBlueOrange.opacity(0.08))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.adaptiveBlueOrange.opacity(activeFilterCount > 0 ? 0.4 : 0.2), lineWidth: 1)
            )
            .foregroundColor(.adaptiveBlueOrange)
        }
        .buttonStyle(.plain)
    }
    
    private var sortButton: some View {
        Menu {
            Picker("Sort By", selection: sortOption) {
                ForEach(sortOptions, id: \.self) { option in
                    Text(option).tag(option)
                }
            }
            
            Divider()
            
            Button {
                sortAscending.wrappedValue.toggle()
            } label: {
                Label(
                    sortAscending.wrappedValue ? "Ascending" : "Descending",
                    systemImage: sortAscending.wrappedValue ? "arrow.up" : "arrow.down"
                )
            }
            
            Divider()
            
            Button(role: .destructive, action: onResetSort) {
                Label("Reset Sort", systemImage: "arrow.clockwise")
            }
        } label: {
            HStack(spacing: 4) {
                Image(systemName: "arrow.up.arrow.down.circle")
                    .font(.system(size: 14, weight: .medium))
                Text("Sort")
                    .font(.system(size: 13, weight: .medium))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .padding(.horizontal, 8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.adaptiveBlueOrange.opacity(0.08))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.adaptiveBlueOrange.opacity(0.2), lineWidth: 1)
            )
            .foregroundColor(.adaptiveBlueOrange)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Range Slider (Shared)

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
                
                // Active track
                RoundedRectangle(cornerRadius: trackHeight / 2)
                    .fill(Color.blue)
                    .frame(width: max(0, maxOffset - minOffset), height: trackHeight)
                    .offset(x: minOffset)
                
                // Min thumb
                thumbView
                    .offset(x: minOffset - thumbSize / 2)
                    .gesture(minDragGesture(geometry: geometry))
                
                // Max thumb
                thumbView
                    .offset(x: maxOffset - thumbSize / 2)
                    .gesture(maxDragGesture(geometry: geometry))
            }
            .frame(height: thumbSize)
            .onAppear { updateOffsets(width: geometry.size.width) }
            .onChange(of: geometry.size.width) { _, newWidth in updateOffsets(width: newWidth) }
            .onChange(of: minValue) { _, _ in updateOffsets(width: geometry.size.width) }
            .onChange(of: maxValue) { _, _ in updateOffsets(width: geometry.size.width) }
        }
    }
    
    private var thumbView: some View {
        Circle()
            .fill(Color.white)
            .frame(width: thumbSize, height: thumbSize)
            .shadow(color: .black.opacity(0.2), radius: 2, x: 0, y: 1)
            .overlay(Circle().stroke(Color.blue, lineWidth: 2))
    }
    
    private func minDragGesture(geometry: GeometryProxy) -> some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                let newOffset = max(0, min(maxOffset - thumbSize, value.location.x - thumbSize / 2))
                minOffset = newOffset
                let percentage = newOffset / (geometry.size.width - thumbSize)
                let range = bounds.upperBound - bounds.lowerBound
                let rawValue = bounds.lowerBound + (range * Double(percentage))
                minValue = (rawValue / step).rounded() * step
            }
    }
    
    private func maxDragGesture(geometry: GeometryProxy) -> some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                let newOffset = max(minOffset + thumbSize, min(geometry.size.width, value.location.x - thumbSize / 2))
                maxOffset = newOffset
                let percentage = newOffset / (geometry.size.width - thumbSize)
                let range = bounds.upperBound - bounds.lowerBound
                let rawValue = bounds.lowerBound + (range * Double(percentage))
                maxValue = (rawValue / step).rounded() * step
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

// MARK: - Empty State Views

struct EmptyStateView: View {
    let icon: String
    let title: String
    let subtitle: String
    
    var body: some View {
        VStack {
            Spacer()
            Image(systemName: icon)
                .font(.system(size: 60))
                .foregroundColor(.secondary)
                .padding(.bottom, 16)
            Text(title)
                .font(.system(size: 22, weight: .semibold))
            Text(subtitle)
                .foregroundColor(.secondary)
                .padding(.top, 4)
            Spacer()
        }
    }
}

struct NoResultsView: View {
    var body: some View {
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
}
// MARK: - Sorting Extensions

extension Array where Element == Cards {
    func sorted(by option: String, ascending: Bool) -> [Cards] {
        sorted { card1, card2 in
            let result: Bool
            switch option {
            case "Date":
                result = card1.purchaseDate < card2.purchaseDate
            case "Profit":
                result = (card1.profit ?? 0) < (card2.profit ?? 0)
            case "Buy Price":
                result = card1.buyPrice < card2.buyPrice
            case "Sale Price":
                result = (card1.salePrice ?? 0) < (card2.salePrice ?? 0)
            case "Name":
                result = card1.name < card2.name
            default:
                result = card1.purchaseDate < card2.purchaseDate
            }
            return ascending ? result : !result
        }
    }
}

extension Array where Element == SealedProduct {
    func sorted(by option: String, ascending: Bool) -> [SealedProduct] {
        sorted { product1, product2 in
            let result: Bool
            switch option {
            case "Date":
                result = product1.purchaseDate < product2.purchaseDate
            case "Profit":
                result = (product1.profit ?? 0) < (product2.profit ?? 0)
            case "Buy Price":
                result = product1.buyPrice < product2.buyPrice
            case "Sale Price":
                result = (product1.salePrice ?? 0) < (product2.salePrice ?? 0)
            case "Name":
                result = product1.name < product2.name
            default:
                result = product1.purchaseDate < product2.purchaseDate
            }
            return ascending ? result : !result
        }
    }
}

extension Array where Element == MiscExpense {
    func sorted(by option: String, ascending: Bool) -> [MiscExpense] {
        sorted { expense1, expense2 in
            let result: Bool
            switch option {
            case "Date":
                result = expense1.purchaseDate < expense2.purchaseDate
            case "Profit":
                // For expenses, treat cost as negative profit
                result = -expense1.cost < -expense2.cost
            case "Buy Price", "Sale Price":
                // For expenses, use cost for both buy and sale price sorting
                result = expense1.cost < expense2.cost
            case "Name":
                result = expense1.itemDescription < expense2.itemDescription
            default:
                result = expense1.purchaseDate < expense2.purchaseDate
            }
            return ascending ? result : !result
        }
    }
}

