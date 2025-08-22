//
//  OnboardingViewModel.swift
//  AiFriendChat
//
//  Created by AI Assistant
//

import Foundation
import SwiftUI

@MainActor
class OnboardingViewModel: ObservableObject {
    @Published var onboardingStatus: OnboardingStatus?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var currentStepIndex = 0
    @Published var showCompletionMessage = false
    @Published var completionMessage = ""
    
    // Profile data
    @Published var userName = ""
    @Published var userPhone = ""
    @Published var selectedVoice = "alloy"
    @Published var notificationsEnabled = true
    
    private let backendService = BackendService.shared
    private let allSteps = OnboardingStep.allCases
    
    var currentStep: OnboardingStep {
        return onboardingStatus?.currentStep ?? .welcome
    }
    
    var progressPercentage: Double {
        return onboardingStatus?.progressPercentage ?? 0
    }
    
    var isOnboardingComplete: Bool {
        return onboardingStatus?.isComplete ?? false
    }
    
    // MARK: - Initialization
    
    func initializeOnboarding() async {
        isLoading = true
        errorMessage = nil
        
        do {
            // Try to get existing onboarding status first
            onboardingStatus = try await backendService.getOnboardingStatus()
        } catch {
            // If no onboarding exists, initialize it
            do {
                onboardingStatus = try await backendService.initializeOnboarding()
            } catch {
                errorMessage = "Failed to initialize onboarding: \(error.localizedDescription)"
                print("Onboarding initialization error: \(error)")
                
                // Create a default onboarding status for offline/testing
                createDefaultOnboardingStatus()
            }
        }
        
        isLoading = false
        updateCurrentStepIndex()
    }
    
    // MARK: - Step Management
    
    func completeCurrentStep() async {
        guard let status = onboardingStatus else { return }
        
        isLoading = true
        errorMessage = nil
        
        do {
            switch status.currentStep {
            case .welcome:
                // Map to backend step name
                _ = try await backendService.completeOnboardingStep(.phone_setup)
                
            case .profile:
                // Map to backend step name
                _ = try await backendService.completeOnboardingStep(.calendar)
                
            case .tutorial:
                // Map to backend step name
                _ = try await backendService.completeOnboardingStep(.scenarios)
                
            case .firstCall:
                // Map to backend step name
                _ = try await backendService.completeOnboardingStep(.welcome_call)
            }
            
            // Refresh onboarding status from backend
            onboardingStatus = try await backendService.getOnboardingStatus()
            updateCurrentStepIndex()
            
            // Save completion status locally if onboarding is complete
            if onboardingStatus?.isComplete == true {
                UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
            }
            
        } catch {
            errorMessage = "Failed to complete step: \(error.localizedDescription)"
            print("Step completion error: \(error)")
            
            // For offline/testing, update local status
            updateLocalOnboardingStatus()
        }
        
        isLoading = false
    }
    
    func skipCurrentStep() async {
        // For mobile app, we can allow skipping certain steps
        await completeCurrentStep()
    }
    
    func goToNextStep() {
        guard currentStepIndex < allSteps.count - 1 else { return }
        currentStepIndex += 1
    }
    
    func goToPreviousStep() {
        guard currentStepIndex > 0 else { return }
        currentStepIndex -= 1
    }
    
    // MARK: - Validation
    
    var isCurrentStepValid: Bool {
        switch currentStep {
        case .welcome, .tutorial, .firstCall:
            return true
        case .profile:
            return !userName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
    }
    
    var canProceed: Bool {
        return isCurrentStepValid && !isLoading
    }
    
    // Add a method to show completion message
    func showCompletion(message: String) {
        completionMessage = message
        showCompletionMessage = true
    }
    
    // MARK: - Private Methods
    
    private func updateCurrentStepIndex() {
        if let status = onboardingStatus,
           let index = allSteps.firstIndex(of: status.currentStep) {
            currentStepIndex = index
        }
    }
    
    private func createDefaultOnboardingStatus() {
        // Create a default status for offline/testing
        onboardingStatus = OnboardingStatus(
            isComplete: false,
            currentStep: .welcome,
            completedSteps: [],
            progressPercentage: 0
        )
    }
    
    private func updateLocalOnboardingStatus() {
        guard var status = onboardingStatus else { return }
        
        // Add current step to completed steps if not already there
        if !status.completedSteps.contains(status.currentStep) {
            status.completedSteps.append(status.currentStep)
        }
        
        // Check if all steps are completed
        let allSteps = OnboardingStep.allCases
        let isComplete = status.completedSteps.count == allSteps.count
        let progressPercentage = Double(status.completedSteps.count) / Double(allSteps.count) * 100
        
        // Determine next step
        let nextStep: OnboardingStep
        if isComplete {
            nextStep = .firstCall // All steps completed
        } else {
            let currentIndex = allSteps.firstIndex(of: status.currentStep) ?? 0
            let nextIndex = min(currentIndex + 1, allSteps.count - 1)
            nextStep = allSteps[nextIndex]
        }
        
        onboardingStatus = OnboardingStatus(
            currentStep: nextStep,
            completedSteps: status.completedSteps,
            isComplete: isComplete,
            progressPercentage: progressPercentage
        )
        
        // Save completion status locally if onboarding is complete
        if isComplete {
            UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
        }
    }
}
