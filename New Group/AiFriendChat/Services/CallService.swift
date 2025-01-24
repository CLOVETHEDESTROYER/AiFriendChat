//
//  CallService.swift
//  AiFriendChat
//
//  Created by Carlos Alvarez on 10/19/24.
//

import Foundation

@available(iOS 17, *)
class CallService {
    static let shared = CallService()
    private let baseURL: String = "https://voice.hyperlabsai.com"
    
    private lazy var jsonDecoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let dateString = try container.decode(String.self)
            
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            
            if let date = formatter.date(from: dateString) {
                return date
            }
            
            formatter.formatOptions = [.withInternetDateTime]
            if let date = formatter.date(from: dateString) {
                return date
            }
            
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Cannot decode date string \(dateString)")
        }
        return decoder
    }()
    
    // MARK: - Schedule a Call
    func scheduleCall(phoneNumber: String, scheduledTime: Date, scenario: String, completion: @escaping (Result<CallSchedule, Error>) -> Void) {
        let url = URL(string: "\(baseURL)/schedule-call")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("Bearer \(KeychainManager.shared.getToken(forKey: "accessToken") ?? "")", forHTTPHeaderField: "Authorization")
        
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withInternetDateTime]
        
        let body: [String: Any] = [
            "phone_number": phoneNumber,
            "scheduled_time": dateFormatter.string(from: scheduledTime),
            "scenario": scenario
        ]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "No data received"])))
                return
            }
            
            do {
                let callSchedule = try self.jsonDecoder.decode(CallSchedule.self, from: data)
                completion(.success(callSchedule))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
    
    // MARK: - Make Immediate Call
    func makeCall(phoneNumber: String, scenario: String, completion: @escaping (Result<String, Error>) -> Void) {
        let url = URL(string: "\(baseURL)/make-call/\(phoneNumber)/\(scenario)")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue("Bearer \(KeychainManager.shared.getToken(forKey: "accessToken") ?? "")", forHTTPHeaderField: "Authorization")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "No data received"])))
                return
            }
            
            do {
                let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
                if let message = json?["message"] as? String {
                    completion(.success(message))
                } else {
                    completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid response format"])))
                }
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
    
    // MARK: - Update User Name
    func updateUserName(to name: String, completion: @escaping (Result<String, Error>) -> Void) {
        guard !name.isEmpty else {
            completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Name cannot be empty"])))
            return
        }
        
        guard let url = URL(string: "\(baseURL)/update-user-name") else {
            completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Add authorization header
        if let token = KeychainManager.shared.getToken(forKey: "accessToken") {
            request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        // Create the correct request body format
        let requestBody = name  // Send just the string, not a dictionary
        
        do {
            let jsonData = try JSONEncoder().encode(requestBody)
            request.httpBody = jsonData
        } catch {
            completion(.failure(error))
            return
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse {
                print("Status code: \(httpResponse.statusCode)")
                // Print response headers for debugging
                print("Response headers: \(httpResponse.allHeaderFields)")
            }
            
            guard let data = data else {
                completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "No data received"])))
                return
            }
            
            // Print response data for debugging
            if let responseString = String(data: data, encoding: .utf8) {
                print("Response data: \(responseString)")
            }
            
            do {
                let response = try JSONDecoder().decode(UpdateNameResponse.self, from: data)
                completion(.success(response.message))
            } catch {
                print("Decoding error: \(error)")
                completion(.failure(error))
            }
        }.resume()
    }
    // Response model to match the backend response
    struct UpdateNameResponse: Codable {
        let message: String
    }
    
    // MARK: - Fetch Scheduled Calls (Placeholder)
    func fetchScheduledCalls(completion: @escaping (Result<[CallSchedule], Error>) -> Void) {
        // Implement if necessary
    }
}
