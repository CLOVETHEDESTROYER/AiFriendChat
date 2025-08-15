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
        // Use the backend service instead of direct API calls
        let backendService = BackendService.shared
        
        do {
            let response = try await backendService.makeCall(phoneNumber: phoneNumber, scenario: scenario)
            
            // The backend handles trial tracking, so we just need to sync the response
            await MainActor.run {
                // Update local purchase manager with backend response
                if !PurchaseManager.shared.isSubscribed {
                    // The backend now handles all usage tracking
                    // We can trigger a refresh of the purchase manager if needed
                    PurchaseManager.shared.objectWillChange.send()
                }
            }
            
            return response.call_sid
            
        } catch BackendError.trialExhausted {
            throw NSError(domain: "", code: -1,
                        userInfo: [NSLocalizedDescriptionKey: "You've used all your trial calls. Please subscribe to continue making calls."])
        } catch let backendError as BackendError {
            if case .paymentRequired(let detail) = backendError {
                throw NSError(domain: "", code: -1,
                            userInfo: [NSLocalizedDescriptionKey: detail.message])
            } else {
                throw backendError
            }
        } catch {
            throw error
        }
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
        
        // TEMPORARY SOLUTION: The mobile backend doesn't have a dedicated username update endpoint
        // For now, we'll store the name locally and simulate a successful update
        // This will be enhanced when the backend adds user profile management
        
        print("📝 Updating username locally to: \(name)")
        
        // Simulate network delay for better UX
        try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
        
        // Store the name locally
        UserDefaults.standard.set(name, forKey: "userName")
        
        // Return success message
        return "Name updated successfully! (stored locally)"
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
        // For now, use regular call endpoint since mobile/make-call handles scenarios
        return try await makeCall(phoneNumber: phoneNumber, scenario: scenarioId)
    }
}
