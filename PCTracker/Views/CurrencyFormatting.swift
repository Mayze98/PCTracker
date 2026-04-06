//
//  CurrencyFormatting.swift
//  PCTracker
//
//  Shared currency formatting helpers.
//

import Foundation

enum CurrencyFormatter {
    /// All prices in the database are stored in CAD (the canonical currency).
    /// When the user switches to USD, displayed values are divided by the USD→CAD rate.
    static let storageCurrency = "CAD"
    
    /// Converts a stored amount (in CAD) to the current display currency.
    /// If displaying in CAD, returns as-is. If displaying in USD, divides by the rate.
    static func displayAmount(_ storedValue: Double, displayCode: String) -> Double {
        guard displayCode == "USD" else { return storedValue }
        let rate = UserDefaults.standard.double(forKey: "usdToCadRate")
        let validRate = rate > 0 ? rate : 1.35
        return storedValue / validRate
    }
    
    /// Converts a user-entered amount (in current display currency) to the storage currency (CAD).
    /// If entering in CAD, returns as-is. If entering in USD, multiplies by the rate.
    static func toStorageAmount(_ enteredValue: Double, fromCode: String) -> Double {
        guard fromCode == "USD" else { return enteredValue }
        let rate = UserDefaults.standard.double(forKey: "usdToCadRate")
        let validRate = rate > 0 ? rate : 1.35
        return enteredValue * validRate
    }
    
    static func symbol(for code: String) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = code
        return formatter.currencySymbol ?? code
    }

    /// Formats a raw value as currency. Does NOT apply conversion — use `converted()` variants for stored values.
    static func string(_ value: Double, code: String, minFraction: Int = 2, maxFraction: Int = 2) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = code
        formatter.minimumFractionDigits = minFraction
        formatter.maximumFractionDigits = maxFraction
        return formatter.string(from: NSNumber(value: value)) ?? "\(value)"
    }

    /// Formats a raw value as a signed currency string. Does NOT apply conversion.
    static func signedString(_ value: Double, code: String, minFraction: Int = 2, maxFraction: Int = 2) -> String {
        let sign = value >= 0 ? "+" : "-"
        return sign + string(abs(value), code: code, minFraction: minFraction, maxFraction: maxFraction)
    }
    
    /// Formats a stored value (in CAD) for display, converting to the display currency first.
    static func convertedString(_ storedValue: Double, code: String, minFraction: Int = 2, maxFraction: Int = 2) -> String {
        let displayed = displayAmount(storedValue, displayCode: code)
        return string(displayed, code: code, minFraction: minFraction, maxFraction: maxFraction)
    }
    
    /// Formats a stored value (in CAD) as a signed currency string, converting to the display currency first.
    static func convertedSignedString(_ storedValue: Double, code: String, minFraction: Int = 2, maxFraction: Int = 2) -> String {
        let displayed = displayAmount(storedValue, displayCode: code)
        return signedString(displayed, code: code, minFraction: minFraction, maxFraction: maxFraction)
    }
}
