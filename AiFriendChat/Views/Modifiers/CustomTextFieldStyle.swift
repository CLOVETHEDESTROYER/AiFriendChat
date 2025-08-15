import SwiftUI

// MARK: - Custom Text Field Style for Clean, Adaptive Design

struct CleanTextFieldStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding()
            .background(Color(.systemBackground))
            .foregroundColor(Color(.label))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color(.systemGray4), lineWidth: 1)
            )
    }
}

struct AuthTextFieldStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color(.systemBackground).opacity(0.9))
            .foregroundColor(Color(.label))
            .cornerRadius(15)
            .overlay(
                RoundedRectangle(cornerRadius: 15)
                    .stroke(Color(.systemGray4), lineWidth: 0.5)
            )
    }
}

// MARK: - View Extensions for Easy Application

extension View {
    func cleanTextFieldStyle() -> some View {
        modifier(CleanTextFieldStyle())
    }
    
    func authTextFieldStyle() -> some View {
        modifier(AuthTextFieldStyle())
    }
}

// MARK: - Color Extensions for Adaptive Text Fields

extension Color {
    static var adaptiveTextFieldBackground: Color {
        Color(.systemBackground)
    }
    
    static var adaptiveTextColor: Color {
        Color(.label)
    }
    
    static var adaptiveTextFieldBorder: Color {
        Color(.systemGray4)
    }
}
