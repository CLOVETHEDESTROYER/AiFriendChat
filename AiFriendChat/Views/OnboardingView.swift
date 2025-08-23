//
//  OnboardingView.swift
//  AiFriendChat
//
//  Created by AI Assistant
//

import SwiftUI

struct OnboardingView: View {
    @StateObject private var viewModel = OnboardingViewModel()
    @Binding var isOnboardingComplete: Bool
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient
                LinearGradient(
                    gradient: Gradient(colors: [Color("Color"), Color("Color 2")]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Progress bar
                    ProgressBarView(progress: viewModel.progressPercentage / 100)
                        .padding(.horizontal)
                        .padding(.top)
                    
                    // Current step view
                    TabView(selection: $viewModel.currentStepIndex) {
                        WelcomeStepView(viewModel: viewModel)
                            .tag(0)
                        
                        ProfileStepView(viewModel: viewModel)
                            .tag(1)
                        
                        TutorialStepView(viewModel: viewModel)
                            .tag(2)
                        
                        FirstCallStepView(
                            viewModel: viewModel,
                            onComplete: { isOnboardingComplete = true }
                        )
                        .tag(3)
                    }
                    .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                    .animation(.easeInOut, value: viewModel.currentStepIndex)
                }
            }
        }
        .navigationBarHidden(true)
        .task {
            await viewModel.initializeOnboarding()
        }
        .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
            Button("OK") {
                viewModel.errorMessage = nil
            }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
        .onChange(of: viewModel.isOnboardingComplete) { _, newValue in
            if newValue {
                isOnboardingComplete = true
            }
        }
    }
}

// MARK: - Progress Bar Component

struct ProgressBarView: View {
    let progress: Double
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Setup Progress")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.8))
                Spacer()
                Text("\(Int(progress * 100))%")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.8))
            }
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color.white.opacity(0.3))
                        .frame(height: 4)
                        .cornerRadius(2)
                    
                    Rectangle()
                        .fill(Color.white)
                        .frame(width: geometry.size.width * progress, height: 4)
                        .cornerRadius(2)
                        .animation(.easeInOut(duration: 0.3), value: progress)
                }
            }
            .frame(height: 4)
        }
    }
}

// MARK: - Individual Step Views

struct WelcomeStepView: View {
    @ObservedObject var viewModel: OnboardingViewModel
    
    var body: some View {
        VStack(spacing: 40) {
            Spacer()
            
            // App logo/icon
            Image("logo")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 120, height: 120)
                .clipShape(RoundedRectangle(cornerRadius: 20))
            
            VStack(spacing: 16) {
                Text("👋 Welcome to AiFriend!")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                
                Text("Your AI calling companion for entertainment and escaping awkward situations")
                    .font(.title3)
                    .foregroundColor(.white.opacity(0.9))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                VStack(spacing: 12) {
                    FeatureRow(icon: "🎭", text: "22+ Fun Scenarios")
                    FeatureRow(icon: "📞", text: "Instant AI Calls")
                    FeatureRow(icon: "🔊", text: "Realistic Voices")
                    FeatureRow(icon: "🎁", text: "3 Free Trial Calls")
                }
                .padding(.top)
            }
            
            Spacer()
            
            // Continue button
            Button(action: {
                Task {
                    await viewModel.completeCurrentStep()
                    viewModel.goToNextStep()
                }
            }) {
                HStack {
                    Text("Get Started")
                    Image(systemName: "arrow.right")
                }
            }
            .buttonStyle(OnboardingButtonStyle(isEnabled: viewModel.canProceed))
            .disabled(!viewModel.canProceed)
            .padding(.horizontal, 30)
            .padding(.bottom, 30)
        }
        .padding()
    }
}

private struct FeatureRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Text(icon)
                .font(.title2)
            Text(text)
                .font(.body)
                .foregroundColor(.white.opacity(0.9))
            Spacer()
        }
        .padding(.horizontal)
    }
}

struct ProfileStepView: View {
    @ObservedObject var viewModel: OnboardingViewModel
    
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            VStack(spacing: 16) {
                Text("👤")
                    .font(.system(size: 60))
                
                Text("Set Up Your Profile")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text("Tell us a bit about yourself so your AI friend can call you by name")
                    .font(.body)
                    .foregroundColor(.white.opacity(0.9))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            
            VStack(spacing: 20) {
                // Name field
                VStack(alignment: .leading, spacing: 8) {
                    Text("Your Name")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.8))
                    
                    TextField("Enter your name", text: $viewModel.userName)
                        .textFieldStyle(OnboardingTextFieldStyle())
                }
                
                // Phone field (optional)
                VStack(alignment: .leading, spacing: 8) {
                    Text("Phone Number (Optional)")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.8))
                    
                    TextField("Your phone number", text: $viewModel.userPhone)
                        .textFieldStyle(OnboardingTextFieldStyle())
                        .keyboardType(.phonePad)
                }
                
                // Voice preference
                VStack(alignment: .leading, spacing: 8) {
                    Text("Preferred Voice")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.8))
                    
                    Picker("Voice", selection: $viewModel.selectedVoice) {
                        Text("Alloy (Female, Warm)").tag("alloy")
                        Text("Ash (Male, Energetic)").tag("ash")
                        Text("Coral (Female, Gentle)").tag("coral")
                        Text("Echo (Male, Professional)").tag("echo")
                    }
                    .pickerStyle(MenuPickerStyle())
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(Color(.systemBackground).opacity(0.9))
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color(.systemGray4), lineWidth: 1)
                    )
                }
                
                // Notifications toggle
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Notifications")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.8))
                        Text("Get reminders and updates")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.6))
                    }
                    Spacer()
                    Toggle("", isOn: $viewModel.notificationsEnabled)
                        .tint(Color("highlight"))
                }
                .onboardingCard()
            }
            .padding(.horizontal, 30)
            
            Spacer()
            
            // Navigation buttons
            HStack(spacing: 16) {
                Button("Back") {
                    viewModel.goToPreviousStep()
                }
                .buttonStyle(OnboardingButtonStyle(isPrimary: false))
                .frame(maxWidth: .infinity)
                
                Button(action: {
                    Task {
                        await viewModel.completeCurrentStep()
                        viewModel.goToNextStep()
                    }
                }) {
                    HStack {
                        Text("Continue")
                        Image(systemName: "arrow.right")
                    }
                }
                .buttonStyle(OnboardingButtonStyle(isEnabled: viewModel.canProceed))
                .disabled(!viewModel.canProceed)
                .frame(maxWidth: .infinity)
            }
            .padding(.horizontal, 30)
            .padding(.bottom, 30)
        }
        .padding()
    }
}

struct TutorialStepView: View {
    @ObservedObject var viewModel: OnboardingViewModel
    
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            VStack(spacing: 16) {
                Text("🎓")
                    .font(.system(size: 60))
                
                Text("How It Works")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text("Learn the basics in just 30 seconds")
                    .font(.body)
                    .foregroundColor(.white.opacity(0.9))
                    .multilineTextAlignment(.center)
            }
            
            VStack(spacing: 20) {
                TutorialStep(
                    number: "1",
                    title: "Choose a Scenario",
                    description: "Pick from 22+ fun scenarios like 'Celebrity Interview' or 'Emergency Call'"
                )
                
                TutorialStep(
                    number: "2",
                    title: "Enter Phone Number",
                    description: "Add the number you want to call (or use your own for testing)"
                )
                
                TutorialStep(
                    number: "3",
                    title: "Make the Call",
                    description: "Your AI friend will call and play the chosen scenario perfectly"
                )
                
                TutorialStep(
                    number: "4",
                    title: "Have Fun!",
                    description: "Enjoy realistic conversations or use it to escape awkward moments"
                )
            }
            .padding(.horizontal, 30)
            
            Spacer()
            
            // Navigation buttons
            HStack(spacing: 16) {
                Button("Back") {
                    viewModel.goToPreviousStep()
                }
                .buttonStyle(OnboardingButtonStyle(isPrimary: false))
                .frame(maxWidth: .infinity)
                
                Button(action: {
                    Task {
                        await viewModel.completeCurrentStep()
                    }
                }) {
                    HStack {
                        Text("Got It!")
                        Image(systemName: "arrow.right")
                    }
                }
                .buttonStyle(OnboardingButtonStyle(isEnabled: viewModel.canProceed))
                .disabled(!viewModel.canProceed)
                .frame(maxWidth: .infinity)
            }
            .padding(.horizontal, 30)
            .padding(.bottom, 30)
        }
        .padding()
    }
}

struct TutorialStep: View {
    let number: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 16) {
            // Step number
            Text(number)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.black)
                .frame(width: 32, height: 32)
                .background(Color.white)
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.white)
                
                Text(description)
                    .font(.body)
                    .foregroundColor(.white.opacity(0.8))
            }
            
            Spacer()
        }
        .onboardingCard()
    }
}

struct FirstCallStepView: View {
    @ObservedObject var viewModel: OnboardingViewModel
    let onComplete: () -> Void
    
    @State private var phoneNumber = ""
    @State private var isTestingCall = false
    @State private var showSuccessAlert = false
    @State private var successMessage = ""
    
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            VStack(spacing: 16) {
                Text("📞")
                    .font(.system(size: 60))
                
                Text("Make Your First Call")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text("Test your setup with a practice call. Use your own number to hear how it works!")
                    .font(.body)
                    .foregroundColor(.white.opacity(0.9))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            
            VStack(spacing: 20) {
                // Phone number input
                VStack(alignment: .leading, spacing: 8) {
                    Text("Phone Number to Call")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.8))
                    
                    TextField("Enter phone number", text: $phoneNumber)
                        .textFieldStyle(OnboardingTextFieldStyle())
                        .keyboardType(.phonePad)
                }
                
                // Test call button
                if isTestingCall {
                    VStack(spacing: 12) {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        Text("Making test call...")
                            .font(.body)
                            .foregroundColor(.white.opacity(0.8))
                    }
                    .frame(height: 60)
                } else {
                    Button("🎭 Make Test Call (Celebrity Interview)") {
                        makeTestCall()
                    }
                    .buttonStyle(OnboardingButtonStyle(
                        isEnabled: !phoneNumber.isEmpty,
                        isPrimary: false
                    ))
                    .disabled(phoneNumber.isEmpty)
                }
            }
            .padding(.horizontal, 30)
            
            Spacer()
            
            // Navigation buttons
            HStack(spacing: 16) {
                Button("Back") {
                    viewModel.goToPreviousStep()
                }
                .buttonStyle(OnboardingButtonStyle(isPrimary: false))
                .frame(maxWidth: .infinity)
                
                Button("Finish Setup") {
                    Task {
                        await viewModel.completeCurrentStep()
                        onComplete()
                    }
                }
                .buttonStyle(OnboardingButtonStyle(isEnabled: viewModel.canProceed))
                .disabled(!viewModel.canProceed)
                .frame(maxWidth: .infinity)
            }
            .padding(.horizontal, 30)
            .padding(.bottom, 30)
        }
        .padding()
        .alert("Success!", isPresented: $showSuccessAlert) {
            Button("Continue") {
                // Alert automatically dismisses and onComplete() will be called
            }
        } message: {
            Text(successMessage)
        }
    }
    
    private func makeTestCall() {
        guard !phoneNumber.isEmpty else { return }
        
        isTestingCall = true
        
        Task {
            do {
                // Make a test call using the celebrity scenario
                let backendService = BackendService.shared
                let formattedPhone = phoneNumber.starts(with: "+") ? phoneNumber : "+1" + phoneNumber.filter { $0.isNumber }
                
                                            _ = try await backendService.makeCall(phoneNumber: formattedPhone, scenario: "fake_celebrity")
                
                await MainActor.run {
                    isTestingCall = false
                    // Show success and guide to premium
                    successMessage = "🎉 Welcome to AiFriend! You have 2 more trial calls. Upgrade to Premium for unlimited fun!"
                    showSuccessAlert = true
                    
                    Task {
                        await viewModel.completeCurrentStep()
                        onComplete()
                    }
                }
                
            } catch BackendError.unauthorized {
                await MainActor.run {
                    isTestingCall = false
                    // Show auth prompt for onboarding
                    viewModel.errorMessage = "Please create an account or log in to make calls"
                }
            } catch {
                await MainActor.run {
                    isTestingCall = false
                    // Show error but allow completion
                    print("Test call error: \(error)")
                    viewModel.errorMessage = "Test call failed, but you can still continue. Try again from the main app!"
                }
            }
        }
    }
}

struct OnboardingView_Previews: PreviewProvider {
    static var previews: some View {
        OnboardingView(isOnboardingComplete: .constant(false))
    }
}
