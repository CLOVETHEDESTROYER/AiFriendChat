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
        // Always use production endpoint for consistent response format and proper rate limiting
        // Debug premium can still be used for testing subscription features without bypassing limits
        
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
            print("⚠️ No access token found - user should not be able to make calls")
            return [
                "X-App-Type": "mobile",
                "User-Agent": "Speech-Assistant-Mobile-iOS/1.0"
            ]
        }
        
        print("✅ Using access token for request")
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
    
    // MARK: - Mobile Onboarding Methods
    
    /// Get onboarding status for mobile user
    func getOnboardingStatus() async throws -> OnboardingStatus {
        let request = try createAuthenticatedRequest(
            endpoint: "/onboarding/status",
            method: "GET"
        )
        
        let (data, response) = try await URLSession.shared.data(for: request)
        try handleHTTPResponse(response)
        
        // The web backend returns a complex structure, we need to adapt it for mobile
        let webResponse = try JSONSerialization.jsonObject(with: data) as? [String: Any] ?? [:]
        
        // Convert web backend response to mobile format
        return adaptWebOnboardingToMobile(webResponse)
    }
    
    /// Initialize onboarding for new mobile user (simplified)
    func initializeOnboarding() async throws -> OnboardingStatus {
        let request = try createAuthenticatedRequest(
            endpoint: "/onboarding/initialize",
            method: "POST"
        )
        
        let (data, response) = try await URLSession.shared.data(for: request)
        try handleHTTPResponse(response)
        
        let webResponse = try JSONSerialization.jsonObject(with: data) as? [String: Any] ?? [:]
        return adaptWebOnboardingToMobile(webResponse)
    }
    
    /// Complete a mobile onboarding step
    func completeOnboardingStep(_ step: OnboardingStep, data: [String: Any]? = nil) async throws -> OnboardingStepResponse {
        var requestData: [String: Any] = ["step": step.rawValue]
        if let data = data {
            requestData["data"] = data
        }
        
        let request = try createAuthenticatedRequest(
            endpoint: "/onboarding/complete-step",
            method: "POST",
            body: requestData
        )
        
        let (responseData, response) = try await URLSession.shared.data(for: request)
        try handleHTTPResponse(response)
        
        return try JSONDecoder().decode(OnboardingStepResponse.self, from: responseData)
    }
    
    /// Save user profile during onboarding
    func saveOnboardingProfile(_ profile: OnboardingProfile) async throws {
        let profileData: [String: Any] = [
            "name": profile.name,
            "phone_number": profile.phoneNumber ?? "",
            "preferred_voice": profile.preferredVoice,
            "notifications_enabled": profile.notificationsEnabled
        ]
        
        _ = try await completeOnboardingStep(.profile, data: profileData)
    }
    
    // MARK: - Enhanced Onboarding Methods
    
    /// Start anonymous onboarding (no registration required)
    func startAnonymousOnboarding() async throws -> String {
        let request = try createUnauthenticatedRequest(
            endpoint: "/onboarding/start",
            method: "POST"
        )
        
        let (data, response) = try await URLSession.shared.data(for: request)
        try handleHTTPResponse(response)
        
        let responseDict = try JSONSerialization.jsonObject(with: data) as? [String: Any] ?? [:]
        return responseDict["session_id"] as? String ?? ""
    }
    
    /// Set user name during anonymous onboarding
    func setOnboardingName(sessionId: String, name: String) async throws {
        let request = try createUnauthenticatedRequest(
            endpoint: "/onboarding/set-name?session_id=\(sessionId)",
            method: "POST",
            body: ["user_name": name]
        )
        
        let (_, response) = try await URLSession.shared.data(for: request)
        try handleHTTPResponse(response)
    }
    
    /// Select scenario during anonymous onboarding
    func selectOnboardingScenario(sessionId: String, scenario: String) async throws {
        let request = try createUnauthenticatedRequest(
            endpoint: "/onboarding/select-scenario?session_id=\(sessionId)",
            method: "POST",
            body: ["scenario_id": scenario]
        )
        
        let (_, response) = try await URLSession.shared.data(for: request)
        try handleHTTPResponse(response)
    }
    
    /// Complete anonymous onboarding
    func completeAnonymousOnboarding(sessionId: String) async throws {
        let request = try createUnauthenticatedRequest(
            endpoint: "/onboarding/complete?session_id=\(sessionId)",
            method: "POST"
        )
        
        let (_, response) = try await URLSession.shared.data(for: request)
        try handleHTTPResponse(response)
    }
    
    /// Get onboarding session status
    func getOnboardingSession(sessionId: String) async throws -> [String: Any] {
        let request = try createUnauthenticatedRequest(
            endpoint: "/onboarding/session/\(sessionId)",
            method: "GET"
        )
        
        let (data, response) = try await URLSession.shared.data(for: request)
        try handleHTTPResponse(response)
        
        return try JSONSerialization.jsonObject(with: data) as? [String: Any] ?? [:]
    }
    
    // MARK: - Private Helper Methods for Onboarding
    
    private func createAuthenticatedRequest(endpoint: String, method: String, body: [String: Any]? = nil) throws -> URLRequest {
        let url = URL(string: "\(baseURL)\(endpoint)")!
        var request = URLRequest(url: url)
        request.httpMethod = method
        
        let headers = getAuthHeaders()
        headers.forEach { key, value in
            request.setValue(value, forHTTPHeaderField: key)
        }
        
        if let body = body {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        }
        
        return request
    }
    
    private func createUnauthenticatedRequest(endpoint: String, method: String, body: [String: Any]? = nil) throws -> URLRequest {
        let url = URL(string: "\(baseURL)\(endpoint)")!
        var request = URLRequest(url: url)
        request.httpMethod = method
        
        if let body = body {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        }
        
        return request
    }
    
    private func handleHTTPResponse(_ response: URLResponse) throws {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw BackendError.networkError
        }
        
        switch httpResponse.statusCode {
        case 200...299:
            return
        case 401:
            throw BackendError.unauthorized
        case 402:
            throw BackendError.paymentRequired(PaymentDetail(error: "Payment required", message: "Payment required", upgrade_options: nil, timestamp: nil))
        case 500:
            throw BackendError.serverError
        default:
            throw BackendError.unknown("HTTP \(httpResponse.statusCode)")
        }
    }
    
    private func adaptWebOnboardingToMobile(_ webResponse: [String: Any]) -> OnboardingStatus {
        // The web backend has 4 steps: phone_setup, calendar, scenarios, welcome_call
        // We map these to our mobile steps: welcome, profile, tutorial, first_call
        
        let webSteps = webResponse["steps"] as? [String: [String: Any]] ?? [:]
        var completedSteps: [OnboardingStep] = []
        
        // Check web steps and map to mobile
        if let phoneSetup = webSteps["phoneSetup"], 
           phoneSetup["completed"] as? Bool == true {
            completedSteps.append(.welcome)
            completedSteps.append(.profile) // Profile includes basic setup
        }
        
        if let scenarios = webSteps["scenarios"],
           scenarios["completed"] as? Bool == true {
            completedSteps.append(.tutorial)
        }
        
        if let welcomeCall = webSteps["welcomeCall"],
           welcomeCall["completed"] as? Bool == true {
            completedSteps.append(.firstCall)
        }
        
        let isComplete = completedSteps.count == OnboardingStep.allCases.count
        let currentStep = completedSteps.isEmpty ? .welcome : 
                         (completedSteps.count < OnboardingStep.allCases.count ? 
                          OnboardingStep.allCases[completedSteps.count] : .firstCall)
        let progressPercentage = Double(completedSteps.count) / Double(OnboardingStep.allCases.count) * 100
        
        return OnboardingStatus(
            isComplete: isComplete,
            currentStep: currentStep,
            completedSteps: completedSteps,
            progressPercentage: progressPercentage
        )
    }
    


    func getAvailableScenarios() async throws -> [Scenario] {
        let url = URL(string: "\(baseURL)/mobile/scenarios")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        let headers = getAuthHeaders()
        headers.forEach { key, value in
            request.setValue(value, forHTTPHeaderField: key)
        }
        
        return try await performRequest(request) { data in
            let response = try JSONDecoder().decode(ScenariosResponse.self, from: data)
            return response.scenarios
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
