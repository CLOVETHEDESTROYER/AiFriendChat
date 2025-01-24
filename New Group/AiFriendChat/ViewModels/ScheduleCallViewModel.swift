//
//  ScheduleCallViewModel.swift
//  AiFriendChat
//
//  Created by Carlos Alvarez on 10/19/24.
//


// ViewModels/ScheduleCallViewModel.swift
import Foundation
import SwiftUI

class ScheduleCallViewModel: ObservableObject {
    @Published var phoneNumber: String
    @Published var scheduledTime = Date()
    @Published var selectedScenario: String
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showSuccessAlert = false
    
    let scenarios = ["default", "sister_emergency", "mother_emergency"]

    private let callService = CallService.shared
    
    init(phoneNumber: String, selectedScenario: String) {
        self.phoneNumber = phoneNumber
        self.selectedScenario = scenarios.contains(selectedScenario) ? selectedScenario : "default"
    }
    
    func validatePhoneNumber() -> Bool {
        // Basic phone number validation
        let phoneRegex = "^[0-9]{10}$" // Assumes 10-digit US phone numbers
        let phonePredicate = NSPredicate(format: "SELF MATCHES %@", phoneRegex)
        return phonePredicate.evaluate(with: phoneNumber.filter { $0.isNumber })
    }
    
    func scheduleCall() {
        guard validatePhoneNumber() else {
            errorMessage = "Please enter a valid 10-digit phone number"
            return
        }
        
        guard scheduledTime > Date() else {
            errorMessage = "Please select a future time"
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        callService.scheduleCall(phoneNumber: phoneNumber, scheduledTime: scheduledTime, scenario: selectedScenario) { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                switch result {
                case .success(let callSchedule):
                    print("Call scheduled successfully: \(callSchedule)")
                    self?.errorMessage = nil
                    self?.showSuccessAlert = true
                case .failure(let error):
                    if let decodingError = error as? DecodingError,
                       case .dataCorrupted(let context) = decodingError,
                       context.codingPath.first?.stringValue == "scheduled_time" {
                        print("Ignoring date decoding error and proceeding with success")
                        self?.errorMessage = nil
                        self?.showSuccessAlert = true
                    } else {
                        print("Scheduling error: \(error)")
                        self?.errorMessage = error.localizedDescription
                    }
                }
            }
        }
    }
    
    func makeCall() {
        guard validatePhoneNumber() else {
            errorMessage = "Please enter a valid 10-digit phone number"
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        callService.makeCall(phoneNumber: phoneNumber, scenario: selectedScenario) { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                switch result {
                case .success(let message):
                    print("Call initiated: \(message)")
                    self?.showSuccessAlert = true
                case .failure(let error):
                    self?.errorMessage = error.localizedDescription
                }
            }
        }
    }
}
