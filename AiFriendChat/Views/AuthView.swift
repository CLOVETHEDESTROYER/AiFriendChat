//
//  AuthView.swift
//  AiFriendChat
//
//  Created by Carlos Alvarez on 10/19/24.
//

import SwiftUI
import SwiftData
import AuthenticationServices

struct AuthView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var isLogin = true
    @State private var email = ""
    @State private var password = ""
    @State private var name = ""
    @State private var phoneNumber = ""
    @State private var showEnhancedRegistration = false
    
    var body: some View {
        ZStack {
            // Background with main color and gradient
            VStack(spacing: 0) {
                // First 1/4 of the screen with the "AccentColor"
                Color("Color")
                    .frame(height: UIScreen.main.bounds.height / 4)
                
                // Remaining 3/4 of the screen with a gradient
                LinearGradient(
                    gradient: Gradient(colors: [Color("Color"), Color("Color 2")]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: UIScreen.main.bounds.height * 3 / 4)
            }
            .edgesIgnoringSafeArea(.all)
            
            // Login form and other content
            ScrollView {
                VStack(spacing: 20) {
                    // Logo
                    Image("logo") // Replace with the name of your image in Assets
                        .resizable()
                        .scaledToFit()
                        .frame(width: 250, height: 250) // Adjusted size
                        .padding(.top, 20)
                    
                    // App name
                    Text("AI FRIEND CHAT")
                        .font(.system(size: 36, weight: .heavy, design: .rounded)) // Adjusted font size
                        .foregroundColor(.white)
                        .padding(.bottom, 10)
                    
                    // Login/Register Title
                    Text(isLogin ? "Login" : "Register")
                        .font(.largeTitle)
                        .foregroundColor(.white)
                        .padding(.bottom, 10)
                    
                    // Enhanced Registration Fields (only show when not login and enhanced registration is enabled)
                    if !isLogin && showEnhancedRegistration {
                        // Name Field
                        TextField("Full Name", text: $name)
                            .autocapitalization(.words)
                            .disableAutocorrection(true)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color(.systemBackground).opacity(0.9))
                            .foregroundColor(Color(.label))
                            .cornerRadius(15)
                            .overlay(
                                RoundedRectangle(cornerRadius: 15)
                                    .stroke(Color(.systemGray4), lineWidth: 0.5)
                            )
                            .padding(.horizontal, 30)
                        
                        // Phone Number Field
                        TextField("Phone Number (Optional)", text: $phoneNumber)
                            .keyboardType(.phonePad)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color(.systemBackground).opacity(0.9))
                            .foregroundColor(Color(.label))
                            .cornerRadius(15)
                            .overlay(
                                RoundedRectangle(cornerRadius: 15)
                                    .stroke(Color(.systemGray4), lineWidth: 0.5)
                            )
                            .padding(.horizontal, 30)
                    }
                    
                    // Email Text Field
                    TextField("Email", text: $email)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                        .keyboardType(.emailAddress)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(.systemBackground).opacity(0.9))
                        .foregroundColor(Color(.label))
                        .cornerRadius(15)
                        .overlay(
                            RoundedRectangle(cornerRadius: 15)
                                .stroke(Color(.systemGray4), lineWidth: 0.5)
                        )
                        .padding(.horizontal, 30)
                    
                    // Password Text Field
                    SecureField("Password", text: $password)
                        .disableAutocorrection(true)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(.systemBackground).opacity(0.9))
                        .foregroundColor(Color(.label))
                        .cornerRadius(15)
                        .overlay(
                            RoundedRectangle(cornerRadius: 15)
                                .stroke(Color(.systemGray4), lineWidth: 0.5)
                        )
                        .padding(.horizontal, 30)
                    
                    // Login/Register Button
                    Button(action: {
                        let lowercaseEmail = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
                        if isLogin {
                            authViewModel.login(email: lowercaseEmail, password: password)
                        } else {
                            if showEnhancedRegistration {
                                authViewModel.registerWithOnboarding(
                                    email: lowercaseEmail,
                                    password: password,
                                    name: name.trimmingCharacters(in: .whitespacesAndNewlines),
                                    phoneNumber: phoneNumber.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : phoneNumber.trimmingCharacters(in: .whitespacesAndNewlines)
                                )
                            } else {
                                authViewModel.register(email: lowercaseEmail, password: password)
                            }
                        }
                    }) {
                        Text(isLogin ? "Login" : "Register")
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.blue)
                            .cornerRadius(15)
                    }
                    .padding(.horizontal, 30)
                    .disabled(email.isEmpty || password.isEmpty || (!isLogin && showEnhancedRegistration && name.isEmpty))
                    
                    // Apple Sign-In Button (only show when not login)
                    if !isLogin {
                        AppleSignInButtonView()
                            .padding(.horizontal, 30)
                    }
                    
                    // Enhanced Registration Toggle
                    if !isLogin {
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                showEnhancedRegistration.toggle()
                            }
                        }) {
                            HStack {
                                Image(systemName: showEnhancedRegistration ? "chevron.up" : "chevron.down")
                                Text(showEnhancedRegistration ? "Hide Advanced Options" : "Show Advanced Options")
                            }
                            .foregroundColor(.white.opacity(0.8))
                            .font(.caption)
                        }
                        .padding(.top, 10)
                    }
                    
                    // Error Message
                    if let errorMessage = authViewModel.errorMessage {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .font(.caption)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 30)
                    }
                    
                    // Toggle between Login and Register
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            isLogin.toggle()
                            showEnhancedRegistration = false
                            email = ""
                            password = ""
                            name = ""
                            phoneNumber = ""
                            authViewModel.errorMessage = nil
                        }
                    }) {
                        Text(isLogin ? "Don't have an account? Register" : "Already have an account? Login")
                            .foregroundColor(.white.opacity(0.8))
                            .font(.caption)
                    }
                    .padding(.top, 20)
                    
                    Spacer()
                }
                .padding(.bottom, 50)
            }
        }
        .navigationBarHidden(true)
    }
}

// MARK: - Apple Sign-In Button (Inline for compatibility)
struct AppleSignInButtonView: View {
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
    AuthView()
        .environmentObject(AuthViewModel())
}
