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
        themeLoss
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

// MARK: - Midnight Foil Theme
extension Color {
    // Gold accent - unchanged between light and dark
    static var themeGold: Color {
        Color(red: 201/255, green: 168/255, blue: 76/255) // #C9A84C
    }
    
    // Navy - nav/headers in light mode
    static var themeNavy: Color {
        Color(red: 26/255, green: 35/255, blue: 64/255) // #1A2340
    }
    
    // Ink - secondary surfaces in light mode
    static var themeInk: Color {
        Color(red: 46/255, green: 61/255, blue: 107/255) // #2E3D6B
    }
    
    // Ice - surfaces in light mode
    static var themeIce: Color {
        Color(red: 232/255, green: 240/255, blue: 255/255) // #E8F0FF
    }
    
    // Void - app background in dark mode
    static var themeVoid: Color {
        Color(red: 12/255, green: 15/255, blue: 26/255) // #0C0F1A
    }
    
    // Deep Navy - deep background in dark mode
    static var themeDeepNavy: Color {
        Color(red: 20/255, green: 25/255, blue: 40/255) // #141928
    }
    
    // Surface - card surfaces in dark mode
    static var themeSurface: Color {
        Color(red: 30/255, green: 38/255, blue: 64/255) // #1E2640
    }
    
    // Adaptive accent: Gold in both modes
    static var adaptiveBlueOrange: Color {
        themeGold
    }
    
    // Adaptive app background
    static var themeBackground: Color {
        Color.adaptive(
            light: themeNavy,       // #1A2340
            dark: themeVoid         // #0C0F1A
        )
    }
    
    // Adaptive card/surface background
    static var themeCardBackground: Color {
        Color.adaptive(
            light: themeInk,        // #2E3D6B
            dark: themeSurface      // #1E2640
        )
    }
    
    // Adaptive header/nav background
    static var themeHeaderBackground: Color {
        Color.adaptive(
            light: themeNavy,       // #1A2340
            dark: themeDeepNavy     // #141928
        )
    }
    
    // Adaptive secondary text on header
    static var themeHeaderText: Color {
        .white
    }
    
    // Adaptive list row / form section background
    static var themeRowBackground: Color {
        Color.adaptive(
            light: themeInk,        // #2E3D6B
            dark: themeDeepNavy     // #141928
        )
    }
    
    // Primary text color: white in both modes
    static var themePrimaryText: Color {
        .white
    }
    
    // Secondary text color: Ice #E8F0FF in both modes
    static var themeSecondaryText: Color {
        themeIce // #E8F0FF
    }
    
    // Adaptive profit color: gold
    static var themeProfit: Color {
        themeGold
    }
    
    // Loss color: muted slate-rose for negative values
    static var themeLoss: Color {
        Color(red: 163/255, green: 120/255, blue: 140/255) // #A3788C
    }
}

// MARK: - Manrope Font System
extension Font {
    // Manrope font family name references for the static font files
    // Weights map to: ExtraLight(200), Light(300), Regular(400), Medium(500), SemiBold(600), Bold(700), ExtraBold(800)
    
    /// Manrope with a specific size and weight
    static func manrope(_ size: CGFloat, weight: ManropeWeight = .regular) -> Font {
        .custom(weight.fontName, size: size)
    }
    
    /// Manrope sized to match a given text style, with relative scaling
    static func manrope(_ style: Font.TextStyle, weight: ManropeWeight = .regular) -> Font {
        .custom(weight.fontName, size: style.defaultSize, relativeTo: style)
    }
    
    enum ManropeWeight {
        case extraLight
        case light
        case regular
        case medium
        case semiBold
        case bold
        case extraBold
        
        var fontName: String {
            switch self {
            case .extraLight: return "Manrope-ExtraLight"
            case .light:      return "Manrope-Light"
            case .regular:    return "Manrope-Regular"
            case .medium:     return "Manrope-Medium"
            case .semiBold:   return "Manrope-SemiBold"
            case .bold:       return "Manrope-Bold"
            case .extraBold:  return "Manrope-ExtraBold"
            }
        }
    }
}

// MARK: - TextStyle Default Sizes (for relativeTo scaling)
extension Font.TextStyle {
    var defaultSize: CGFloat {
        switch self {
        case .largeTitle:  return 34
        case .title:       return 28
        case .title2:      return 22
        case .title3:      return 20
        case .headline:    return 17
        case .body:        return 17
        case .callout:     return 16
        case .subheadline: return 15
        case .footnote:    return 13
        case .caption:     return 12
        case .caption2:    return 11
        @unknown default:  return 17
        }
    }
}
