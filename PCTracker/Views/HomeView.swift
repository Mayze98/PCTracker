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
    @Binding var selectedTab: Int
    
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
        let expensesCost = miscExpenses.reduce(0.0) { $0 + $1.cost }
        return cardsProfit + productsProfit - expensesCost
    }
    
    private var totalExpenses: Double {
        let cardsExpense = soldCards.reduce(0.0) { $0 + ($1.buyPrice) }
        let productsExpense = soldSealedProducts.reduce(0.0) { $0 + ($1.buyPrice) }
        let expensesCost = miscExpenses.reduce(0.0) { $0 + $1.cost }
        return cardsExpense + productsExpense + expensesCost
    }
    
    // Calculate net profit for a given month (same logic as netProfitMonthChange)
    private func netProfitForMonth(startOfMonth: Date, endOfMonth: Date) -> Double {
        var profit: Double = 0
        for card in soldCards {
            let dateToCheck = card.saleDate ?? card.purchaseDate
            if dateToCheck >= startOfMonth && dateToCheck <= endOfMonth {
                profit += (card.profit ?? 0)
            }
        }
        for product in soldSealedProducts {
            let dateToCheck = product.saleDate ?? product.purchaseDate
            if dateToCheck >= startOfMonth && dateToCheck <= endOfMonth {
                profit += (product.profit ?? 0)
            }
        }
        for expense in miscExpenses {
            if expense.purchaseDate >= startOfMonth && expense.purchaseDate <= endOfMonth {
                profit -= expense.cost
            }
        }
        return profit
    }
    
    // Chart data grouped by month — uses the same calculation as netProfitMonthChange
    private var profitByMonth: [ProfitByMonth] {
        let calendar = Calendar.current
        
        // Collect all relevant dates to determine which months have activity
        var monthStarts: Set<Date> = []
        for card in soldCards {
            let dateToUse = card.saleDate ?? card.purchaseDate
            let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: dateToUse))!
            monthStarts.insert(monthStart)
        }
        for product in soldSealedProducts {
            let dateToUse = product.saleDate ?? product.purchaseDate
            let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: dateToUse))!
            monthStarts.insert(monthStart)
        }
        for expense in miscExpenses {
            let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: expense.purchaseDate))!
            monthStarts.insert(monthStart)
        }
        
        // Calculate profit for each month using full month range
        return monthStarts.map { monthStart in
            let endOfMonth = calendar.date(byAdding: DateComponents(month: 1, second: -1), to: monthStart)!
            let profit = netProfitForMonth(startOfMonth: monthStart, endOfMonth: endOfMonth)
            return ProfitByMonth(month: monthStart, profit: profit)
        }
        .filter { $0.profit != 0 }
        .sorted { $0.month < $1.month }
    }
    
    
    private var cardsMonthChange: String {
        let calendar = Calendar.current
        let now = Date()
        
        // Get start of current month and end of today
        let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: now))!
        let endOfToday = calendar.date(bySettingHour: 23, minute: 59, second: 59, of: now)!
        
        // Count items added in current month to date
        let count = inventoryCards.filter { $0.purchaseDate >= startOfMonth && $0.purchaseDate <= endOfToday }.count
        
        let sign = count > 0 ? "+" : ""
        return "\(sign)\(count)"
    }
    
    private var sealedMonthChange: String {
        let calendar = Calendar.current
        let now = Date()
        
        // Get start of current month and end of today
        let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: now))!
        let endOfToday = calendar.date(bySettingHour: 23, minute: 59, second: 59, of: now)!
        
        // Count items added in current month to date
        let count = inventorySealedProducts.filter { $0.purchaseDate >= startOfMonth && $0.purchaseDate <= endOfToday }.count
        
        let sign = count > 0 ? "+" : ""
        return "\(sign)\(count)"
    }
    
    private var inventoryMonthChange: String {
        let calendar = Calendar.current
        let now = Date()
        
        // Get start of current month and end of today
        let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: now))!
        let endOfToday = calendar.date(bySettingHour: 23, minute: 59, second: 59, of: now)!
        
        // Calculate value added in current month to date
        var value: Double = 0
        for card in inventoryCards {
            if card.purchaseDate >= startOfMonth && card.purchaseDate <= endOfToday {
                value += card.buyPrice
            }
        }
        for product in inventorySealedProducts {
            if product.purchaseDate >= startOfMonth && product.purchaseDate <= endOfToday {
                value += product.buyPrice
            }
        }
        
        let sign = value > 0 ? "+" : ""
        return "\(sign)$\(String(format: "%.1f", value))"
    }
    
    private var netProfitMonthChange: String {
        let calendar = Calendar.current
        let now = Date()
        
        let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: now))!
        let endOfMonth = calendar.date(byAdding: DateComponents(month: 1, second: -1), to: startOfMonth)!
        
        let profit = netProfitForMonth(startOfMonth: startOfMonth, endOfMonth: endOfMonth)
        
        let sign = profit > 0 ? "+" : ""
        return "\(sign)$\(String(format: "%.1f", profit))"
    }
    
    private var yearToDateROI: String {
        let calendar = Calendar.current
        let now = Date()
        let startOfYear = calendar.date(from: calendar.dateComponents([.year], from: now))!
        
        var ytdSales: Double = 0
        var ytdExpenses: Double = 0
        
        // Use sale date for sold cards
        for card in soldCards {
            let dateToCheck = card.saleDate ?? card.purchaseDate
            if dateToCheck >= startOfYear {
                ytdSales += (card.salePrice ?? 0)
                ytdExpenses += card.buyPrice
            }
        }
        
        // Use sale date for sold products
        for product in soldSealedProducts {
            let dateToCheck = product.saleDate ?? product.purchaseDate
            if dateToCheck >= startOfYear {
                ytdSales += (product.salePrice ?? 0)
                ytdExpenses += product.buyPrice
            }
        }
        
        for expense in miscExpenses where expense.purchaseDate >= startOfYear {
            ytdExpenses += expense.cost
        }
        
        if ytdExpenses > 0 {
            let roi = ((ytdSales - ytdExpenses) / ytdExpenses) * 100
            return String(format: "%.2f%%", roi)
        }
        return "0.00%"
    }
    
    private var totalSoldCount: Int {
        soldCards.count + soldSealedProducts.count
    }
    
    private var soldMonthChange: String {
        let calendar = Calendar.current
        let now = Date()
        let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: now))!
        let endOfToday = calendar.date(bySettingHour: 23, minute: 59, second: 59, of: now)!
        
        let count = soldCards.filter {
            let d = $0.saleDate ?? $0.purchaseDate
            return d >= startOfMonth && d <= endOfToday
        }.count + soldSealedProducts.filter {
            let d = $0.saleDate ?? $0.purchaseDate
            return d >= startOfMonth && d <= endOfToday
        }.count
        
        let sign = count > 0 ? "+" : ""
        return "\(sign)\(count)"
    }
    
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("PCTracker")
                        .font(.manrope(24, weight: .bold))
                    Image("gold_star-nobg")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 60)

                }
//                Text("\(inventoryCards.count) cards in collection")
//                    .font(.system(size: 17))
//                    .foregroundColor(.themeSecondaryText)
            }
            .padding(.horizontal)
            .padding(.top, 8)
            
            // Stats Grid
            VStack(spacing: 12) {
                HStack(spacing: 12) {
                    // Total Cards
                    FlippableStatCard(
                        icon: "lanyardcard",
                        iconColor: .themeGold,
                        title: "Cards",
                        value: "\(inventoryCards.count)",
                        backTitle: "Monthly",
                        backValue: cardsMonthChange,
                        backIcon: "calendar",
                        valueFontSize: 18,
                        selectedTab: $selectedTab
                    )
                    // Sealed
                    FlippableStatCard(
                        icon: "cube.box",
                        iconColor: .themeGold,
                        title: "Sealed",
                        value: "\(inventorySealedProducts.count)",
                        backTitle: "Monthly",
                        backValue: sealedMonthChange,
                        backIcon: "calendar",
                        valueFontSize: 18,
                        selectedTab: $selectedTab
                    )
                }
                HStack(spacing: 12) {
                    // Inventory
                    FlippableStatCard(
                        icon: "storefront",
                        iconColor: .themeGold,
                        title: "Inventory",
                        value: String(format: "$%.1f", totalCards + totalProducts),
                        backTitle: "Monthly",
                        backValue: inventoryMonthChange,
                        backIcon: "calendar",
                        valueFontSize: 18,
                        selectedTab: $selectedTab
                    )
                    // Total Sold
                    FlippableStatCard(
                        icon: "shippingbox",
                        iconColor: .themeGold,
                        title: "Total Sold",
                        value: "\(totalSoldCount)",
                        backTitle: "Monthly",
                        backValue: soldMonthChange,
                        backIcon: "calendar",
                        valueFontSize: 18,
                        selectedTab: $selectedTab
                    )
                }
            }
            .padding(.horizontal)
            
            HStack(spacing: 12) {
                FlippableStatCard(
                    icon: "dollarsign",
                    iconColor: .themeGold,
                    title: "Net Profit",
                    value: String(format: "$%.1f", totalProfit),
                    backTitle: "Monthly",
                    backValue: netProfitMonthChange,
                    backIcon: "calendar",
                    valueFontSize: 18,
                    selectedTab: $selectedTab
                )
                FlippableStatCard(
                    icon: "chart.line.uptrend.xyaxis",
                    iconColor: .themeGold,
                    title: "ROI",
                    value: totalExpenses > 0 ? String(format: "%.2f%%", ((totalSales - totalExpenses)/totalExpenses) * 100) : "0.00%",
                    backTitle: "YTD ROI",
                    backValue: yearToDateROI,
                    backIcon: "calendar.badge.clock",
                    valueFontSize: 18,
                    selectedTab: $selectedTab
                )
            }
            .padding(.horizontal)
            
            // Realized Profit Chart
            VStack(alignment: .leading, spacing: 12) {
                Text("Realized Profit by Month")
                    .font(.manrope(20, weight: .semiBold))
                    .padding(.horizontal)
                
                if profitByMonth.isEmpty {
                    // Empty state for chart
                    VStack(spacing: 16) {
                        Image(systemName: "chart.bar")
                            .font(.system(size: 40))
                            .foregroundColor(.themeSecondaryText)
                        Text("No realized profit yet")
                            .font(.manrope(.body))
                            .foregroundColor(.themeSecondaryText)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 200)
                } else {
                    Chart(profitByMonth) { item in
                        BarMark(
                            x: .value("Month", item.month, unit: .month),
                            y: .value("Profit", item.profit)
                        )
                        .foregroundStyle(item.profit >= 0 ? Color.themeGold : Color.themeLoss)
                        .cornerRadius(6)
                        .opacity(selectedMonth == nil || Calendar.current.isDate(selectedMonth!, equalTo: item.month, toGranularity: .month) ? 1.0 : 0.3)
                    }
                    .chartXAxis {
                        AxisMarks(values: .stride(by: .month)) { value in
                            if let date = value.as(Date.self) {
                                AxisValueLabel {
                                    Text(date, format: .dateTime.month(.abbreviated))
                                        .foregroundStyle(.white)
                                }
                            }
                        }
                    }
                    .chartYAxis {
                        AxisMarks(position: .leading) { value in
                            AxisValueLabel {
                                if let profit = value.as(Double.self) {
                                    Text("$\(profit, specifier: "%.0f")")
                                        .foregroundStyle(.white)
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
                                .font(.manrope(16, weight: .semiBold))
                            HStack(spacing: 4) {
                                Text("Profit:")
                                    .font(.manrope(.body))
                                    .foregroundColor(.themeSecondaryText)
                                Text(selectedData.profit >= 0 ? "+$\(selectedData.profit, specifier: "%.2f")" : "-$\(abs(selectedData.profit), specifier: "%.2f")")
                                    .font(.manrope(18, weight: .bold))
                                    .foregroundColor(selectedData.profit >= 0 ? .themeGold : .themeLoss)
                            }
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.themeCardBackground)
                        .cornerRadius(12)
                        .padding(.horizontal)
                        .transition(.opacity)
                    }
                }
            }
            .padding(.vertical)
            .background(Color.themeRowBackground)
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.themeGold.opacity(0.15), lineWidth: 1)
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
        .background(Color.themeBackground)
        .onChange(of: selectedTab) { _, _ in
            selectedMonth = nil
        }
    }
}

#Preview {
    HomeView(selectedTab: .constant(0))
        .modelContainer(for: [Cards.self, SealedProduct.self, MiscExpense.self], inMemory: true)
}
