//
//  ColorExtensions.swift
//  PCTracker
//
//  Created by John on 2026-03-09.
//

import SwiftUI

// MARK: - Card Condition Color Helper
extension Color {
    /// Returns the appropriate color for a card condition
    /// - Parameters:
    ///   - condition: The condition string (M, NM, LP, MP, HP, DMG)
    ///   - isGraded: Whether the card is graded
    /// - Returns: The color to use for the condition badge
    static func conditionColor(for condition: String, isGraded: Bool) -> Color {
        if isGraded {
            return Color(red: 0.4, green: 0.6, blue: 0.9) // Soft blue
        }
        
        switch condition.uppercased() {
        case "M", "NM":
            return Color(red: 0.4, green: 0.8, blue: 0.5) // Soft green
        case "LP":
            return Color(red: 0.3, green: 0.7, blue: 0.4) // Muted green
        case "MP":
            return Color(red: 0.9, green: 0.8, blue: 0.4) // Soft yellow
        case "HP":
            return Color(red: 0.9, green: 0.7, blue: 0.4) // Soft orange
        case "DMG":
            return Color(red: 0.9, green: 0.5, blue: 0.5) // Soft red
        default:
            return Color(red: 0.6, green: 0.6, blue: 0.6) // Soft gray
        }
    }
    
    /// Adaptive color: Blue in light mode, Orange in dark mode
    static var appAccent: Color {
        Color("AppAccent")
    }
    
    /// Creates an adaptive color that changes based on color scheme
    static func adaptive(light: Color, dark: Color) -> Color {
        Color(UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark ? UIColor(dark) : UIColor(light)
        })
    }
    
    // Soft, subtle colors for profit/loss
    static var softGreen: Color {
        Color(red: 0.4, green: 0.8, blue: 0.5)
    }
    
    static var softRed: Color {
        Color(red: 0.9, green: 0.5, blue: 0.5)
    }
    
    static var softBlue: Color {
        Color(red: 0.5, green: 0.7, blue: 0.95)
    }
    
    static var softYellow: Color {
        Color(red: 0.95, green: 0.85, blue: 0.4)
    }
    
    static var softOrange: Color {
        Color(red: 0.95, green: 0.7, blue: 0.4)
    }
}

// Fallback if asset doesn't exist - creates adaptive color programmatically
extension Color {
    static var adaptiveBlueOrange: Color {
        Color.adaptive(
            light: Color(red: 0.5, green: 0.7, blue: 0.95), // Soft blue
            dark: Color(red: 0.95, green: 0.7, blue: 0.4)   // Soft orange
        )
    }
}
