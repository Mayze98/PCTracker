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
                    .font(.system(size: 15))
                    .foregroundColor(.secondary)
                Text(value)
                    .font(.system(size: valueFontSize, weight: .semibold))
            }

        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color(.separator), lineWidth: 1)
        )
    }
}
