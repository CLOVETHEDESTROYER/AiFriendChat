//
//  NetworkManager.swift
//  AiFriendChat
//
//  Created by Carlos Alvarez on 10/19/24.
//

//
//  NetworkManager.swift
//  AiFriendChat
//

import Foundation

class NetworkManager {
    static let shared = NetworkManager()

    // Use baseURL from Info.plist for flexibility
    private let baseURL = Bundle.main.object(forInfoDictionaryKey: "BaseURL") as? String ?? ""

    // Add shared methods:
    func createAuthenticatedRequest(url: URL, method: String, body: Data? = nil) -> URLRequest {
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("mobile", forHTTPHeaderField: "X-App-Type")
        request.setValue("Speech-Assistant-Mobile-iOS/1.0", forHTTPHeaderField: "User-Agent")
        if let token = KeychainManager.shared.getToken(forKey: "accessToken") {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        request.httpBody = body
        return request
    }

    // Register Endpoint
    func register(email: String, password: String, completion: @escaping (Result<TokenResponse, Error>) -> Void) {
        guard let url = URL(string: "\(baseURL)/register") else {
            completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])))
            return
        }

        let request = createAuthenticatedRequest(url: url, method: "POST", body: try? JSONEncoder().encode(["email": email, "password": password]))

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            if let httpResponse = response as? HTTPURLResponse, !(200...299).contains(httpResponse.statusCode) {
                let statusError = NSError(domain: "", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "HTTP Error \(httpResponse.statusCode)"])
                completion(.failure(statusError))
                return
            }

            guard let data = data else {
                completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "No data received"])))
                return
            }

            do {
                let tokenResponse = try JSONDecoder().decode(TokenResponse.self, from: data)
                completion(.success(tokenResponse))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }

    // Login Endpoint
    func login(email: String, password: String, completion: @escaping (Result<TokenResponse, Error>) -> Void) {
        guard let url = URL(string: "\(baseURL)/login") else {
            completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])))
            return
        }

        let request = createAuthenticatedRequest(url: url, method: "POST", body: try? JSONEncoder().encode(["email": email, "password": password]))

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            if let httpResponse = response as? HTTPURLResponse, !(200...299).contains(httpResponse.statusCode) {
                let statusError = NSError(domain: "", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "HTTP Error \(httpResponse.statusCode)"])
                completion(.failure(statusError))
                return
            }

            guard let data = data else {
                completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "No data received"])))
                return
            }

            do {
                let tokenResponse = try JSONDecoder().decode(TokenResponse.self, from: data)
                completion(.success(tokenResponse))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
}
