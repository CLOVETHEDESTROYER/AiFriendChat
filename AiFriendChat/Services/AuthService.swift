// Services/AuthService.swift
class AuthService {
    static let shared = AuthService()
    private init() {}
    
    func login(email: String, password: String, completion: @escaping (Result<TokenResponse, Error>) -> Void) {
        // Implement API call to login
    }
    
    func register(email: String, password: String, completion: @escaping (Result<TokenResponse, Error>) -> Void) {
        // Implement API call to register
    }
}