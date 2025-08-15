//
//  EnhancedAiFriendChatTests.swift
//  AiFriendChatTests
//
//  Created by AI Assistant on 2025-01-16
//

import XCTest
@testable import AiFriendChat

final class EnhancedAiFriendChatTests: XCTestCase {
    
    var backendService: BackendService!
    var keychainManager: KeychainManager!
    
    override func setUpWithError() throws {
        backendService = BackendService.shared
        keychainManager = KeychainManager.shared
    }
    
    override func tearDownWithError() throws {
        // Clean up any test data
    }
    
    // MARK: - Enhanced UsageStats Tests
    
    func testEnhancedUsageStatsDecoding() throws {
        let jsonData = """
        {
            "app_type": "mobile_consumer",
            "is_trial_active": true,
            "trial_calls_remaining": 2,
            "trial_calls_used": 1,
            "calls_made_today": 1,
            "calls_made_this_week": 3,
            "calls_made_this_month": 8,
            "calls_made_total": 15,
            "is_subscribed": false,
            "subscription_tier": null,
            "upgrade_recommended": false,
            "total_call_duration_this_week": 180,
            "total_call_duration_this_month": 450,
            "addon_calls_remaining": 0,
            "addon_calls_expiry": null,
            "week_start_date": "2024-01-15T10:30:00Z",
            "month_start_date": "2024-01-15T10:30:00Z"
        }
        """.data(using: .utf8)!
        
        let usageStats = try JSONDecoder().decode(UsageStats.self, from: jsonData)
        
        XCTAssertEqual(usageStats.app_type, "mobile_consumer")
        XCTAssertTrue(usageStats.is_trial_active)
        XCTAssertEqual(usageStats.trial_calls_remaining, 2)
        XCTAssertEqual(usageStats.calls_made_this_week, 3)
        XCTAssertEqual(usageStats.calls_made_this_month, 8)
        XCTAssertEqual(usageStats.total_call_duration_this_week, 180)
        XCTAssertEqual(usageStats.total_call_duration_this_month, 450)
        XCTAssertEqual(usageStats.addon_calls_remaining, 0)
    }
    
    func testEnhancedPricingInfoDecoding() throws {
        let jsonData = """
        {
            "plans": [
                {
                    "id": "basic",
                    "name": "Basic Plan",
                    "price": "$4.99",
                    "billing": "weekly",
                    "calls": "5 calls per week",
                    "duration_limit": "1 minute per call",
                    "features": ["Unlimited scenarios", "Call history", "Basic support"]
                },
                {
                    "id": "premium",
                    "name": "Premium Plan",
                    "price": "$25.00",
                    "billing": "monthly",
                    "calls": "30 calls per month",
                    "duration_limit": "2 minutes per call",
                    "features": ["All Basic features", "Priority support", "Advanced analytics"]
                }
            ],
            "addon": {
                "id": "addon",
                "name": "Additional Calls",
                "price": "$4.99",
                "calls": "5 additional calls",
                "expires": "30 days",
                "description": "Perfect when you need a few more calls"
            }
        }
        """.data(using: .utf8)!
        
        let pricingInfo = try JSONDecoder().decode(PricingInfo.self, from: jsonData)
        
        XCTAssertEqual(pricingInfo.plans.count, 2)
        XCTAssertEqual(pricingInfo.plans.first?.id, "basic")
        XCTAssertEqual(pricingInfo.plans.first?.price, "$4.99")
        XCTAssertEqual(pricingInfo.plans.last?.id, "premium")
        XCTAssertEqual(pricingInfo.plans.last?.price, "$25.00")
        XCTAssertEqual(pricingInfo.addon.price, "$4.99")
        XCTAssertEqual(pricingInfo.addon.calls, "5 additional calls")
    }
    
    func testEnhancedScenarioDecoding() throws {
        let jsonData = """
        {
            "id": "default",
            "name": "Friendly Chat",
            "description": "A casual, friendly conversation",
            "icon": "💬",
            "category": "entertainment",
            "is_family_friendly": true,
            "recommended_voice": "alloy",
            "voice_temperature": 0.7
        }
        """.data(using: .utf8)!
        
        let scenario = try JSONDecoder().decode(Scenario.self, from: jsonData)
        
        XCTAssertEqual(scenario.id, "default")
        XCTAssertEqual(scenario.name, "Friendly Chat")
        XCTAssertEqual(scenario.category, "entertainment")
        XCTAssertEqual(scenario.is_family_friendly, true)
        XCTAssertEqual(scenario.recommended_voice, "alloy")
        XCTAssertEqual(scenario.voice_temperature, 0.7)
    }
    
    func testCallResponseWithDurationLimit() throws {
        let jsonData = """
        {
            "call_sid": "CA1234567890abcdef",
            "status": "initiated",
            "duration_limit": 120,
            "usage_stats": {
                "calls_remaining_this_week": 4,
                "calls_remaining_this_month": 29,
                "addon_calls_remaining": 0,
                "upgrade_recommended": false
            }
        }
        """.data(using: .utf8)!
        
        let callResponse = try JSONDecoder().decode(CallResponse.self, from: jsonData)
        
        XCTAssertEqual(callResponse.call_sid, "CA1234567890abcdef")
        XCTAssertEqual(callResponse.status, "initiated")
        XCTAssertEqual(callResponse.duration_limit, 120)
        XCTAssertEqual(callResponse.usage_stats.calls_remaining_this_week, 4)
        XCTAssertEqual(callResponse.usage_stats.calls_remaining_this_month, 29)
        XCTAssertFalse(callResponse.usage_stats.upgrade_recommended)
    }
    
    // MARK: - Enhanced Error Handling Tests
    
    func testEnhancedBackendErrorMessages() {
        let networkError = BackendError.networkError
        XCTAssertEqual(networkError.errorDescription, "Oops! Check your internet and try again.")
        
        let unauthorizedError = BackendError.unauthorized
        XCTAssertEqual(unauthorizedError.errorDescription, "Session expired. Please log in again.")
        
        let trialExhaustedError = BackendError.trialExhausted
        XCTAssertEqual(trialExhaustedError.errorDescription, "Your trial calls have been used. Upgrade to continue making calls!")
        
        let purchaseError = BackendError.purchaseError("Invalid receipt")
        XCTAssertEqual(purchaseError.errorDescription, "Purchase error: Invalid receipt")
        
        let serverError = BackendError.serverError
        XCTAssertEqual(serverError.errorDescription, "Server is taking a break. Try later!")
    }
    
    func testPaymentRequiredErrorDecoding() throws {
        let jsonData = """
        {
            "detail": {
                "error": "trial_exhausted",
                "message": "Trial calls exhausted. Upgrade to Basic ($4.99/week) for 5 calls per week!",
                "upgrade_options": [
                    {
                        "plan": "basic",
                        "price": "$4.99",
                        "calls": "5/week",
                        "product_id": "speech_assistant_basic_weekly"
                    }
                ],
                "timestamp": "2024-01-15T10:30:00Z"
            }
        }
        """.data(using: .utf8)!
        
        let paymentError = try JSONDecoder().decode(PaymentRequiredError.self, from: jsonData)
        
        XCTAssertEqual(paymentError.detail.error, "trial_exhausted")
        XCTAssertEqual(paymentError.detail.upgrade_options?.count, 1)
        XCTAssertEqual(paymentError.detail.upgrade_options?.first?.product_id, "speech_assistant_basic_weekly")
    }
    
    // MARK: - Call Permission Tests
    
    func testCallPermissionDecoding() throws {
        let jsonData = """
        {
            "can_make_call": true,
            "status": "basic_call_available",
            "details": {
                "calls_remaining_this_week": 4,
                "calls_remaining_this_month": 29,
                "duration_limit": 60,
                "app_type": "mobile_consumer",
                "message": "You have 4 calls remaining this week"
            }
        }
        """.data(using: .utf8)!
        
        let permission = try JSONDecoder().decode(CallPermission.self, from: jsonData)
        
        XCTAssertTrue(permission.can_make_call)
        XCTAssertEqual(permission.status, "basic_call_available")
        XCTAssertEqual(permission.details.calls_remaining_this_week, 4)
        XCTAssertEqual(permission.details.duration_limit, 60)
        XCTAssertEqual(permission.details.message, "You have 4 calls remaining this week")
    }
    
    // MARK: - Scenarios Tests
    
    func testScenariosResponseDecoding() throws {
        let jsonData = """
        {
            "scenarios": [
                {
                    "id": "default",
                    "name": "Friendly Chat",
                    "description": "A casual, friendly conversation",
                    "icon": "💬",
                    "category": "entertainment",
                    "is_family_friendly": true,
                    "recommended_voice": "alloy",
                    "voice_temperature": 0.7
                },
                {
                    "id": "comedian",
                    "name": "Stand-up Comedian",
                    "description": "Funny jokes and comedy bits",
                    "icon": "😂",
                    "category": "entertainment",
                    "is_family_friendly": true,
                    "recommended_voice": "ash",
                    "voice_temperature": 0.8
                }
            ]
        }
        """.data(using: .utf8)!
        
        let response = try JSONDecoder().decode(ScenariosResponse.self, from: jsonData)
        
        XCTAssertEqual(response.scenarios.count, 2)
        XCTAssertEqual(response.scenarios.first?.id, "default")
        XCTAssertEqual(response.scenarios.last?.id, "comedian")
    }
    
    // MARK: - Performance Tests
    
    func testEnhancedUsageStatsPerformance() throws {
        let jsonData = """
        {
            "app_type": "mobile_consumer",
            "is_trial_active": true,
            "trial_calls_remaining": 2,
            "trial_calls_used": 1,
            "calls_made_today": 1,
            "calls_made_this_week": 3,
            "calls_made_this_month": 8,
            "calls_made_total": 15,
            "is_subscribed": false,
            "subscription_tier": null,
            "upgrade_recommended": false,
            "total_call_duration_this_week": 180,
            "total_call_duration_this_month": 450,
            "addon_calls_remaining": 0,
            "addon_calls_expiry": null,
            "week_start_date": "2024-01-15T10:30:00Z",
            "month_start_date": "2024-01-15T10:30:00Z"
        }
        """.data(using: .utf8)!
        
        measure {
            do {
                _ = try JSONDecoder().decode(UsageStats.self, from: jsonData)
            } catch {
                XCTFail("Decoding failed: \(error)")
            }
        }
    }
    
    func testScenarioDecodingPerformance() throws {
        // Test with multiple scenarios
        let scenarios = Array(repeating: """
        {
            "id": "default",
            "name": "Friendly Chat",
            "description": "A casual, friendly conversation",
            "icon": "💬",
            "category": "entertainment",
            "is_family_friendly": true,
            "recommended_voice": "alloy",
            "voice_temperature": 0.7
        }
        """, count: 25).joined(separator: ",")
        
        let jsonData = """
        {
            "scenarios": [\(scenarios)]
        }
        """.data(using: .utf8)!
        
        measure {
            do {
                _ = try JSONDecoder().decode(ScenariosResponse.self, from: jsonData)
            } catch {
                XCTFail("Decoding failed: \(error)")
            }
        }
    }
    
    // MARK: - Integration Tests (require backend)
    
    func testBackendConnectionFlow() async throws {
        // This test requires a valid token and backend connection
        // In a real test environment, you'd mock the network calls
        
        do {
            _ = try await backendService.checkCallPermission()
            // If we get here, the API call succeeded
        } catch {
            // Expected in test environment without valid backend
            XCTAssertTrue(error is BackendError)
        }
    }
    
    // MARK: - Mock Data Helpers
    
    func testMockDataCreation() {
        let mockStats = createMockUsageStats()
        
        XCTAssertEqual(mockStats.app_type, "mobile_consumer")
        XCTAssertTrue(mockStats.is_trial_active)
        XCTAssertEqual(mockStats.trial_calls_remaining, 3)
        XCTAssertFalse(mockStats.is_subscribed)
        
        let mockScenarios = createMockScenarios()
        XCTAssertEqual(mockScenarios.count, 2)
        XCTAssertEqual(mockScenarios.first?.id, "default")
        XCTAssertEqual(mockScenarios.last?.id, "comedian")
    }
}

// MARK: - Mock Data Factory

extension EnhancedAiFriendChatTests {
    
    func createMockUsageStats() -> UsageStats {
        return UsageStats(
            app_type: "mobile_consumer",
            is_trial_active: true,
            trial_calls_remaining: 3,
            trial_calls_used: 0,
            calls_made_today: 0,
            calls_made_this_week: 0,
            calls_made_this_month: 0,
            calls_made_total: 0,
            is_subscribed: false,
            subscription_tier: nil,
            upgrade_recommended: false,
            total_call_duration_this_week: 0,
            total_call_duration_this_month: 0,
            addon_calls_remaining: 0,
            addon_calls_expiry: nil,
            week_start_date: "2024-01-15T10:30:00Z",
            month_start_date: "2024-01-15T10:30:00Z"
        )
    }
    
    func createMockScenarios() -> [Scenario] {
        return [
            Scenario(
                id: "default",
                name: "Friendly Chat",
                description: "A casual, friendly conversation",
                icon: "💬",
                category: "entertainment",
                is_family_friendly: true,
                recommended_voice: "alloy",
                voice_temperature: 0.7
            ),
            Scenario(
                id: "comedian",
                name: "Stand-up Comedian",
                description: "Funny jokes and comedy bits",
                icon: "😂",
                category: "entertainment",
                is_family_friendly: true,
                recommended_voice: "ash",
                voice_temperature: 0.8
            )
        ]
    }
    
    func createMockPricingInfo() -> PricingInfo {
        return PricingInfo(
            plans: [
                PricingPlan(
                    id: "basic",
                    name: "Basic Plan",
                    price: "$4.99",
                    billing: "weekly",
                    calls: "5 calls per week",
                    duration_limit: "1 minute per call",
                    features: ["Unlimited scenarios", "Call history", "Basic support"]
                ),
                PricingPlan(
                    id: "premium",
                    name: "Premium Plan",
                    price: "$25.00",
                    billing: "monthly",
                    calls: "30 calls per month",
                    duration_limit: "2 minutes per call",
                    features: ["All Basic features", "Priority support", "Advanced analytics"]
                )
            ],
            addon: AddonPlan(
                id: "addon",
                name: "Additional Calls",
                price: "$4.99",
                calls: "5 additional calls",
                expires: "30 days",
                description: "Perfect when you need a few more calls"
            )
        )
    }
}
