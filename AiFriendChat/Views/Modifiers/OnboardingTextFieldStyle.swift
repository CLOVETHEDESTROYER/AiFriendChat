//
//  OnboardingTextFieldStyle.swift
//  AiFriendChat
//
//  Created by AI Assistant
//

import SwiftUI

struct OnboardingTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .font(.body)
            .padding()
            .frame(maxWidth: .infinity)
            .frame(minHeight: 50)
            .background(Color(.systemBackground).opacity(0.9))
            .foregroundColor(Color(.label))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color(.systemGray4), lineWidth: 1)
            )
    }
}

struct OnboardingButtonStyle: ButtonStyle {
    let isEnabled: Bool
    let isPrimary: Bool
    
    init(isEnabled: Bool = true, isPrimary: Bool = true) {
        self.isEnabled = isEnabled
        self.isPrimary = isPrimary
    }
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.title3)
            .fontWeight(.semibold)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(
                isPrimary ? 
                (isEnabled ? Color.white : Color.white.opacity(0.6)) :
                Color.clear
            )
            .foregroundColor(
                isPrimary ? 
                (isEnabled ? Color.black : Color.black.opacity(0.6)) :
                Color.white
            )
            .cornerRadius(28)
            .overlay(
                isPrimary ? nil :
                RoundedRectangle(cornerRadius: 28)
                    .stroke(Color.white.opacity(0.5), lineWidth: 1)
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

struct OnboardingCardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(20)
            .background(Color.white.opacity(0.1))
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
            )
    }
}

extension View {
    func onboardingCard() -> some View {
        self.modifier(OnboardingCardStyle())
    }
}
