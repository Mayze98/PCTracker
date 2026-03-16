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

