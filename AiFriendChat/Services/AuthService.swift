//
//  AuthService.swift
//  AiFriendChat
//
//  Created by Carlos Alvarez on 10/19/24.
//


// Services/AuthService.swift
import Foundation

struct AuthService {
    static let shared = AuthService()
    #if DEBUG
    private let baseURL = "https://voice.hyperlabsai.com"
    #else
    private let baseURL = "https://voice.hyperlabsai.com"
    #endif

    private init() {}

    func login(email: String, password: String, completion: @escaping (Result<TokenResponse, Error>) -> Void) {
        guard let url = URL(string: "\(baseURL)/auth/login") else {
            print("Failed to create URL with baseURL: \(baseURL)")
            completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.setValue("mobile", forHTTPHeaderField: "X-App-Type")
        request.setValue("Speech-Assistant-Mobile-iOS/1.0", forHTTPHeaderField: "User-Agent")
        request.timeoutInterval = 30
        
        let parameters = "username=\(email)&password=\(password)"
        request.httpBody = parameters.data(using: .utf8)
        
        let session = URLSession(configuration: .default)
        
        session.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Network error: \(error)")
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse {
                print("Response status code: \(httpResponse.statusCode)")
            }
            
            guard let data = data else {
                print("No data received")
                DispatchQueue.main.async {
                    completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "No data received"])))
                }
                return
            }
            
            do {
                let tokenResponse = try JSONDecoder().decode(TokenResponse.self, from: data)
                DispatchQueue.main.async {
                    completion(.success(tokenResponse))
                }
            } catch {
                print("Decoding error: \(error)")
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }
        }.resume()
    }

    func register(email: String, password: String, completion: @escaping (Result<TokenResponse, Error>) -> Void) {
        guard let url = URL(string: "\(baseURL)/auth/register") else {
            print("Failed to create URL with baseURL: \(baseURL)")
            completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("mobile", forHTTPHeaderField: "X-App-Type")
        request.setValue("Speech-Assistant-Mobile-iOS/1.0", forHTTPHeaderField: "User-Agent")
        request.timeoutInterval = 30
        
        // Create JSON request body
        let requestBody = ["email": email, "password": password]
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        } catch {
            print("Failed to encode request body: \(error)")
            completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to encode request data"])))
            return
        }
        
        let session = URLSession(configuration: .default)
        
        session.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Network error: \(error)")
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse {
                print("Registration response status code: \(httpResponse.statusCode)")
            }
            
            guard let data = data else {
                print("No data received")
                DispatchQueue.main.async {
                    completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "No data received"])))
                }
                return
            }
            
            // Print the raw response for debugging
            if let responseString = String(data: data, encoding: .utf8) {
                print("Raw server response: \(responseString)")
            }
            
            do {
                // First try to decode as TokenResponse
                if let tokenResponse = try? JSONDecoder().decode(TokenResponse.self, from: data) {
                    DispatchQueue.main.async {
                        completion(.success(tokenResponse))
                    }
                    return
                }
                
                // If that fails, try to decode as an error message
                if let errorResponse = try? JSONDecoder().decode([String: String].self, from: data) {
                    DispatchQueue.main.async {
                        let errorMessage = errorResponse["detail"] ?? errorResponse["message"] ?? "Unknown error"
                        completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: errorMessage])))
                    }
                    return
                }
                
                // If both fail, throw a generic error
                throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid server response format"])
                
            } catch {
                print("Registration decoding error: \(error)")
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }
        }.resume()
    }

    func refreshToken(token: String, completion: @escaping (Result<String, Error>) -> Void) {
        guard let url = URL(string: "\(baseURL)/auth/refresh") else {
            print("Failed to create URL with baseURL: \(baseURL)")
            completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Send refresh token in request body
        let requestBody = ["refresh_token": token]
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        } catch {
            print("Failed to encode refresh token request: \(error)")
            completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to encode request data"])))
            return
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
                return
            }
            
            guard let data = data else {
                DispatchQueue.main.async {
                    completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "No data received"])))
                }
                return
            }
            
            do {
                let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
                if let newToken = json?["access_token"] as? String {
                    DispatchQueue.main.async {
                        completion(.success(newToken))
                    }
                } else {
                    DispatchQueue.main.async {
                        completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid response format"])))
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }
        }.resume()
    }
    
    func logout(completion: @escaping (Result<Void, Error>) -> Void) {
        guard let token = KeychainManager.shared.getToken(forKey: "accessToken") else {
            // If no token exists, consider logout successful
            DispatchQueue.main.async {
                completion(.success(()))
            }
            return
        }
        
        guard let url = URL(string: "\(baseURL)/auth/logout") else {
            print("Failed to create URL with baseURL: \(baseURL)")
            completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Logout network error: \(error)")
                // Even if the API call fails, we should still clear local data
                DispatchQueue.main.async {
                    completion(.success(()))
                }
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse {
                print("Logout response status code: \(httpResponse.statusCode)")
            }
            
            // Consider logout successful regardless of server response
            // The important thing is clearing local data
            DispatchQueue.main.async {
                completion(.success(()))
            }
        }.resume()
    }
}
