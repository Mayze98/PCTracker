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
            return .blue
        }
        
        switch condition.uppercased() {
        case "M", "NM":
            return .green
        case "LP":
            return .mint
        case "MP":
            return .yellow
        case "HP":
            return .orange
        case "DMG":
            return .red
        default:
            return .gray
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
    
    // Vibrant colors for profit/loss
    static var softGreen: Color {
        .green
    }
    
    static var softRed: Color {
        .red
    }
    
    static var softBlue: Color {
        .blue
    }
    
    static var softYellow: Color {
        .yellow
    }
    
    static var softOrange: Color {
        .orange
    }
}

// Fallback if asset doesn't exist - creates adaptive color programmatically
extension Color {
    static var adaptiveBlueOrange: Color {
        Color.adaptive(
            light: .blue,
            dark: .orange
        )
    }
}
