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
    func scheduleCall(phoneNumber: String, scheduledTime: Date, scenario: String) async throws -> CallSchedule {
        // Check if user can schedule call
        guard try await PurchaseManager.shared.canScheduleCall() else {
            throw NSError(domain: "", code: -1,
                        userInfo: [NSLocalizedDescriptionKey: "Scheduling calls is a premium feature. Please subscribe to schedule calls."])
        }
        
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
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw NSError(domain: "", code: -1,
                         userInfo: [NSLocalizedDescriptionKey: "Server error"])
        }
        
        return try jsonDecoder.decode(CallSchedule.self, from: data)
    }
    
    // MARK: - Make Immediate Call
    func makeCall(phoneNumber: String, scenario: String) async throws -> String {
        // Check if user can make call
        guard try await PurchaseManager.shared.canMakeCall() else {
            throw NSError(domain: "", code: -1,
                        userInfo: [NSLocalizedDescriptionKey: "You've used all your trial calls. Please subscribe to continue making calls."])
        }
        
        let url = URL(string: "\(baseURL)/make-call/\(phoneNumber)/\(scenario)")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue("Bearer \(KeychainManager.shared.getToken(forKey: "accessToken") ?? "")", forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw NSError(domain: "", code: -1,
                         userInfo: [NSLocalizedDescriptionKey: "Server error"])
        }
        
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let message = json["message"] as? String else {
            throw NSError(domain: "", code: -1,
                         userInfo: [NSLocalizedDescriptionKey: "Invalid response format"])
        }
        
        // Increment call count only after successful call
        let purchaseManager = await PurchaseManager.shared
        if !(await purchaseManager.isSubscribed) {
            await MainActor.run {
                purchaseManager.incrementCallCount()
            }
        }
        
        return message
    }
    
    // MARK: - Update User Name
    struct UpdateNameResponse: Codable {
        let message: String
    }
    
    func updateUserName(to name: String) async throws -> String {
        guard !name.isEmpty else {
            throw NSError(domain: "", code: -1,
                        userInfo: [NSLocalizedDescriptionKey: "Name cannot be empty"])
        }
        
        guard let url = URL(string: "\(baseURL)/update-user-name") else {
            throw NSError(domain: "", code: -1,
                        userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])
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
        
        request.httpBody = try JSONEncoder().encode(requestBody)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        if let httpResponse = response as? HTTPURLResponse {
            print("Status code: \(httpResponse.statusCode)")
            print("Response headers: \(httpResponse.allHeaderFields)")
        }
        
        // Print response data for debugging
        if let responseString = String(data: data, encoding: .utf8) {
            print("Response data: \(responseString)")
        }
        
        let updateResponse = try JSONDecoder().decode(UpdateNameResponse.self, from: data)
        return updateResponse.message
    }
    
    // MARK: - Fetch Scheduled Calls (Placeholder)
    func fetchScheduledCalls(completion: @escaping (Result<[CallSchedule], Error>) -> Void) {
        // Implement if necessary
    }
    
    // MARK: - Custom Scenarios
    struct CreateCustomScenarioResponse: Codable {
        let scenarioId: String
        let message: String
        
        enum CodingKeys: String, CodingKey {
            case scenarioId = "scenario_id"
            case message
        }
    }
    
    func createCustomScenario(name: String, prompt: String, persona: String, voiceType: VoiceType, temperature: Double) async throws -> String {
        let url = URL(string: "\(baseURL)/realtime/custom-scenario")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("Bearer \(KeychainManager.shared.getToken(forKey: "accessToken") ?? "")", forHTTPHeaderField: "Authorization")
        
        let body = [
            "name": name,
            "prompt": prompt,
            "persona": persona,
            "voice_type": voiceType.rawValue,
            "temperature": temperature
        ] as [String: Any]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw NSError(domain: "", code: -1,
                         userInfo: [NSLocalizedDescriptionKey: "Failed to create custom scenario"])
        }
        
        let createResponse = try JSONDecoder().decode(CreateCustomScenarioResponse.self, from: data)
        return createResponse.scenarioId
    }
    
    func makeCustomCall(phoneNumber: String, scenarioId: String) async throws -> String {
        let purchaseManager = await PurchaseManager.shared
        
        // Check subscription and trial status
        guard try await purchaseManager.canMakeCall() else {
            throw NSError(domain: "", code: -1,
                        userInfo: [NSLocalizedDescriptionKey: "You've used all your trial calls. Please subscribe to continue making calls."])
        }
        
        // Increment call count BEFORE making the call if not subscribed
        if !(await purchaseManager.isSubscribed) {
            await MainActor.run {
                purchaseManager.incrementCallCount()
            }
        }
        
        do {
            // Make the API call
            let url = URL(string: "\(baseURL)/make-custom-call/\(phoneNumber)/\(scenarioId)")!
            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            request.addValue("Bearer \(KeychainManager.shared.getToken(forKey: "accessToken") ?? "")", forHTTPHeaderField: "Authorization")
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode) else {
                // If call fails, decrement the count
                if !(await purchaseManager.isSubscribed) {
                    await MainActor.run {
                        purchaseManager.decrementCallCount()
                    }
                }
                throw NSError(domain: "", code: -1,
                             userInfo: [NSLocalizedDescriptionKey: "Failed to initiate custom call"])
            }
            
            guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let message = json["message"] as? String else {
                throw NSError(domain: "", code: -1,
                             userInfo: [NSLocalizedDescriptionKey: "Invalid response format"])
            }
            
            return message
        } catch {
            // If call fails, decrement the count
            if !(await purchaseManager.isSubscribed) {
                await MainActor.run {
                    purchaseManager.decrementCallCount()
                }
            }
            throw error
        }
    }
}
