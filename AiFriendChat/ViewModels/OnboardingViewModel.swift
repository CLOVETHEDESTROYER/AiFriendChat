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
                _ = try await backendService.completeOnboardingStep(.welcome)
                
            case .profile:
                let profile = OnboardingProfile(
                    name: userName,
                    phoneNumber: userPhone.isEmpty ? nil : userPhone,
                    preferredVoice: selectedVoice,
                    notificationsEnabled: notificationsEnabled
                )
                try await backendService.saveOnboardingProfile(profile)
                
                // Also save locally for immediate use
                UserDefaults.standard.set(userName, forKey: "userName")
                
            case .tutorial:
                _ = try await backendService.completeOnboardingStep(.tutorial)
                
            case .firstCall:
                _ = try await backendService.completeOnboardingStep(.firstCall)
            }
            
            // Refresh onboarding status
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
        
        var completedSteps = status.completedSteps
        if !completedSteps.contains(status.currentStep) {
            completedSteps.append(status.currentStep)
        }
        
        let nextStep = status.currentStep
        let allSteps = OnboardingStep.allCases
        let nextStepIndex = allSteps.firstIndex(of: nextStep).map { $0 + 1 } ?? 0
        let newCurrentStep = nextStepIndex < allSteps.count ? allSteps[nextStepIndex] : .firstCall
        
        let isComplete = completedSteps.count == OnboardingStep.allCases.count
        let progressPercentage = Double(completedSteps.count) / Double(OnboardingStep.allCases.count) * 100
        
        onboardingStatus = OnboardingStatus(
            isComplete: isComplete,
            currentStep: newCurrentStep,
            completedSteps: completedSteps,
            progressPercentage: progressPercentage
        )
        
        updateCurrentStepIndex()
        
        // Save completion status locally if onboarding is complete
        if isComplete {
            UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
        }
    }
}
