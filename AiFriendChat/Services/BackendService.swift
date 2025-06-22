import Foundation

// MARK: - API Models
struct UsageStats: Codable {
    let app_type: String
    let is_trial_active: Bool
    let trial_calls_remaining: Int
    let trial_calls_used: Int
    let calls_made_today: Int
    let calls_made_total: Int
    let is_subscribed: Bool
    let subscription_tier: String?
    let upgrade_recommended: Bool
    let pricing: PricingInfo?
}

struct PricingInfo: Codable {
    let weekly_plan: PricingPlan
}

struct PricingPlan: Codable {
    let price: String
    let billing: String
    let features: [String]
}

struct CallPermission: Codable {
    let can_make_call: Bool
    let status: String
    let details: CallPermissionDetails
}

struct CallPermissionDetails: Codable {
    let calls_remaining: Int?
    let trial_ends: String?
    let app_type: String?
    let message: String?
    let pricing: PricingInfo?
}

struct CallResponse: Codable {
    let call_sid: String
    let status: String
    let usage_stats: UsageStatsUpdate
}

struct UsageStatsUpdate: Codable {
    let trial_calls_remaining: Int
    let calls_made_total: Int
    let upgrade_recommended: Bool
}

struct PaymentRequiredError: Codable {
    let detail: PaymentDetail
}

struct PaymentDetail: Codable {
    let error: String
    let message: String
    let upgrade_url: String?
    let pricing: PricingInfo?
}

// MARK: - Backend Service
class BackendService: ObservableObject {
    static let shared = BackendService()
    
    private let baseURL = "https://voice.hyperlabsai.com"
    
    private init() {}
    
    // MARK: - Usage Stats
    func getUsageStats() async throws -> UsageStats {
        let url = URL(string: "\(baseURL)/mobile/usage-stats")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        // Add auth headers
        let headers = getAuthHeaders()
        headers.forEach { key, value in
            request.setValue(value, forHTTPHeaderField: key)
        }
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        if let httpResponse = response as? HTTPURLResponse {
            switch httpResponse.statusCode {
            case 200:
                return try JSONDecoder().decode(UsageStats.self, from: data)
            case 401:
                throw BackendError.unauthorized
            case 500:
                throw BackendError.serverError
            default:
                throw BackendError.unknown("HTTP \(httpResponse.statusCode)")
            }
        }
        
        throw BackendError.networkError
    }
    
    // MARK: - Call Permission Check
    func checkCallPermission() async throws -> CallPermission {
        let url = URL(string: "\(baseURL)/mobile/check-call-permission")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        // Add auth headers
        let headers = getAuthHeaders()
        headers.forEach { key, value in
            request.setValue(value, forHTTPHeaderField: key)
        }
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        if let httpResponse = response as? HTTPURLResponse {
            switch httpResponse.statusCode {
            case 200:
                return try JSONDecoder().decode(CallPermission.self, from: data)
            case 401:
                throw BackendError.unauthorized
            case 402:
                let errorData = try JSONDecoder().decode(PaymentRequiredError.self, from: data)
                throw BackendError.paymentRequired(errorData.detail)
            case 500:
                throw BackendError.serverError
            default:
                throw BackendError.unknown("HTTP \(httpResponse.statusCode)")
            }
        }
        
        throw BackendError.networkError
    }
    
    // MARK: - Make Call
    func makeCall(phoneNumber: String, scenario: String) async throws -> CallResponse {
        // First check permission
        let permission = try await checkCallPermission()
        
        if !permission.can_make_call {
            if permission.status == "trial_calls_exhausted" {
                throw BackendError.trialExhausted
            } else {
                throw BackendError.permissionDenied(permission.details.message ?? "Cannot make call")
            }
        }
        
        let url = URL(string: "\(baseURL)/mobile/make-call")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Add auth headers
        let headers = getAuthHeaders()
        headers.forEach { key, value in
            request.setValue(value, forHTTPHeaderField: key)
        }
        
        let callData = ["phone_number": phoneNumber, "scenario": scenario]
        request.httpBody = try JSONSerialization.data(withJSONObject: callData)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        if let httpResponse = response as? HTTPURLResponse {
            switch httpResponse.statusCode {
            case 200:
                return try JSONDecoder().decode(CallResponse.self, from: data)
            case 402:
                let errorData = try JSONDecoder().decode(PaymentRequiredError.self, from: data)
                throw BackendError.paymentRequired(errorData.detail)
            case 401:
                throw BackendError.unauthorized
            case 500:
                throw BackendError.serverError
            default:
                throw BackendError.unknown("HTTP \(httpResponse.statusCode)")
            }
        }
        
        throw BackendError.networkError
    }
    
    // MARK: - Helper Methods
    private func getAuthHeaders() -> [String: String] {
        guard let token = KeychainManager.shared.getToken(forKey: "accessToken") else {
            return [:]
        }
        
        return [
            "Authorization": "Bearer \(token)",
            "X-App-Type": "mobile",
            "User-Agent": "Speech-Assistant-Mobile-iOS/1.0"
        ]
    }
}

// MARK: - Backend Errors
enum BackendError: Error, LocalizedError {
    case networkError
    case unauthorized
    case serverError
    case trialExhausted
    case permissionDenied(String)
    case paymentRequired(PaymentDetail)
    case unknown(String)
    
    var errorDescription: String? {
        switch self {
        case .networkError:
            return "Network connection error. Please check your internet connection."
        case .unauthorized:
            return "Authentication failed. Please log in again."
        case .serverError:
            return "Server error. Please try again later."
        case .trialExhausted:
            return "Your trial calls have been used. Upgrade to continue making calls!"
        case .permissionDenied(let message):
            return message
        case .paymentRequired(let detail):
            return detail.message
        case .unknown(let message):
            return "Unknown error: \(message)"
        }
    }
} 