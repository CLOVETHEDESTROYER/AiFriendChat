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
                    print("Registration successful. Access token: \(tokenResponse.accessToken)")
                case .failure(let error):
                    self.errorMessage = error.localizedDescription
                    print("Registration error: \(error.localizedDescription)")
                }
            }
        }
    }
    
    func logout() {
        KeychainManager.shared.deleteToken(forKey: "accessToken")
        self.isLoggedIn = false
        self.user = nil
    }
    
    func refreshTokenIfNeeded(completion: @escaping (Bool) -> Void) {
            guard let token = KeychainManager.shared.getToken(forKey: "accessToken") else {
                completion(false)
                return
            }
            
            authService.refreshToken(token: token) { result in
                DispatchQueue.main.async {
                    switch result {
                    case .success(let newToken):
                        KeychainManager.shared.saveToken(newToken, forKey: "accessToken")
                        completion(true)
                    case .failure(_):
                        self.isLoggedIn = false
                        KeychainManager.shared.deleteToken(forKey: "accessToken")
                        completion(false)
                    }
                }
            }
        }
}
