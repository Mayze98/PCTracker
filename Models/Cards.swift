//
//  Cards.swift
//  PCTracker
//
//  Created by John on 2026-03-01.
//

// need card name, card number, graded, condition, buyPrice, salePrice
import SwiftData
import SwiftUI

@Model
class Cards {
    var name: String
    var number: String?
    var cardSet: String?
    var graded: Bool
    var condition: String  // Store condition as simple String
    var buyPrice: Double
    var salePrice: Double?
    var saleDate: Date?
    var purchaseDate: Date
    @Attribute(.externalStorage) var photoData: Data?
    var marketPrice: Double?
    var marketPriceDate: Date?
    
    init(name: String, number: String? = nil, cardSet: String? = nil, graded: Bool = false, condition: String = "NM", buyPrice: Double, salePrice: Double? = nil, saleDate: Date? = nil, purchaseDate: Date = Date(), photoData: Data? = nil, marketPrice: Double? = nil, marketPriceDate: Date? = nil) {
        self.name = name
        self.number = number
        self.cardSet = cardSet
        self.graded = graded
        self.condition = condition
        self.buyPrice = buyPrice
        self.salePrice = salePrice
        self.saleDate = saleDate
        self.purchaseDate = purchaseDate
        self.photoData = photoData
        self.marketPrice = marketPrice
        self.marketPriceDate = marketPriceDate
    }
    
    // Unrealized profit/loss based on market price vs buy price
    var marketProfit: Double? {
        guard let market = marketPrice else { return nil }
        return market - buyPrice
    }
    
    // Whether the cached market price is stale (older than 24 hours)
    var isMarketPriceStale: Bool {
        guard let date = marketPriceDate else { return true }
        return Date().timeIntervalSince(date) > 86400
    }
    
    // if the card has a profit
    var hasProfit: Bool {
        if let sale = salePrice {
            return sale > buyPrice
        }
        return false
    }
    
    // profit amount
    var profit: Double? {
        guard let sale = salePrice else { return nil }
        return sale - buyPrice
    }
    
    // return on investment percentage
    var roi: Double? {
        guard let profit = profit, buyPrice > 0 else { return nil }
        return (profit / buyPrice) * 100
    }
}

@Model
class SealedProduct {
    var name: String
    var expansion: String?
    var buyPrice: Double
    var salePrice: Double?
    var saleDate: Date?
    var purchaseDate: Date
    @Attribute(.externalStorage) var photoData: Data?
    
    init(name: String, expansion: String, buyPrice: Double, salePrice: Double? = nil, saleDate: Date? = nil, purchaseDate: Date = Date(), photoData: Data? = nil) {
        self.name = name
        self.expansion = expansion
        self.buyPrice = buyPrice
        self.salePrice = salePrice
        self.saleDate = saleDate
        self.purchaseDate = purchaseDate
        self.photoData = photoData
    }
    
    var hasProfit: Bool {
        if let sale = salePrice {
            return sale > buyPrice
        }
        return false
    }
    
    var profit: Double? {
        guard let sale = salePrice else { return nil }
        return sale - buyPrice
    }
    
    // return on investment percentage
    var roi: Double? {
        guard let profit = profit, buyPrice > 0 else { return nil }
        return (profit / buyPrice) * 100
    }
}

@Model
class MiscExpense {
    var itemDescription: String
    var cost: Double
    var purchaseDate: Date
    var notes: String?
    @Attribute(.externalStorage) var photoData: Data?
    
    init(itemDescription: String, cost: Double, purchaseDate: Date = Date(), notes: String? = nil, photoData: Data? = nil) {
        self.itemDescription = itemDescription
        self.cost = cost
        self.purchaseDate = purchaseDate
        self.notes = notes
        self.photoData = photoData
    }
}
