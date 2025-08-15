//
//  ScheduleCallViewModel.swift
//  AiFriendChat
//
//  Created by Carlos Alvarez on 10/19/24.
//


// ViewModels/ScheduleCallViewModel.swift
import Foundation
import SwiftUI

@MainActor
class ScheduleCallViewModel: ObservableObject {
    @Published var phoneNumber: String = ""
    @Published var selectedDate: Date = Date()
    @Published var selectedScenario: String = "default"
    @Published var isCustomScenario: Bool = false
    @Published var selectedCustomPrompt: SavedPrompt?
    @Published var errorMessage: String?
    @Published var showSuccessAlert = false
    @Published var isLoading = false
    @Published var showAuthPrompt = false
    @Published var showAuthView = false
    @Published var showError = false
    @Published var showSubscriptionAlert = false
    
    private let callService = CallService.shared
    private let purchaseManager = PurchaseManager.shared
    var authViewModel: AuthViewModel?
    
    init() { }
    
    func scheduleCall() {
        guard validatePhoneNumber() else {
            errorMessage = "Please enter a valid 10-digit phone number"
            showError = true
            return
        }
        
        if !(authViewModel?.isLoggedIn ?? false) {
            showAuthPrompt = true
            return
        }
        
        Task {
            // Check subscription status first
            if !purchaseManager.isSubscribed {
                errorMessage = "Scheduling calls is a premium feature. Please subscribe to schedule calls."
                showError = true
                showSubscriptionAlert = true
                return
            }
            
            isLoading = true
            errorMessage = nil
            
            do {
                if isCustomScenario {
                    guard let prompt = selectedCustomPrompt,
                          let scenarioId = prompt.scenarioId else {
                        throw NSError(domain: "", code: -1, 
                                    userInfo: [NSLocalizedDescriptionKey: "Invalid custom scenario"])
                    }
                    
                    let formattedPhone = phoneNumber.filter { $0.isNumber }
                    
                    _ = try await callService.makeCustomCall(
                        phoneNumber: formattedPhone,
                        scenarioId: scenarioId
                    )
                    isLoading = false
                    showSuccessAlert = true
                } else {
                    let formattedPhone = phoneNumber.starts(with: "+") ? phoneNumber : "+1" + phoneNumber.filter { $0.isNumber }
                    _ = try await callService.scheduleCall(
                        phoneNumber: formattedPhone,
                        scheduledTime: selectedDate,
                        scenario: selectedScenario
                    )
                    isLoading = false
                    showSuccessAlert = true
                }
            } catch {
                isLoading = false
                errorMessage = error.localizedDescription
                showError = true
                print("Error in scheduleCall: \(error)")
            }
        }
    }
    
    private func validatePhoneNumber() -> Bool {
        // Support E.164: optional +, 1-15 digits
        let phonePattern = "^\\+?\\d{1,15}$"
        let predicate = NSPredicate(format: "SELF MATCHES %@", phonePattern)
        return predicate.evaluate(with: phoneNumber.filter { $0.isNumber || $0 == "+" })
    }
    
    func makeCall() {
        guard validatePhoneNumber() else {
            errorMessage = "Please enter a valid 10-digit phone number"
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                let formattedPhone = phoneNumber.starts(with: "+") ? phoneNumber : "+1" + phoneNumber.filter { $0.isNumber }
                let message = try await callService.makeCall(
                    phoneNumber: formattedPhone,
                    scenario: selectedScenario
                )
                isLoading = false
                showSuccessAlert = true
                print("Call initiated: \(message)")
            } catch {
                isLoading = false
                errorMessage = error.localizedDescription
                print("Call error: \(error)")
            }
        }
    }
}
