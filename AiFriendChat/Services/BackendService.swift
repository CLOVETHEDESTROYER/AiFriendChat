import Foundation
import os

// MARK: - Enhanced API Models
struct UsageStats: Codable {
    let app_type: String
    let is_trial_active: Bool
    let trial_calls_remaining: Int
    let trial_calls_used: Int
    let calls_made_today: Int
    let calls_made_this_week: Int          // NEW: Weekly cycle tracking
    let calls_made_this_month: Int         // NEW: Monthly cycle tracking
    let calls_made_total: Int
    let is_subscribed: Bool
    let subscription_tier: String?
    let upgrade_recommended: Bool
    let total_call_duration_this_week: Int?    // NEW: Duration tracking
    let total_call_duration_this_month: Int?   // NEW: Duration tracking
    let addon_calls_remaining: Int?            // NEW: Addon calls
    let addon_calls_expiry: String?            // NEW: Addon expiry
    let week_start_date: String?               // NEW: Cycle start dates
    let month_start_date: String?              // NEW: Cycle start dates
}

// NEW: Enhanced pricing structure
struct PricingInfo: Codable {
    let plans: [PricingPlan]
    let addon: AddonPlan
}

struct PricingPlan: Codable {
    let id: String
    let name: String
    let price: String
    let billing: String
    let calls: String
    let duration_limit: String
    let features: [String]
}

struct AddonPlan: Codable {
    let id: String
    let name: String
    let price: String
    let calls: String
    let expires: String
    let description: String
}

struct CallPermission: Codable {
    let can_make_call: Bool
    let status: String
    let details: CallPermissionDetails
}

// NEW: Enhanced call permission with upgrade options
struct CallPermissionDetails: Codable {
    let calls_remaining_this_week: Int?
    let calls_remaining_this_month: Int?
    let duration_limit: Int?
    let app_type: String?
    let message: String?
    let upgrade_options: [UpgradeOption]?
}

struct UpgradeOption: Codable {
    let plan: String
    let price: String
    let calls: String
    let product_id: String
}

// NEW: Enhanced call response with duration limits
struct CallResponse: Codable {
    let call_sid: String
    let status: String
    let duration_limit: Int              // NEW: Duration limit for this call
    let usage_stats: UsageStatsUpdate
}

struct UsageStatsUpdate: Codable {
    let calls_remaining_this_week: Int?
    let calls_remaining_this_month: Int?
    let addon_calls_remaining: Int?
    let upgrade_recommended: Bool
}

struct PaymentRequiredError: Codable {
    let detail: PaymentDetail
}

struct PaymentDetail: Codable {
    let error: String
    let message: String
    let upgrade_options: [UpgradeOption]?
    let timestamp: String?
}

// NEW: Enhanced Scenario Model
struct Scenario: Codable, Identifiable {
    let id: String
    let name: String
    let description: String
    let icon: String
    let category: String?
    let is_family_friendly: Bool?
    let recommended_voice: String?
    let voice_temperature: Double?
}

struct ScenariosResponse: Codable {
    let scenarios: [Scenario]
}

// NEW: Purchase Response
struct PurchaseResponse: Codable {
    let success: Bool
    let message: String
    let usage_stats: UsageStats
}

struct PurchaseError: Codable {
    let detail: String
}

// MARK: - Enhanced Backend Service
class BackendService: ObservableObject {
    static let shared = BackendService()
    
    private let baseURL = "https://voice.hyperlabsai.com"
    
    private init() {}
    
    // MARK: - Enhanced Usage Stats
    func getUsageStats() async throws -> UsageStats {
        let url = URL(string: "\(baseURL)/mobile/usage-stats")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        let headers = getAuthHeaders()
        headers.forEach { key, value in
            request.setValue(value, forHTTPHeaderField: key)
        }
        
        return try await performRequest(request) { data in
            try JSONDecoder().decode(UsageStats.self, from: data)
        }
    }
    
    // MARK: - Enhanced Call Permission Check
    func checkCallPermission() async throws -> CallPermission {
        let url = URL(string: "\(baseURL)/mobile/check-call-permission")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        let headers = getAuthHeaders()
        headers.forEach { key, value in
            request.setValue(value, forHTTPHeaderField: key)
        }
        
        return try await performRequest(request) { data in
            try JSONDecoder().decode(CallPermission.self, from: data)
        }
    }
    
    // MARK: - Enhanced Make Call
    func makeCall(phoneNumber: String, scenario: String) async throws -> CallResponse {
        // First check permission
        let permission = try await checkCallPermission()
        
        if !permission.can_make_call {
            if permission.status == "trial_exhausted" {
                throw BackendError.trialExhausted
            } else {
                throw BackendError.permissionDenied(permission.details.message ?? "Cannot make call")
            }
        }
        
        let url = URL(string: "\(baseURL)/mobile/make-call")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let headers = getAuthHeaders()
        headers.forEach { key, value in
            request.setValue(value, forHTTPHeaderField: key)
        }
        
        let callData = ["phone_number": phoneNumber, "scenario": scenario]
        request.httpBody = try JSONSerialization.data(withJSONObject: callData)
        
        return try await performRequest(request) { data in
            try JSONDecoder().decode(CallResponse.self, from: data)
        }
    }
    
    // MARK: - NEW: Get Enhanced Pricing
    func getPricing() async throws -> PricingInfo {
        let url = URL(string: "\(baseURL)/mobile/pricing")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        let headers = getAuthHeaders()
        headers.forEach { key, value in
            request.setValue(value, forHTTPHeaderField: key)
        }
        
        return try await performRequest(request) { data in
            try JSONDecoder().decode(PricingInfo.self, from: data)
        }
    }
    
    // MARK: - NEW: Get Enhanced Scenarios
    func getScenarios() async throws -> [Scenario] {
        let url = URL(string: "\(baseURL)/mobile/scenarios")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        let headers = getAuthHeaders()
        headers.forEach { key, value in
            request.setValue(value, forHTTPHeaderField: key)
        }
        
        let response = try await performRequest(request) { data in
            try JSONDecoder().decode(ScenariosResponse.self, from: data)
        }
        return response.scenarios
    }
    
    // MARK: - NEW: Purchase Subscription
    func purchaseSubscription(receiptData: String, isSandbox: Bool, productId: String) async throws -> PurchaseResponse {
        let url = URL(string: "\(baseURL)/mobile/purchase-subscription")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let headers = getAuthHeaders()
        headers.forEach { key, value in
            request.setValue(value, forHTTPHeaderField: key)
        }
        
        let purchaseData: [String: Any] = [
            "receipt_data": receiptData,
            "is_sandbox": isSandbox,
            "product_id": productId
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: purchaseData)
        
        return try await performRequest(request) { data in
            try JSONDecoder().decode(PurchaseResponse.self, from: data)
        }
    }
    
    // MARK: - Helper Methods
    private func getAuthHeaders() -> [String: String] {
        guard let token = KeychainManager.shared.getToken(forKey: "accessToken") else {
            return [
                "X-App-Type": "mobile",
                "User-Agent": "Speech-Assistant-Mobile-iOS/1.0"
            ]
        }
        
        return [
            "Authorization": "Bearer \(token)",
            "X-App-Type": "mobile",
            "User-Agent": "Speech-Assistant-Mobile-iOS/1.0"
        ]
    }
    
    private func performRequest<T: Decodable>(_ request: URLRequest, decoder: @escaping (Data) throws -> T, maxRetries: Int = 1) async throws -> T {
        var attempts = 0
        while attempts <= maxRetries {
            do {
                let (data, response) = try await URLSession.shared.data(for: request)
                if let httpResponse = response as? HTTPURLResponse {
                    if httpResponse.statusCode == 401 && attempts < maxRetries {
                        try await refreshToken()
                        attempts += 1
                        continue
                    }
                    switch httpResponse.statusCode {
                    case 200:
                        return try decoder(data)
                    case 401:
                        throw BackendError.unauthorized
                    case 402:
                        let errorData = try JSONDecoder().decode(PaymentRequiredError.self, from: data)
                        throw BackendError.paymentRequired(errorData.detail)
                    case 400:
                        let errorData = try JSONDecoder().decode(PurchaseError.self, from: data)
                        throw BackendError.purchaseError(errorData.detail)
                    case 500:
                        throw BackendError.serverError
                    default:
                        throw BackendError.unknown("HTTP \(httpResponse.statusCode)")
                    }
                }
                throw BackendError.networkError
            } catch {
                os_log("Network error: %@", log: .default, type: .error, error.localizedDescription)
                attempts += 1
                if attempts > maxRetries { throw error }
            }
        }
        throw BackendError.networkError
    }
    
    private func refreshToken() async throws {
        guard let refreshToken = KeychainManager.shared.getToken(forKey: "refreshToken") else {
            throw BackendError.unauthorized
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            AuthService.shared.refreshToken(token: refreshToken) { result in
                switch result {
                case .success(let newToken):
                    KeychainManager.shared.saveToken(newToken, forKey: "accessToken")
                    continuation.resume(returning: ())
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }
}

// MARK: - Enhanced Backend Errors
enum BackendError: Error, LocalizedError {
    case networkError
    case unauthorized
    case serverError
    case trialExhausted
    case permissionDenied(String)
    case paymentRequired(PaymentDetail)
    case purchaseError(String)        // NEW: Purchase errors
    case unknown(String)
    
    var errorDescription: String? {
        switch self {
        case .networkError:
            return "Oops! Check your internet and try again."
        case .unauthorized:
            return "Session expired. Please log in again."
        case .serverError:
            return "Server is taking a break. Try later!"
        case .trialExhausted:
            return "Your trial calls have been used. Upgrade to continue making calls!"
        case .permissionDenied(let message):
            return message
        case .paymentRequired(let detail):
            return detail.message
        case .purchaseError(let message):
            return "Purchase error: \(message)"
        case .unknown(let message):
            return "Unknown error: \(message)"
        }
    }
}