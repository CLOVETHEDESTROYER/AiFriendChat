//
//  CallViewModel.swift
//  AiFriendChat
//
//  Created by Carlos Alvarez on 10/23/24.
//

import Foundation
import SwiftUICore

class CallViewModel: ObservableObject {
    @Published var isCallInProgress = false
    @Published var errorMessage: String?
    @Published var successMessage: String?
    @Published var showUpgradePrompt = false
    @Published var upgradeMessage = ""
    
    private let backendService = BackendService.shared
    private let purchaseManager = PurchaseManager.shared

    func initiateCall(phoneNumber: String, scenario: String) {
        clearMessages()

        guard !phoneNumber.isEmpty else {
            setErrorMessage("Please enter a phone number.")
            return
        }

        performCall(phoneNumber: phoneNumber, scenario: scenario)
    }

    private func performCall(phoneNumber: String, scenario: String) {
        isCallInProgress = true

        Task {
            do {
                let response = try await backendService.makeCall(phoneNumber: phoneNumber, scenario: scenario)
                
                await MainActor.run {
                    self.isCallInProgress = false
                    self.setSuccessMessage("Call initiated successfully! Call SID: \(response.call_sid)")
                    
                    // Update local call count if not subscribed
                    if !self.purchaseManager.isSubscribed {
                        self.purchaseManager.incrementCallCount()
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
}
