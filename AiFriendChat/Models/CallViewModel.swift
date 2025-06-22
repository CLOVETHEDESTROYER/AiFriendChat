//
//  CallViewModel.swift
//  AiFriendChat
//
//  Created by Carlos Alvarez on 10/23/24.
//

import Foundation
import SwiftUICore
import SwiftData

@MainActor
class CallViewModel: ObservableObject {
    @Published var isCallInProgress = false
    @Published var errorMessage: String?
    @Published var successMessage: String?
    @Published var showUpgradePrompt = false
    @Published var upgradeMessage = ""
    
    private let backendService = BackendService.shared
    private let purchaseManager = PurchaseManager.shared
    private let modelContext: ModelContext
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func initiateCall(phoneNumber: String, scenario: String) {
        clearMessages()
<<<<<<< HEAD

        guard !phoneNumber.isEmpty else {
            setErrorMessage("Please enter a phone number.")
            return
=======
        
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
                        // Add method to decrement call count
                        purchaseManager.decrementCallCount()
                    }
                    setErrorMessage(error.localizedDescription)
                    logCall(phoneNumber: phoneNumber, scenario: scenario, status: .failed)
                }
            } else {
                // Handle regular scenarios as before
                performCall(phoneNumber: phoneNumber, scenario: scenario)
            }
>>>>>>> webrtc-integration
        }
    }

    private func performCall(phoneNumber: String, scenario: String) {
        isCallInProgress = true

<<<<<<< HEAD
        Task {
            do {
                let response = try await backendService.makeCall(phoneNumber: phoneNumber, scenario: scenario)
                
                await MainActor.run {
                    self.isCallInProgress = false
                    self.setSuccessMessage("Call initiated successfully! Call SID: \(response.call_sid)")
                    
                    // Update local call count if not subscribed
                    if !self.purchaseManager.isSubscribed {
                        self.purchaseManager.incrementCallCount()
=======
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue("Bearer \(KeychainManager.shared.getToken(forKey: "accessToken") ?? "")", forHTTPHeaderField: "Authorization")

        print("Initiating call to URL: \(url.absoluteString)")

        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            guard let self = self else { return }
            DispatchQueue.main.async {
                self.isCallInProgress = false
                if let error = error {
                    self.setErrorMessage("Network error: \(error.localizedDescription)")
                    self.logCall(phoneNumber: phoneNumber, scenario: scenario, status: .failed)
                } else if let httpResponse = response as? HTTPURLResponse {
                    print("Received response with status code: \(httpResponse.statusCode)")
                    switch httpResponse.statusCode {
                    case 200:
                        if let data = data, let responseString = String(data: data, encoding: .utf8) {
                            print("Server response: \(responseString)")
                            self.setSuccessMessage("Call initiated successfully")
                            self.logCall(phoneNumber: phoneNumber, scenario: scenario, status: .completed)
                        }
                    case 401:
                        self.setErrorMessage("Unauthorized: Please log in again")
                        self.logCall(phoneNumber: phoneNumber, scenario: scenario, status: .failed)
                    default:
                        self.setErrorMessage("Server error: Status code \(httpResponse.statusCode)")
                        self.logCall(phoneNumber: phoneNumber, scenario: scenario, status: .failed)
>>>>>>> webrtc-integration
                    }
                }
                
            } catch BackendError.trialExhausted {
                await MainActor.run {
                    self.isCallInProgress = false
                    self.upgradeMessage = "Your trial calls have been used. Upgrade to continue making calls!"
                    self.showUpgradePrompt = true
                }
                
            } catch BackendError.paymentRequired(let detail) {
                await MainActor.run {
                    self.isCallInProgress = false
                    self.upgradeMessage = detail.message
                    self.showUpgradePrompt = true
                }
                
            } catch BackendError.permissionDenied(let message) {
                await MainActor.run {
                    self.isCallInProgress = false
                    self.setErrorMessage(message)
                }
                
            } catch BackendError.unauthorized {
                await MainActor.run {
                    self.isCallInProgress = false
                    self.setErrorMessage("Authentication failed. Please log in again.")
                }
                
            } catch BackendError.serverError {
                await MainActor.run {
                    self.isCallInProgress = false
                    self.setErrorMessage("Server error. Please try again later.")
                }
                
            } catch BackendError.networkError {
                await MainActor.run {
                    self.isCallInProgress = false
                    self.setErrorMessage("Network connection error. Please check your internet connection.")
                }
                
            } catch {
                await MainActor.run {
                    self.isCallInProgress = false
                    self.setErrorMessage("Unexpected error: \(error.localizedDescription)")
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
