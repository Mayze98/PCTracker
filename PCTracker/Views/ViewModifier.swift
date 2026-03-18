//
//  ViewModifier.swift
//  PCTracker
//
//  Created by John on 2026-02-26.
//
import SwiftUI

struct StatCard: View {
    let icon: String
    let iconColor: Color
    let title: String
    let value: String
    var valueFontSize: CGFloat = 28
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 28))
                .foregroundColor(iconColor)
                .frame(width: 50, height: 50)
                .background(iconColor.opacity(0.1))
                .cornerRadius(12)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.manrope(15, weight: .medium))
                    .foregroundColor(.themeSecondaryText)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                Text(value)
                    .font(.manrope(valueFontSize, weight: .semiBold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }

        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(height: 82)
        .background(Color.themeCardBackground)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.themeGold.opacity(0.2), lineWidth: 1)
        )
    }
}
struct FlippableStatCard: View {
    let icon: String
    let iconColor: Color
    let title: String
    let value: String
    let backTitle: String
    let backValue: String
    let backIcon: String?
    var valueFontSize: CGFloat = 28
    @Binding var selectedTab: Int
    
    @State private var isFlipped = false
    
    var body: some View {
        ZStack {
            // Front side
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.system(size: 28))
                    .foregroundColor(iconColor)
                    .frame(width: 50, height: 50)
                    .background(iconColor.opacity(0.1))
                    .cornerRadius(12)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.manrope(15, weight: .medium))
                        .foregroundColor(.themeSecondaryText)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                    Text(value)
                        .font(.manrope(valueFontSize, weight: .semiBold))
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
                
                Spacer()
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .frame(height: 82)
            .background(Color.themeCardBackground)
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.themeGold.opacity(0.2), lineWidth: 1)
            )
            .opacity(isFlipped ? 0 : 1)
            .rotation3DEffect(
                .degrees(isFlipped ? 180 : 0),
                axis: (x: 0, y: 1, z: 0)
            )
            
            // Back side
            HStack(spacing: 16) {
                if let backIcon = backIcon {
                    Image(systemName: backIcon)
                        .font(.system(size: 28))
                        .foregroundColor(iconColor)
                        .frame(width: 50, height: 50)
                        .background(iconColor.opacity(0.1))
                        .cornerRadius(12)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(backTitle)
                        .font(.manrope(15, weight: .medium))
                        .foregroundColor(.themeSecondaryText)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                    Text(backValue)
                        .font(.manrope(valueFontSize, weight: .semiBold))
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
                
                Spacer()
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .frame(height: 82)
            .background(Color.themeCardBackground)
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.themeGold.opacity(0.2), lineWidth: 1)
            )
            .opacity(isFlipped ? 1 : 0)
            .rotation3DEffect(
                .degrees(isFlipped ? 0 : -180),
                axis: (x: 0, y: 1, z: 0)
            )
        }
        .frame(height: 82)
        .onTapGesture {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                isFlipped.toggle()
            }
        }
        .onChange(of: selectedTab) { _, _ in
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                isFlipped = false
            }
        }
    }
}

// MARK: - Hero Card for Net Profit / ROI

struct FlippableHeroCard: View {
    let label: String
    let value: String
    let valueColor: Color
    let monthLabel: String
    let monthValue: String
    @Binding var selectedTab: Int
    
    @State private var isFlipped = false
    
    var body: some View {
        ZStack {
            // Front
            frontSide
                .opacity(isFlipped ? 0 : 1)
                .rotation3DEffect(.degrees(isFlipped ? 180 : 0), axis: (x: 0, y: 1, z: 0))
            
            // Back
            backSide
                .opacity(isFlipped ? 1 : 0)
                .rotation3DEffect(.degrees(isFlipped ? 0 : -180), axis: (x: 0, y: 1, z: 0))
        }
        .frame(height: 120)
        .onTapGesture {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                isFlipped.toggle()
            }
        }
        .onChange(of: selectedTab) { _, _ in
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                isFlipped = false
            }
        }
    }
    
    private var frontSide: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.manrope(13, weight: .medium))
                .foregroundColor(.themeSecondaryText)
            
            Text(value)
                .font(.manrope(32, weight: .bold))
                .foregroundColor(valueColor)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            
            Spacer()
            
            Text("Tap for monthly")
                .font(.manrope(10, weight: .regular))
                .foregroundColor(.themeSecondaryText.opacity(0.5))
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(height: 120)
        .background(Color.themeCardBackground)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(
                    LinearGradient(
                        colors: [Color.themeGold.opacity(0.4), Color.themeGold.opacity(0.1)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
    }
    
    private var backSide: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(monthLabel)
                .font(.manrope(13, weight: .medium))
                .foregroundColor(.themeSecondaryText)
            
            Text(monthValue)
                .font(.manrope(32, weight: .bold))
                .foregroundColor(valueColor)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            
            Spacer()
            
            Text("Tap for all-time")
                .font(.manrope(10, weight: .regular))
                .foregroundColor(.themeSecondaryText.opacity(0.5))
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(height: 120)
        .background(Color.themeCardBackground)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(
                    LinearGradient(
                        colors: [Color.themeGold.opacity(0.4), Color.themeGold.opacity(0.1)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
    }
}

// MARK: - Compact Stat Card for secondary stats

struct CompactStatCard: View {
    let icon: String
    let title: String
    let value: String
    let monthChange: String
    
    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.themeGold)
                .frame(width: 32, height: 32)
                .background(Color.themeGold.opacity(0.1))
                .cornerRadius(8)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.manrope(11, weight: .medium))
                    .foregroundColor(.themeSecondaryText)
                    .lineLimit(1)
                Text(value)
                    .font(.manrope(16, weight: .semiBold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            
            Spacer()
            
            Text(monthChange)
                .font(.manrope(11, weight: .medium))
                .foregroundColor(.themeSecondaryText.opacity(0.7))
                .lineLimit(1)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.themeCardBackground.opacity(0.6))
        .cornerRadius(12)
    }
}

