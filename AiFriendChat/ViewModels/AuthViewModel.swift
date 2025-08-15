//
//  AuthViewModel.swift
//  AiFriendChat
//
//  Created by Carlos Alvarez on 10/19/24.
//


// ViewModels/AuthViewModel.swift
import Foundation
import SwiftUI

class AuthViewModel: ObservableObject {
    @Published var isLoggedIn = false
    @Published var isLogin = true
    @Published var user: User?
    @Published var errorMessage: String?  // Add this line
    @Published var error: Error?
    
    private let authService = AuthService.shared
    
    
    
    func login(email: String, password: String) {
        authService.login(email: email, password: password) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let tokenResponse):
                    self.isLoggedIn = true
                    KeychainManager.shared.saveToken(tokenResponse.accessToken, forKey: "accessToken")
                    KeychainManager.shared.saveToken(tokenResponse.refreshToken, forKey: "refreshToken")
                    self.errorMessage = nil
                    print("Login successful. Access token: \(tokenResponse.accessToken)")
                case .failure(let error):
                    self.isLoggedIn = false
                    self.errorMessage = error.localizedDescription
                    print("Login failed. Error: \(error.localizedDescription)")
                }
            }
        }
    }
    
    func register(email: String, password: String) {
        AuthService.shared.register(email: email, password: password) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let tokenResponse):
                    self.isLoggedIn = true
                    // Save access token securely
                    KeychainManager.shared.saveToken(tokenResponse.accessToken, forKey: "accessToken")
                    KeychainManager.shared.saveToken(tokenResponse.refreshToken, forKey: "refreshToken")
                    print("Registration successful. Access token: \(tokenResponse.accessToken)")
                case .failure(let error):
                    let desc = error.localizedDescription.lowercased()
                    if desc.contains("unexpected") || desc.contains("500") {
                        self.errorMessage = "Registration may have failed due to a server issue. If this email is new, try logging in instead - you might already be registered."
                    } else if desc.contains("already exists") || desc.contains("duplicate") {
                        self.errorMessage = "This email is already registered. Try logging in instead."
                    } else {
                        self.errorMessage = "Registration failed: \(error.localizedDescription)"
                    }
                    print("🔴 Registration error: \(desc)")
                }
            }
        }
    }
    
    func logout() {
        authService.logout { result in
            DispatchQueue.main.async {
                switch result {
                case .success(_):
                    // Clear local data after successful API call
                    KeychainManager.shared.deleteToken(forKey: "accessToken")
                    KeychainManager.shared.deleteToken(forKey: "refreshToken")
                    self.isLoggedIn = false
                    self.user = nil
                    print("Logout successful")
                case .failure(let error):
                    // Even if API call fails, clear local data for security
                    print("Logout API call failed: \(error.localizedDescription)")
                    KeychainManager.shared.deleteToken(forKey: "accessToken")
                    KeychainManager.shared.deleteToken(forKey: "refreshToken")
                    self.isLoggedIn = false
                    self.user = nil
                }
            }
        }
    }
    
    func refreshTokenIfNeeded(completion: @escaping (Bool) -> Void) {
            guard let refreshToken = KeychainManager.shared.getToken(forKey: "refreshToken") else {
                completion(false)
                return
            }
            
            authService.refreshToken(token: refreshToken) { result in
                DispatchQueue.main.async {
                    switch result {
                    case .success(let newToken):
                        KeychainManager.shared.saveToken(newToken, forKey: "accessToken")
                        completion(true)
                    case .failure(_):
                        self.isLoggedIn = false
                        KeychainManager.shared.deleteToken(forKey: "accessToken")
                        KeychainManager.shared.deleteToken(forKey: "refreshToken")
                        completion(false)
                    }
                }
            }
        }

    func handleAuthenticationError() {
        refreshTokenIfNeeded { success in
            if !success {
                self.isLoggedIn = false
                self.errorMessage = "Session expired. Please log in again."
            }
        }
    }
}
