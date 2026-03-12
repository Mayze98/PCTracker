//
//  HomeView.swift
//  PCTracker
//
//  Created by John on 2026-02-26.
//
import SwiftData
import SwiftUI
import Charts

// MARK: - Chart Data
struct ProfitByMonth: Identifiable {
    let id = UUID()
    let month: Date
    let profit: Double
}

// MARK: - Home View
struct HomeView: View {
    @Query private var allCards: [Cards]
    @Query private var allSealedProducts: [SealedProduct]
    @Query private var miscExpenses: [MiscExpense]
    
    @State private var selectedMonth: Date?

    // Filter out items that have been sold (have a salePrice)
    private var soldCards: [Cards] {
        allCards.filter { $0.salePrice != nil }
    }
    
    private var soldSealedProducts: [SealedProduct] {
        allSealedProducts.filter { $0.salePrice != nil }
    }
    
    // Filter out items that have not been sold (don't a salePrice)
    private var inventoryCards: [Cards] {
        allCards.filter { $0.salePrice == nil }
    }
    
    private var inventorySealedProducts: [SealedProduct] {
        allSealedProducts.filter { $0.salePrice == nil }
    }
    
    
    private var totalCards: Double {
        inventoryCards.reduce(0.0) { $0 + $1.buyPrice }
    }
    
    private var totalProducts: Double {
        inventorySealedProducts.reduce(0.0) { $0 + $1.buyPrice }
    }
    
    private var expenseCost: Double {
        miscExpenses.reduce(0.0) { $0 + $1.cost }
    }
    
    private var totalSales: Double {
        let cardsSale = soldCards.reduce(0.0) { $0 + ($1.salePrice ?? 0) }
        let productsSale = soldSealedProducts.reduce(0.0) { $0 + ($1.salePrice ?? 0) }
        return cardsSale + productsSale
    }
    
    private var totalProfit: Double {
        let cardsProfit = soldCards.reduce(0.0) { $0 + ($1.profit ?? 0) }
        let productsProfit = soldSealedProducts.reduce(0.0) { $0 + ($1.profit ?? 0) }
        return cardsProfit + productsProfit
    }
    
    private var totalExpenses: Double {
        let cardsExpense = soldCards.reduce(0.0) { $0 + ($1.buyPrice) }
        let productsExpense = soldSealedProducts.reduce(0.0) { $0 + ($1.buyPrice) }
        let expensesCost = miscExpenses.reduce(0.0) { $0 + $1.cost }
        return cardsExpense + productsExpense + expensesCost
    }
    
    // Chart data grouped by month
    private var profitByMonth: [ProfitByMonth] {
        let calendar = Calendar.current
        var monthlyProfits: [Date: Double] = [:]
        
        // Group sold cards by month
        for card in soldCards {
            guard let profit = card.profit else { continue }
            let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: card.purchaseDate))!
            monthlyProfits[monthStart, default: 0] += profit
        }
        
        // Group sold products by month
        for product in soldSealedProducts {
            guard let profit = product.profit else { continue }
            let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: product.purchaseDate))!
            monthlyProfits[monthStart, default: 0] += profit
        }
        
        // Subtract expenses by month
        for expense in miscExpenses {
            let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: expense.purchaseDate))!
            monthlyProfits[monthStart, default: 0] -= expense.cost
        }
        
        return monthlyProfits.map { ProfitByMonth(month: $0.key, profit: $0.value) }
            .sorted { $0.month < $1.month }
    }
    
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Header
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("PCTracker")
                        .font(.system(size: 34, weight: .bold))
                    Image("gold_star-nobg")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 60)

                }
//                Text("\(inventoryCards.count) cards in collection")
//                    .font(.system(size: 17))
//                    .foregroundColor(.secondary)
            }
            .padding(.horizontal)
            .padding(.top, 8)
            
            // Stats Grid
            VStack(spacing: 12) {
                HStack(spacing: 12) {
                    // Total Cards
                    StatCard(
                        icon: "lanyardcard",
                        iconColor: .blue,
                        title: "Cards",
                        value: "\(inventoryCards.count)",
                        valueFontSize: 18
                    )
                    // Sealed
                    StatCard(
                        icon: "cube.box",
                        iconColor: .yellow,
                        title: "Sealed",
                        value: "\(inventorySealedProducts.count)",
                        valueFontSize: 18
                    )


                }
                HStack(spacing: 12) {
                    // Inventory
                    StatCard(
                        icon: "storefront",
                        iconColor: .orange,
                        title: "Inventory",
                        value: String(format: "$%.1f", totalCards + totalProducts),
                        valueFontSize: 18
                    )
                    // Profit
                    StatCard(
                        icon: "dollarsign",
                        iconColor: .green,
                        title: "Net Profit",
                        value: String(format: "$%.1f", totalProfit - expenseCost),
                        valueFontSize: 18
                    )
                }
            }
            .padding(.horizontal)
            
            HStack {
                StatCard(
                    icon: "chart.line.uptrend.xyaxis",
                    iconColor: .green,
                    title: "Return on Investment",
                    value: totalExpenses > 0 ? String(format: "%.2f%%", ((totalSales - totalExpenses)/totalExpenses) * 100) : "0.00%"
                )
            }
            .padding(.horizontal)
            
            // Realized Profit Chart
            VStack(alignment: .leading, spacing: 12) {
                Text("Realized Profit by Month")
                    .font(.system(size: 20, weight: .semibold))
                    .padding(.horizontal)
                
                if profitByMonth.isEmpty {
                    // Empty state for chart
                    VStack(spacing: 16) {
                        Image(systemName: "chart.bar")
                            .font(.system(size: 40))
                            .foregroundColor(.secondary)
                        Text("No realized profit yet")
                            .font(.system(size: 17))
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 200)
                } else {
                    Chart(profitByMonth) { item in
                        BarMark(
                            x: .value("Month", item.month, unit: .month),
                            y: .value("Profit", item.profit)
                        )
                        .foregroundStyle(item.profit >= 0 ? Color.green : Color.red)
                        .cornerRadius(6)
                        .opacity(selectedMonth == nil || Calendar.current.isDate(selectedMonth!, equalTo: item.month, toGranularity: .month) ? 1.0 : 0.3)
                    }
                    .chartXAxis {
                        AxisMarks(values: .stride(by: .month)) { value in
                            if let date = value.as(Date.self) {
                                AxisValueLabel {
                                    Text(date, format: .dateTime.month(.abbreviated))
                                }
                            }
                        }
                    }
                    .chartYAxis {
                        AxisMarks(position: .leading) { value in
                            AxisValueLabel {
                                if let profit = value.as(Double.self) {
                                    Text("$\(profit, specifier: "%.0f")")
                                }
                            }
                        }
                    }
                    .chartXSelection(value: $selectedMonth)
                    .frame(height: 200)
                    .padding(.horizontal)
                    
                    // Display selected month profit
                    if let selectedMonth = selectedMonth,
                       let selectedData = profitByMonth.first(where: { Calendar.current.isDate($0.month, equalTo: selectedMonth, toGranularity: .month) }) {
                        VStack(spacing: 8) {
                            Text(selectedData.month, format: .dateTime.month(.wide).year())
                                .font(.system(size: 16, weight: .semibold))
                            HStack(spacing: 4) {
                                Text("Profit:")
                                    .foregroundColor(.secondary)
                                Text(selectedData.profit >= 0 ? "+$\(selectedData.profit, specifier: "%.2f")" : "-$\(abs(selectedData.profit), specifier: "%.2f")")
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(selectedData.profit >= 0 ? .green : .red)
                            }
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color(.secondarySystemGroupedBackground))
                        .cornerRadius(12)
                        .padding(.horizontal)
                        .transition(.opacity)
                    }
                }
            }
            .padding(.vertical)
            .background(Color(.systemBackground))
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color(.separator), lineWidth: 1)
            )
            .padding(.horizontal)
            .contentShape(Rectangle())
            .onTapGesture {
                // Tap outside the chart to deselect
                withAnimation {
                    selectedMonth = nil
                }
            }
            
            Spacer()
        }
        .background(Color(.systemGroupedBackground))
    }
}

#Preview {
    HomeView()
        .modelContainer(for: [Cards.self, SealedProduct.self, MiscExpense.self], inMemory: true)
}
