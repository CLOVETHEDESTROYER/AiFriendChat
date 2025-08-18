//
//  CallViewModel.swift
//  AiFriendChat
//
//  Created by Carlos Alvarez on 10/23/24.
//

import Foundation
import SwiftUI
import SwiftData

@MainActor
class CallViewModel: ObservableObject {
    @Published var isCallInProgress = false
    @Published var errorMessage: String?
    @Published var successMessage: String?
    @Published var upgradeMessage: String?
    @Published var showUpgradePrompt = false
    
    // NEW: Duration tracking
    @Published var currentCallDuration: TimeInterval = 0
    @Published var callDurationLimit: Int = 60 // Default 1 minute
    @Published var showDurationWarning = false
    
    // NEW: Enhanced usage stats
    @Published var usageStats: UsageStats?
    
    // NEW: Use enhanced services
    private let backendService = BackendService.shared
    private let purchaseManager = PurchaseManager.shared
    private let modelContext: ModelContext
    private var callTimer: Timer?
    
    // Add this property to CallViewModel
    @Published var authenticationRequired = false
    
    // Add these properties to CallViewModel
    @Published var showPremiumPrompt = false
    @Published var premiumPromptMessage = ""
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func initiateCall(phoneNumber: String, scenario: String) {
        clearMessages()
        resetCallTimer()

        guard !phoneNumber.isEmpty else {
            setErrorMessage("Please enter a phone number.")
            return
        }
        
        let formattedPhone = phoneNumber.starts(with: "+") ? phoneNumber : "+1" + phoneNumber.filter { $0.isNumber }
        
        Task {
            do {
                // NEW: Use enhanced backend service
                let response = try await backendService.makeCall(phoneNumber: formattedPhone, scenario: scenario)
                
                await MainActor.run {
                    // Set duration limit from backend response
                    self.callDurationLimit = response.duration_limit
                    self.startCallTimer()
                    self.setSuccessMessage("Call initiated successfully! Duration limit: \(response.duration_limit)s")
                    self.logCall(phoneNumber: phoneNumber, scenario: scenario, status: .completed, duration: TimeInterval(response.duration_limit))
                    
                    // Update usage stats display
                    self.updateUsageStatsFromResponse(response.usage_stats)
                    
                    // Check if user should see premium prompt - convert to UsageStats
                    let convertedStats = self.convertUsageStatsUpdateToUsageStats(response.usage_stats)
                    self.checkAndShowPremiumPrompt(usageStats: convertedStats)
                }
                
            } catch BackendError.trialExhausted {
                await MainActor.run {
                    self.upgradeMessage = "Your trial calls have been used. Upgrade to continue making calls!"
                    self.showUpgradePrompt = true
                    self.logCall(phoneNumber: phoneNumber, scenario: scenario, status: .failed)
                }
            } catch BackendError.paymentRequired(let detail) {
                await MainActor.run {
                    self.upgradeMessage = detail.message
                    self.showUpgradePrompt = true
                    self.logCall(phoneNumber: phoneNumber, scenario: scenario, status: .failed)
                }
            } catch {
                await MainActor.run {
                    self.handleCallError(error)
                    self.logCall(phoneNumber: phoneNumber, scenario: scenario, status: .failed)
                }
            }
        }
    }
    
    // NEW: Enhanced error handling
    private func handleCallError(_ error: Error) {
        print("🔴 Call initiation error: \(error.localizedDescription)")
        print("🔴 Error type: \(type(of: error))")
        
        if case BackendError.unauthorized = error {
            // Signal that authentication is required
            self.authenticationRequired = true
            self.setErrorMessage("Session expired. Please log in again.")
            return
        }
        
        let errorMessage = error.localizedDescription.lowercased()
        
        if errorMessage.contains("trial calls") || errorMessage.contains("subscribe") {
            self.upgradeMessage = error.localizedDescription
            self.showUpgradePrompt = true
        } else if errorMessage.contains("authentication") || errorMessage.contains("unauthorized") {
            self.authenticationRequired = true
            self.setErrorMessage("Session expired. Please log in again.")
        } else if errorMessage.contains("server") || errorMessage.contains("500") {
            self.setErrorMessage("Our servers are busy right now. Please try again in a moment.")
        } else if errorMessage.contains("network") {
            self.setErrorMessage("Network connection issue. Check your internet and try again.")
        } else {
            self.setErrorMessage("Something went wrong: \(error.localizedDescription)")
        }
    }
    
    // NEW: Call duration timer
    private func startCallTimer() {
        isCallInProgress = true
        callTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                
                if self.currentCallDuration >= TimeInterval(self.callDurationLimit) {
                    self.endCall()
                } else {
                    self.currentCallDuration += 1
                    
                    // Show warning when approaching limit (10 seconds before)
                    if self.currentCallDuration >= TimeInterval(self.callDurationLimit - 10) {
                        self.showDurationWarning = true
                    }
                }
            }
        }
    }
    
    // NEW: End call functionality
    func endCall() {
        callTimer?.invalidate()
        callTimer = nil
        isCallInProgress = false
        
        let finalDuration = currentCallDuration
        currentCallDuration = 0
        showDurationWarning = false
        
        setSuccessMessage("Call ended. Duration: \(Int(finalDuration))s")
    }
    
    // NEW: Reset timer
    private func resetCallTimer() {
        callTimer?.invalidate()
        callTimer = nil
        currentCallDuration = 0
        showDurationWarning = false
        isCallInProgress = false
    }
    
    // NEW: Update usage stats from backend response
    private func updateUsageStatsFromResponse(_ stats: UsageStatsUpdate) {
        // Create a partial stats update for UI display
        if let currentStats = usageStats {
            usageStats = UsageStats(
                app_type: currentStats.app_type,
                is_trial_active: currentStats.is_trial_active,
                trial_calls_remaining: currentStats.trial_calls_remaining,
                trial_calls_used: currentStats.trial_calls_used,
                calls_made_today: currentStats.calls_made_today,
                calls_made_this_week: stats.calls_remaining_this_week ?? currentStats.calls_made_this_week,
                calls_made_this_month: stats.calls_remaining_this_month ?? currentStats.calls_made_this_month,
                calls_made_total: currentStats.calls_made_total + 1,
                is_subscribed: currentStats.is_subscribed,
                subscription_tier: currentStats.subscription_tier,
                upgrade_recommended: stats.upgrade_recommended,
                total_call_duration_this_week: currentStats.total_call_duration_this_week,
                total_call_duration_this_month: currentStats.total_call_duration_this_month,
                addon_calls_remaining: stats.addon_calls_remaining,
                addon_calls_expiry: currentStats.addon_calls_expiry,
                week_start_date: currentStats.week_start_date,
                month_start_date: currentStats.month_start_date
            )
        }
    }
    
    // NEW: Load usage stats from backend
    func loadUsageStats() async {
        do {
            let stats = try await backendService.getUsageStats()
            await MainActor.run {
                self.usageStats = stats
            }
        } catch {
            print("Failed to load usage stats: \(error)")
        }
    }
    
    // NEW: Get remaining calls from backend
    func getRemainingCalls() async -> Int {
        do {
            let stats = try await backendService.getUsageStats()
            return stats.trial_calls_remaining
        } catch {
            print("Failed to get remaining calls: \(error)")
            return 0
        }
    }
    
    // NEW: Check if user can make calls
    func canMakeCall() async -> Bool {
        do {
            let permission = try await backendService.checkCallPermission()
            return permission.can_make_call
        } catch {
            print("Failed to check call permission: \(error)")
            return false
        }
    }

    private func setErrorMessage(_ message: String) {
        DispatchQueue.main.async {
            self.errorMessage = message
            self.successMessage = nil
        }
    }

    private func setSuccessMessage(_ message: String) {
        DispatchQueue.main.async {
            self.successMessage = message
            self.errorMessage = nil
        }
    }

    private func clearMessages() {
        DispatchQueue.main.async {
            self.errorMessage = nil
            self.successMessage = nil
            self.upgradeMessage = nil
            self.showUpgradePrompt = false
        }
    }

    private func logCall(phoneNumber: String, scenario: String, status: CallStatus, duration: TimeInterval = 0) {
        let callHistory = CallHistory(phoneNumber: phoneNumber, scenario: scenario, status: status, duration: duration)
        modelContext.insert(callHistory)
        try? modelContext.save()
    }

    private func checkAndShowPremiumPrompt(usageStats: UsageStats?) {
        Task { @MainActor in
            // Show premium prompt if user is not subscribed and has used trial calls
            let purchaseManager = PurchaseManager.shared
            guard !purchaseManager.isSubscribed else { return }
            
            if let stats = usageStats {
                let remainingCalls = stats.trial_calls_remaining
                if remainingCalls <= 1 {
                    self.premiumPromptMessage = remainingCalls == 0 ? 
                        "🎉 Great call! You've used all your trial calls. Upgrade to Premium for unlimited calls!" :
                        "🎉 Great call! You have \(remainingCalls) trial call remaining. Upgrade to Premium for unlimited calls!"
                    self.showPremiumPrompt = true
                }
            }
        }
    }

    // Fix 4: Add conversion helper method
    private func convertUsageStatsUpdateToUsageStats(_ update: UsageStatsUpdate) -> UsageStats? {
        // Convert UsageStatsUpdate to UsageStats for compatibility
        guard let currentStats = usageStats else { return nil }
        
        return UsageStats(
            app_type: currentStats.app_type,
            is_trial_active: currentStats.is_trial_active,
            trial_calls_remaining: update.calls_remaining_this_week ?? currentStats.trial_calls_remaining,
            trial_calls_used: currentStats.trial_calls_used + 1,
            calls_made_today: currentStats.calls_made_today + 1,
            calls_made_this_week: currentStats.calls_made_this_week + 1,
            calls_made_this_month: currentStats.calls_made_this_month + 1,
            calls_made_total: currentStats.calls_made_total + 1,
            is_subscribed: currentStats.is_subscribed,
            subscription_tier: currentStats.subscription_tier,
            upgrade_recommended: update.upgrade_recommended,
            total_call_duration_this_week: currentStats.total_call_duration_this_week,
            total_call_duration_this_month: currentStats.total_call_duration_this_month,
            addon_calls_remaining: update.addon_calls_remaining,
            addon_calls_expiry: currentStats.addon_calls_expiry,
            week_start_date: currentStats.week_start_date,
            month_start_date: currentStats.month_start_date
        )
    }
}