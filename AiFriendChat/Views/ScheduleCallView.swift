//
//  ScheduleCallView.swift
//  AiFriendChat
//
//  Created by Carlos Alvarez on 10/19/24.
//

import SwiftUI
import SwiftData

struct ScheduleCallView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var authViewModel: AuthViewModel
    @StateObject private var viewModel: ScheduleCallViewModel
    @StateObject private var purchaseManager = PurchaseManager.shared
    @Environment(\.presentationMode) var presentationMode
    @Query private var savedPrompts: [SavedPrompt]
    @FocusState private var isInputActive: Bool
    
    init(phoneNumber: String, scenario: String) {
        let vm = ScheduleCallViewModel()
        vm.phoneNumber = phoneNumber
        vm.selectedScenario = scenario
        _viewModel = StateObject(wrappedValue: vm)
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient(
                    gradient: Gradient(colors: [Color("Color"), Color("Color 2")]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .edgesIgnoringSafeArea(.all)
                
                if authViewModel.isLoggedIn {
                    // Show schedule call form for signed-in users
                    scheduleCallForm
                } else {
                    // Show premium signup screen for non-signed-in users
                    premiumSignupScreen
                }
            }
            .navigationTitle("Schedule Call")
            .navigationBarTitleDisplayMode(.inline)
        }
        .onAppear {
            viewModel.authViewModel = authViewModel
        }
    }
    
    private var premiumSignupScreen: some View {
        VStack(spacing: 30) {
            Spacer()
            
            // Premium icon
            Image(systemName: "calendar.badge.clock")
                .font(.system(size: 80))
                .foregroundColor(.yellow)
            
            // Title
            Text("Schedule Calls")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            // Subtitle
            Text("Sign up for premium weekly subscription to schedule calls")
                .font(.title3)
                .foregroundColor(.white.opacity(0.8))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            // Features list
            VStack(alignment: .leading, spacing: 15) {
                ScheduleFeatureRow(icon: "clock.fill", text: "Schedule calls for any time")
                ScheduleFeatureRow(icon: "phone.fill", text: "Unlimited scheduled calls")
                ScheduleFeatureRow(icon: "star.fill", text: "Premium voice scenarios")
                ScheduleFeatureRow(icon: "calendar", text: "Flexible scheduling")
            }
            .padding(.horizontal, 40)
            
            Spacer()
            
            // Premium upgrade button
            VStack(spacing: 15) {
                PremiumUpgradeButton(purchaseManager: purchaseManager, style: .primary)
                RestorePurchasesButton(purchaseManager: purchaseManager)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 50)
        }
    }
    
    private var scheduleCallForm: some View {
        Form {
            Section(header: Text("Call Details")) {
                TextField("Phone Number", text: $viewModel.phoneNumber)
                    .focused($isInputActive)
                    .keyboardType(.phonePad)
                    .toolbar {
                        ToolbarItemGroup(placement: .keyboard) {
                            Spacer()
                            Button("Done") {
                                isInputActive = false
                            }
                        }
                    }
                
                DatePicker("Scheduled Time", selection: $viewModel.selectedDate, in: Date()...)
                
                Picker("Scenario Type", selection: $viewModel.isCustomScenario) {
                    Text("Standard").tag(false)
                    Text("Custom").tag(true)
                }
                
                if viewModel.isCustomScenario {
                    Picker("Custom Scenario", selection: $viewModel.selectedCustomPrompt) {
                        ForEach(savedPrompts) { prompt in
                            Text("\(prompt.name) (\(prompt.scenarioId ?? "No ID"))")
                                .tag(Optional(prompt))
                        }
                    }
                } else {
                    Picker("Scenario", selection: $viewModel.selectedScenario) {
                        ForEach(standardScenarios, id: \.self) { scenario in
                            Text(scenario.replacingOccurrences(of: "_", with: " ").capitalized)
                                .tag(scenario)
                        }
                    }
                }
            }
            
            Section {
                Button {
                    viewModel.scheduleCall()
                } label: {
                    if viewModel.isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle())
                    } else {
                        Text("Schedule Call")
                    }
                }
                .disabled(viewModel.isLoading || viewModel.phoneNumber.isEmpty || 
                        (viewModel.isCustomScenario && viewModel.selectedCustomPrompt == nil))
            }
            
            if let errorMessage = viewModel.errorMessage {
                Section {
                    Text(errorMessage)
                        .foregroundColor(.red)
                }
            }
        }
        .alert("Success", isPresented: $viewModel.showSuccessAlert) {
            Button("OK") {
                presentationMode.wrappedValue.dismiss()
            }
        } message: {
            Text("Call has been scheduled successfully!")
        }
        .alert("Error", isPresented: $viewModel.showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
        .sheet(isPresented: $viewModel.showAuthPrompt) {
            AuthPromptView(showAuthView: $viewModel.showAuthView)
        }
        .fullScreenCover(isPresented: $viewModel.showAuthView) {
            AuthView()
        }
        .background(
            Color.clear
                .contentShape(Rectangle())
                .onTapGesture {
                    isInputActive = false
                }
        )
    }
    
    private var standardScenarios: [String] {
        ["default", "sister_emergency", "mother_emergency", "yacht_party", "instigator", "gameshow_host"]
    }
}

struct ScheduleCallView_Previews: PreviewProvider {
    static var previews: some View {
        ScheduleCallView(phoneNumber: "1234567890", scenario: "default")
    }
}

// MARK: - ScheduleFeatureRow Component
struct ScheduleFeatureRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 15) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.yellow)
                .frame(width: 30)
            
            Text(text)
                .font(.body)
                .foregroundColor(.white)
            
            Spacer()
        }
    }
}
