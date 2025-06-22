import SwiftUI

struct AuthPromptModifier: ViewModifier {
    @EnvironmentObject var authViewModel: AuthViewModel
    @Binding var showAuthPrompt: Bool
    @Binding var showAuthView: Bool
    let action: () -> Void
    
    func body(content: Content) -> some View {
        content
            .disabled(!authViewModel.isLoggedIn)
            .opacity(authViewModel.isLoggedIn ? 1.0 : 0.6)
            .onTapGesture {
                if !authViewModel.isLoggedIn {
                    showAuthPrompt = true
                } else {
                    action()
                }
            }
            .sheet(isPresented: $showAuthPrompt) {
                AuthPromptView(showAuthView: $showAuthView)
                    .environmentObject(authViewModel)
            }
            .onChange(of: authViewModel.isLoggedIn) { oldValue, newValue in
                if newValue {
                    showAuthPrompt = false
                    showAuthView = false
                    action()
                }
            }
    }
}

extension View {
    func requiresAuth(
        showAuthPrompt: Binding<Bool>,
        showAuthView: Binding<Bool>,
        action: @escaping () -> Void
    ) -> some View {
        modifier(AuthPromptModifier(
            showAuthPrompt: showAuthPrompt,
            showAuthView: showAuthView,
            action: action
        ))
    }
} 