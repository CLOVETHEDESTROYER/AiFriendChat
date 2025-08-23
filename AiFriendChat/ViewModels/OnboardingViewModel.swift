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
        
        print("🔄 Starting step completion for: \(status.currentStep)")
        
        // Prevent infinite loops - check if step was already completed
        if status.completedSteps.contains(status.currentStep) {
            print("⚠️ Step \(status.currentStep) already completed, moving to next step")
            moveToNextStep()
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            switch status.currentStep {
            case .welcome:
                print("✅ Completing welcome step")
                _ = try await backendService.completeOnboardingStep(.welcome)
                
            case .profile:
                print("✅ Completing profile step")
                _ = try await backendService.completeOnboardingStep(.profile)
                
            case .tutorial:
                print("✅ Completing tutorial step")
                _ = try await backendService.completeOnboardingStep(.tutorial)
                
            case .firstCall:
                print("✅ Completing firstCall step")
                _ = try await backendService.completeOnboardingStep(.firstCall)
            }
            
            print("🔄 Refreshing onboarding status from backend")
            onboardingStatus = try await backendService.getOnboardingStatus()
            print("📊 New status: \(String(describing: onboardingStatus))")
            
            // Check if backend properly updated the step
            if let newStatus = onboardingStatus, newStatus.currentStep == status.currentStep {
                print("⚠️ Backend didn't progress step, forcing local progression")
                forceStepProgression()
            } else {
                updateCurrentStepIndex()
            }
            
            // Save completion status locally if onboarding is complete
            if onboardingStatus?.isComplete == true {
                UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
                print("🎉 Onboarding completed!")
            }
            
        } catch {
            errorMessage = "Failed to complete step: \(error.localizedDescription)"
            print("❌ Step completion error: \(error)")
            
            // For offline/testing, update local status
            updateLocalOnboardingStatus()
        }
        
        isLoading = false
        print("🏁 Step completion finished")
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
            print("🔄 Updating current step index: \(currentStepIndex) -> \(index)")
            currentStepIndex = index
        } else {
            print("⚠️ Could not update step index - status: \(String(describing: onboardingStatus))")
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
        
        print("🔄 Updating local onboarding status for step: \(status.currentStep)")
        
        // Add current step to completed steps if not already there
        if !status.completedSteps.contains(status.currentStep) {
            status.completedSteps.append(status.currentStep)
            print("✅ Added step to completed: \(status.currentStep)")
        }
        
        // Check if all steps are completed
        let allSteps = OnboardingStep.allCases
        let isComplete = status.completedSteps.count == allSteps.count
        let progressPercentage = Double(status.completedSteps.count) / Double(allSteps.count) * 100
        
        print("📊 Progress: \(status.completedSteps.count)/\(allSteps.count) steps completed (\(Int(progressPercentage))%)")
        
        // Determine next step
        let nextStep: OnboardingStep
        if isComplete {
            nextStep = .firstCall // All steps completed
            print("🎉 All steps completed, next step: \(nextStep)")
        } else {
            let currentIndex = allSteps.firstIndex(of: status.currentStep) ?? 0
            let nextIndex = min(currentIndex + 1, allSteps.count - 1)
            nextStep = allSteps[nextIndex]
            print("🔄 Moving to next step: \(status.currentStep) -> \(nextStep)")
        }
        
        onboardingStatus = OnboardingStatus(
            isComplete: isComplete,
            currentStep: nextStep,
            completedSteps: status.completedSteps,
            progressPercentage: progressPercentage
        )
        
        // Save completion status locally if onboarding is complete
        if isComplete {
            UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
            print("💾 Saved onboarding completion to UserDefaults")
        }
    }
    
    // MARK: - Step Progression Helpers
    
    private func moveToNextStep() {
        guard let status = onboardingStatus else { return }
        
        let allSteps = OnboardingStep.allCases
        guard let currentIndex = allSteps.firstIndex(of: status.currentStep) else { return }
        
        let nextIndex = min(currentIndex + 1, allSteps.count - 1)
        let nextStep = allSteps[nextIndex]
        
        print("🔄 Moving to next step: \(status.currentStep) -> \(nextStep)")
        
        // Update local status to progress
        onboardingStatus = OnboardingStatus(
            isComplete: false,
            currentStep: nextStep,
            completedSteps: status.completedSteps + [status.currentStep],
            progressPercentage: Double((status.completedSteps.count + 1)) / Double(allSteps.count) * 100
        )
        
        updateCurrentStepIndex()
    }
    
    private func forceStepProgression() {
        guard let status = onboardingStatus else { return }
        
        print("🔄 Forcing step progression for: \(status.currentStep)")
        
        // Mark current step as completed and move to next
        var newCompletedSteps = status.completedSteps
        if !newCompletedSteps.contains(status.currentStep) {
            newCompletedSteps.append(status.currentStep)
        }
        
        let allSteps = OnboardingStep.allCases
        let currentIndex = allSteps.firstIndex(of: status.currentStep) ?? 0
        let nextIndex = min(currentIndex + 1, allSteps.count - 1)
        let nextStep = allSteps[nextIndex]
        
        let progressPercentage = Double(newCompletedSteps.count) / Double(allSteps.count) * 100
        let isComplete = newCompletedSteps.count == allSteps.count
        
        print("🔄 Forced progression: \(status.currentStep) -> \(nextStep)")
        print("📊 Progress: \(newCompletedSteps.count)/\(allSteps.count) steps (\(Int(progressPercentage))%)")
        
        onboardingStatus = OnboardingStatus(
            isComplete: isComplete,
            currentStep: nextStep,
            completedSteps: newCompletedSteps,
            progressPercentage: progressPercentage
        )
        
        updateCurrentStepIndex()
        
        // If onboarding is complete, save to UserDefaults
        if isComplete {
            UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
            print("🎉 Onboarding completed via forced progression!")
        }
    }
}
