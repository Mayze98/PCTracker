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
    @AppStorage("currencyCode") private var currencyCode: String = "CAD"
    
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
        
        return CurrencyFormatter.convertedSignedString(value, code: currencyCode, minFraction: 1, maxFraction: 1)
    }
    
    private var netProfitMonthChange: String {
        let calendar = Calendar.current
        let now = Date()
        
        let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: now))!
        let endOfMonth = calendar.date(byAdding: DateComponents(month: 1, second: -1), to: startOfMonth)!
        
        let profit = netProfitForMonth(startOfMonth: startOfMonth, endOfMonth: endOfMonth)
        
        return CurrencyFormatter.convertedSignedString(profit, code: currencyCode, minFraction: 1, maxFraction: 1)
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
    
    
    // Formatted profit string
    private var formattedProfit: String {
        let absProfit = abs(totalProfit)
        if absProfit >= 1000 {
            return CurrencyFormatter.convertedString(totalProfit, code: currencyCode, minFraction: 0, maxFraction: 0)
        }
        return CurrencyFormatter.convertedString(totalProfit, code: currencyCode, minFraction: 2, maxFraction: 2)
    }
    
    private var formattedROI: String {
        totalExpenses > 0 ? String(format: "%.1f%%", ((totalSales - totalExpenses) / totalExpenses) * 100) : "0.0%"
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                HStack {
                    Text("PCTracker")
                        .font(.manrope(24, weight: .bold))
                    Image("gold_star-nobg")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 60)
                }
                .padding(.horizontal)
                .padding(.top, 8)
                
                // MARK: - Hero: Net Profit & ROI
                HStack(spacing: 12) {
                    // Net Profit hero card
                    FlippableHeroCard(
                        label: "Net Profit",
                        value: formattedProfit,
                        valueColor: totalProfit >= 0 ? .themeGold : .themeLoss,
                        monthLabel: "This month",
                        monthValue: netProfitMonthChange,
                        selectedTab: $selectedTab
                    )
                    
                    // ROI hero card
                    FlippableHeroCard(
                        label: "ROI",
                        value: formattedROI,
                        valueColor: totalExpenses > 0 && totalSales >= totalExpenses ? .themeGold : .themeLoss,
                        monthLabel: "YTD ROI",
                        monthValue: yearToDateROI,
                        selectedTab: $selectedTab
                    )
                }
                .padding(.horizontal)
                
                // MARK: - Secondary Stats (compact 2x2)
                VStack(spacing: 8) {
                    HStack(spacing: 8) {
                        CompactStatCard(
                            icon: "lanyardcard",
                            title: "Cards",
                            value: "\(inventoryCards.count)",
                            monthChange: cardsMonthChange
                        )
                        CompactStatCard(
                            icon: "cube.box",
                            title: "Sealed",
                            value: "\(inventorySealedProducts.count)",
                            monthChange: sealedMonthChange
                        )
                    }
                    HStack(spacing: 8) {
                        CompactStatCard(
                            icon: "storefront",
                            title: "Inventory",
                            value: CurrencyFormatter.convertedString(totalCards + totalProducts, code: currencyCode, minFraction: 0, maxFraction: 0),
                            monthChange: inventoryMonthChange
                        )
                        CompactStatCard(
                            icon: "shippingbox",
                            title: "Sold",
                            value: "\(totalSoldCount)",
                            monthChange: soldMonthChange
                        )
                    }
                }
                .padding(.horizontal)
                
                
                // MARK: - Realized Profit Chart
                VStack(alignment: .leading, spacing: 12) {
                    Text("Realized profit")
                        .font(.manrope(18, weight: .semiBold))
                        .padding(.horizontal)
                    
                    if profitByMonth.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "chart.bar")
                                .font(.system(size: 36))
                                .foregroundColor(.themeSecondaryText.opacity(0.4))
                            Text("No realized profit yet")
                                .font(.manrope(14))
                                .foregroundColor(.themeSecondaryText.opacity(0.6))
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 180)
                    } else {
                        Chart(profitByMonth) { item in
                            BarMark(
                                x: .value("Month", item.month, unit: .month),
                                y: .value("Profit", item.profit)
                            )
                            .foregroundStyle(item.profit >= 0 ? Color.themeGold : Color.themeLoss)
                            .cornerRadius(4)
                            .opacity(selectedMonth == nil || Calendar.current.isDate(selectedMonth!, equalTo: item.month, toGranularity: .month) ? 1.0 : 0.3)
                        }
                        .chartXAxis {
                            AxisMarks(values: .stride(by: .month)) { value in
                                if let date = value.as(Date.self) {
                                    AxisValueLabel {
                                        Text(date, format: .dateTime.month(.abbreviated))
                                            .font(.manrope(10))
                                            .foregroundStyle(Color.themeSecondaryText.opacity(0.7))
                                    }
                                }
                            }
                        }
                        .chartYAxis {
                            AxisMarks(position: .leading) { value in
                                AxisValueLabel {
                                    if let profit = value.as(Double.self) {
                                        Text(CurrencyFormatter.convertedString(profit, code: currencyCode, minFraction: 0, maxFraction: 0))
                                            .font(.manrope(10))
                                            .foregroundStyle(Color.themeSecondaryText.opacity(0.7))
                                    }
                                }
                            }
                        }
                        .chartXSelection(value: $selectedMonth)
                        .frame(height: 180)
                        .padding(.horizontal)
                        
                        if let selectedMonth = selectedMonth,
                           let selectedData = profitByMonth.first(where: { Calendar.current.isDate($0.month, equalTo: selectedMonth, toGranularity: .month) }) {
                            HStack {
                                Text(selectedData.month, format: .dateTime.month(.abbreviated).year())
                                    .font(.manrope(13, weight: .medium))
                                    .foregroundColor(.themeSecondaryText)
                                Spacer()
                                Text(CurrencyFormatter.convertedSignedString(selectedData.profit, code: currencyCode, minFraction: 2, maxFraction: 2))
                                    .font(.manrope(16, weight: .bold))
                                    .foregroundColor(selectedData.profit >= 0 ? .themeGold : .themeLoss)
                            }
                            .padding(.horizontal)
                            .padding(.vertical, 8)
                            .transition(.opacity)
                        }
                    }
                }
                .padding(.vertical, 16)
                .background(Color.themeCardBackground.opacity(0.5))
                .cornerRadius(16)
                .padding(.horizontal)
                .contentShape(Rectangle())
                .onTapGesture {
                    withAnimation {
                        selectedMonth = nil
                    }
                }
            }
            .padding(.bottom, 16)
        }
        .scrollIndicators(.hidden)
        .background(Color.themeBackground)
        .onChange(of: selectedTab) { _, _ in
            selectedMonth = nil
        }
    }
}

#Preview {
    HomeView(selectedTab: .constant(0))
        .modelContainer(previewContainer)
}
