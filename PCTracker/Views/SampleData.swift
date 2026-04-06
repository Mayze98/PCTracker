//
//  SampleData.swift
//  PCTracker
//
//  Sample data for Xcode Previews only.
//  Uses an in-memory ModelContainer so nothing is persisted
//  or synced to a physical device.
//

import SwiftData
import SwiftUI

/// A preview-only ModelContainer pre-loaded with sample inventory.
@MainActor
let previewContainer: ModelContainer = {
    let schema = Schema([Cards.self, SealedProduct.self, MiscExpense.self])
    let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: schema, configurations: [config])
    let context = container.mainContext

    // MARK: - Sample Cards
    //                   name, number, graded, condition, buyPrice, salePrice, saleDate, purchaseDate, marketPrice, marketPriceDate

    let cards: [(String, String?, Bool, String, Double, Double?, Date?, Date, Double?, Date?)] = [
        ("Charizard VMAX",       "074/073", true,  "PSA 10", 350.00, nil,   nil, date(2026, 1, 15), 420.00, date(2026, 3, 30)),
        ("Pikachu VMAX",         "044/185", false, "NM",     45.00,  nil,   nil, date(2026, 2, 3),  62.50,  date(2026, 3, 30)),
        ("Lugia V Alt Art",      "186/195", false, "NM",     120.00, nil,   nil, date(2026, 2, 20), 145.00, date(2026, 3, 30)),
        ("Umbreon VMAX Alt Art", "215/203", true,  "CGC 9.5", 280.00, nil,  nil, date(2026, 1, 8),  310.00, date(2026, 3, 30)),
        ("Mewtwo GX",            "31/68",   false, "LP",     18.50,  nil,   nil, date(2026, 3, 1),  12.00,  date(2026, 3, 30)),
        ("Rayquaza VMAX",        "218/203", false, "NM",     75.00,  nil,   nil, date(2026, 3, 10), 88.00,  date(2026, 3, 30)),
        ("Giratina V Alt Art",   "186/196", false, "NM",     65.00,  nil,   nil, date(2026, 2, 14), nil,    nil),
        ("Mew VMAX",             "114/100", true,  "PSA 9",  95.00,  nil,   nil, date(2026, 1, 22), nil,    nil),
        ("Eevee",                "101/159", false, "MP",     5.00,   nil,   nil, date(2026, 3, 15), 3.50,   date(2026, 3, 29)),
        ("Arceus V Alt Art",     "TG22/TG30", false, "NM",  40.00,  nil,   nil, date(2026, 2, 28), nil,    nil),
        // Sold cards (will appear in Archived)
        ("Dragonite V Alt Art",  "049/078", false, "NM",     55.00,  90.00, date(2026, 3, 20), date(2026, 1, 5), nil, nil),
        ("Gengar VMAX",          "271/264", false, "NM",     30.00,  52.00, date(2026, 3, 18), date(2026, 2, 1), nil, nil),
    ]

    for c in cards {
        context.insert(Cards(
            name: c.0, number: c.1, graded: c.2, condition: c.3,
            buyPrice: c.4, salePrice: c.5, saleDate: c.6, purchaseDate: c.7,
            marketPrice: c.8, marketPriceDate: c.9
        ))
    }

    // MARK: - Sample Sealed Products

    let products: [(String, String, Double, Double?, Date?, Date)] = [
        ("Booster Box",          "Obsidian Flames",      144.99, nil,   nil, date(2026, 1, 20)),
        ("Elite Trainer Box",    "Paldea Evolved",       42.99,  nil,   nil, date(2026, 2, 10)),
        ("Booster Bundle",       "Scarlet & Violet 151", 29.99,  nil,   nil, date(2026, 3, 5)),
        ("Ultra Premium Collection", "Charizard",        119.99, nil,   nil, date(2026, 1, 30)),
        ("Booster Box",          "Crown Zenith",         169.99, nil,   nil, date(2026, 2, 18)),
        // A sold product
        ("Elite Trainer Box",    "Evolving Skies",       64.99,  110.00, date(2026, 3, 12), date(2026, 1, 10)),
    ]

    for p in products {
        context.insert(SealedProduct(
            name: p.0, expansion: p.1, buyPrice: p.2,
            salePrice: p.3, saleDate: p.4, purchaseDate: p.5
        ))
    }

    // MARK: - Sample Misc Expenses

    let expenses: [(String, Double, Date, String?)] = [
        ("Card sleeves (200 ct)", 8.99,  date(2026, 2, 5),  nil),
        ("Top loaders (25 ct)",   6.49,  date(2026, 2, 5),  nil),
        ("PSA Grading – 3 cards", 90.00, date(2026, 1, 12), "Charizard, Umbreon, Mew"),
        ("Shipping supplies",     15.00, date(2026, 3, 8),  "Bubble mailers and tape"),
    ]

    for e in expenses {
        context.insert(MiscExpense(
            itemDescription: e.0, cost: e.1, purchaseDate: e.2, notes: e.3
        ))
    }

    return container
}()

/// Helper to build a Date without verbosity.
private func date(_ year: Int, _ month: Int, _ day: Int) -> Date {
    Calendar.current.date(from: DateComponents(year: year, month: month, day: day))!
}
