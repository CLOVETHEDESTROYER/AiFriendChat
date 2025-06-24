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
    
    private let backendService = CallService.shared
    private let purchaseManager = PurchaseManager.shared
    private let modelContext: ModelContext
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func initiateCall(phoneNumber: String, scenario: String) {
        clearMessages()

        guard !phoneNumber.isEmpty else {
            setErrorMessage("Please enter a phone number.")
            return
        }
        
        Task {
            // First check if user can make call
            let remainingCalls = purchaseManager.getRemainingTrialCalls()
            
            if !purchaseManager.isSubscribed && remainingCalls <= 0 {
                setErrorMessage("You've used all your trial calls. Please subscribe to continue making calls.")
                return
            }
            
            // Increment call count BEFORE making the call if not subscribed
            if !purchaseManager.isSubscribed {
                purchaseManager.incrementCallCount()
            }
            
            if scenario.hasPrefix("custom_") {
                // Extract the prompt name from the scenario string
                let promptName = String(scenario.dropFirst("custom_".count))
                
                // Find the saved prompt in SwiftData
                let descriptor = FetchDescriptor<SavedPrompt>(
                    predicate: #Predicate<SavedPrompt> { prompt in
                        prompt.name == promptName
                    }
                )
                
                guard let savedPrompt = try? modelContext.fetch(descriptor).first,
                      let scenarioId = savedPrompt.scenarioId else {
                    setErrorMessage("Custom scenario not found")
                    return
                }
                
                // Use the makeCustomCall endpoint
                do {
                    let message = try await CallService.shared.makeCustomCall(
                        phoneNumber: phoneNumber,
                        scenarioId: scenarioId
                    )
                    setSuccessMessage(message)
                    logCall(phoneNumber: phoneNumber, scenario: scenario, status: .completed)
                } catch {
                    // If call fails, decrement the count
                    if !purchaseManager.isSubscribed {
                        purchaseManager.decrementCallCount()
                    }
                    setErrorMessage(error.localizedDescription)
                    logCall(phoneNumber: phoneNumber, scenario: scenario, status: .failed)
                }
            } else {
                // Handle regular scenarios
                performCall(phoneNumber: phoneNumber, scenario: scenario)
            }
        }
    }

    private func performCall(phoneNumber: String, scenario: String) {
        isCallInProgress = true

        Task {
            do {
                let response = try await CallService.shared.makeCall(phoneNumber: phoneNumber, scenario: scenario)
                
                await MainActor.run {
                    self.isCallInProgress = false
                    self.setSuccessMessage("Call initiated successfully!")
                }
                
            } catch {
                await MainActor.run {
                    self.isCallInProgress = false
                    
                    // Handle specific error messages
                    let errorMessage = error.localizedDescription
                    if errorMessage.contains("trial calls") || errorMessage.contains("subscribe") {
                        self.upgradeMessage = errorMessage
                        self.showUpgradePrompt = true
                    } else if errorMessage.contains("authentication") || errorMessage.contains("unauthorized") {
                        self.setErrorMessage("Authentication failed. Please log in again.")
                    } else if errorMessage.contains("server") {
                        self.setErrorMessage("Server error. Please try again later.")
                    } else if errorMessage.contains("network") {
                        self.setErrorMessage("Network connection error. Please check your internet connection.")
                    } else {
                        self.setErrorMessage("Unexpected error: \(errorMessage)")
                    }
                }
            }
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
        }
    }

    private func canMakeCall() async -> Bool {
        return purchaseManager.getRemainingTrialCalls() > 0 || purchaseManager.isSubscribed
    }

    private func getRemainingTrialCalls() -> Int {
        return purchaseManager.getRemainingTrialCalls()
    }

    private func logCall(phoneNumber: String, scenario: String, status: CallStatus) {
        let callHistory = CallHistory(phoneNumber: phoneNumber, scenario: scenario, status: status)
        modelContext.insert(callHistory)
        try? modelContext.save()
    }
}
