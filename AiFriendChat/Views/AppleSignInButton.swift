//
//  AppleSignInButton.swift
//  AiFriendChat
//
//  Created by AI Assistant
//

import SwiftUI
import AuthenticationServices

struct AppleSignInButton: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var showingError = false
    @State private var errorMessage = ""
    
    var body: some View {
        SignInWithAppleButton(
            onRequest: { request in
                request.requestedScopes = [.fullName, .email]
            },
            onCompletion: { result in
                handleAppleSignInResult(result)
            }
        )
        .signInWithAppleButtonStyle(.white)
        .frame(height: 50)
        .cornerRadius(8)
        .alert("Apple Sign-In Error", isPresented: $showingError) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
    }
    
    private func handleAppleSignInResult(_ result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let authorization):
            if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
                // Extract the identity token and authorization code
                guard let identityToken = appleIDCredential.identityToken,
                      let authorizationCode = appleIDCredential.authorizationCode else {
                    showError("Failed to get Apple Sign-In credentials")
                    return
                }
                
                // Convert Data to String
                let identityTokenString = String(data: identityToken, encoding: .utf8) ?? ""
                let authorizationCodeString = String(data: authorizationCode, encoding: .utf8) ?? ""
                
                if identityTokenString.isEmpty || authorizationCodeString.isEmpty {
                    showError("Invalid Apple Sign-In credentials")
                    return
                }
                
                // Call the backend with Apple Sign-In credentials
                authViewModel.appleSignIn(
                    identityToken: identityTokenString,
                    authorizationCode: authorizationCodeString
                )
                
            } else {
                showError("Invalid Apple Sign-In credential type")
            }
            
        case .failure(let error):
            if let authError = error as? ASAuthorizationError {
                switch authError.code {
                case .canceled:
                    // User canceled, no need to show error
                    break
                case .failed:
                    showError("Apple Sign-In failed: \(authError.localizedDescription)")
                case .invalidResponse:
                    showError("Invalid Apple Sign-In response")
                case .notHandled:
                    showError("Apple Sign-In not handled")
                case .unknown:
                    showError("Unknown Apple Sign-In error")
                @unknown default:
                    showError("Unexpected Apple Sign-In error")
                }
            } else {
                showError("Apple Sign-In error: \(error.localizedDescription)")
            }
        }
    }
    
    private func showError(_ message: String) {
        errorMessage = message
        showingError = true
    }
}

#Preview {
    AppleSignInButton()
        .environmentObject(AuthViewModel())
        .padding()
}
