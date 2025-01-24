// ViewModels/AuthViewModel.swift
class AuthViewModel: ObservableObject {
    @Published var isLoggedIn = false
    @Published var user: User?
    
    func login(email: String, password: String) {
        // Implement login logic using AuthService
    }
    
    func register(email: String, password: String) {
        // Implement registration logic using AuthService
    }
    
    func logout() {
        // Implement logout logic
    }
}