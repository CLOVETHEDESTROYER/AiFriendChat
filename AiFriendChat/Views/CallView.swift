import SwiftUI
import SwiftData
import os.log

struct CallView: View {
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.app", category: "CallView")
    
    @Environment(\.modelContext) private var modelContext
    @StateObject private var viewModel: HomeViewModel
    @StateObject private var callViewModel: CallViewModel
    @StateObject private var purchaseManager = PurchaseManager.shared
    @EnvironmentObject private var authViewModel: AuthViewModel
    
    @State private var phoneNumber = ""
    @State private var selectedScenario = "default"
    @State private var userName = ""
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    @State private var showAlert = false
    @State private var showScheduleSheet = false
    @State private var showAuthPrompt = false
    @State private var showAuthView = false
    
    @FocusState private var activeField: Field?
    
    private enum Field: Hashable {
        case userName, phoneNumber
    }
    
    var scenarios: [String] {
        var defaultScenarios = ["default", "sister_emergency", "mother_emergency", "yacht_party", "instigator", "gameshow_host"]
        
        if purchaseManager.isSubscribed {
            if let data = UserDefaults.standard.data(forKey: "savedCustomPrompts"),
               let customPrompts = try? JSONDecoder().decode([SavedPrompt].self, from: data) {
                defaultScenarios.append(contentsOf: customPrompts.map { "custom_\($0.name)" })
            }
        }
        
        return defaultScenarios
    }
    
    init(modelContext: ModelContext) {
        _viewModel = StateObject(wrappedValue: HomeViewModel(modelContext: modelContext))
        _callViewModel = StateObject(wrappedValue: CallViewModel(modelContext: modelContext))
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
                
                ScrollView(showsIndicators: true) {
                    VStack(spacing: 15) {
                        // Welcome Title
                        Text("Welcome to AI Friend Chat")
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .padding(.top, 10)
                        
                        // Trial Status in a more compact form
                        if !purchaseManager.isSubscribed {
                            HStack {
                                Text("Trial Calls: \(purchaseManager.getRemainingTrialCalls())")
                                    .font(.subheadline)
                                    .foregroundColor(.white)
                                Spacer()
                                Button("Restore") {
                                    Task {
                                        try? await purchaseManager.restorePurchases()
                                    }
                                }
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.8))
                            }
                            .padding(.horizontal)
                            
                            PremiumUpgradeButton(purchaseManager: purchaseManager, style: .secondary)
                                .padding(.horizontal)
                                .padding(.bottom, 5)
                        }
                        
                        // User Name Input
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Your Name")
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            TextField("Enter your name", text: $userName)
                                .textFieldStyle(.plain)
                                .padding()
                                .background(Color.black.opacity(0.3))
                                .cornerRadius(10)
                                .focused($activeField, equals: .userName)
                            
                            Button(action: updateUserName) {
                                Text("Update Name")
                                    .font(.subheadline)
                                    .foregroundColor(.white)
                                    .padding(.vertical, 8)
                                    .padding(.horizontal, 16)
                                    .background(Color("highlight"))
                                    .cornerRadius(8)
                            }
                        }
                        .padding(.horizontal)
                        
                        // Phone Number Input
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Phone Number")
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            TextField("Enter phone number", text: $phoneNumber)
                                .textFieldStyle(.plain)
                                .padding()
                                .background(Color.black.opacity(0.3))
                                .cornerRadius(10)
                                .keyboardType(.phonePad)
                                .focused($activeField, equals: .phoneNumber)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(phoneNumber.isEmpty ? Color.red.opacity(0.7) : Color.clear, lineWidth: 1)
                                )
                            
                            if phoneNumber.isEmpty {
                                Text("Phone number is required")
                                    .font(.caption)
                                    .foregroundColor(.red)
                                    .padding(.leading, 4)
                            }
                        }
                        .padding(.horizontal)
                        
                        // Scenario Selection
                        VStack(alignment: .leading, spacing: 15) {
                            Text("Select Scenario")
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding(.horizontal)
                            
                            LazyVGrid(columns: [
                                GridItem(.flexible()),
                                GridItem(.flexible()),
                                GridItem(.flexible())
                            ], spacing: 15) {
                                ForEach(scenarios, id: \.self) { scenario in
                                    Button(action: { selectedScenario = scenario }) {
                                        VStack {
                                            Image(systemName: scenario.hasPrefix("custom_") ? "text.bubble.fill" : "hexagon.fill")
                                                .resizable()
                                                .frame(width: 24, height: 24)
                                                .foregroundColor(selectedScenario == scenario ? .white : .black)
                                            
                                            Text(displayName(for: scenario))
                                                .font(.system(size: 12, weight: .medium))
                                                .foregroundColor(selectedScenario == scenario ? .white : .black)
                                                .multilineTextAlignment(.center)
                                                .lineLimit(2)
                                        }
                                        .frame(height: 80)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 8)
                                        .background(selectedScenario == scenario ? Color("highlight") : Color.white.opacity(0.9))
                                        .cornerRadius(10)
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                        
                        // Call Button
                        Button(action: makeCall) {
                            HStack {
                                Image(systemName: "phone.fill")
                                Text("Start Call")
                            }
                            .font(.headline)
                            .foregroundColor(phoneNumber.isEmpty ? .gray : .white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(phoneNumber.isEmpty ? Color("highlight").opacity(0.5) : Color("highlight"))
                            .cornerRadius(15)
                            .padding(.horizontal)
                        }
                        .disabled(phoneNumber.isEmpty || callViewModel.isCallInProgress)
                        .shake(phoneNumber.isEmpty && showAlert)
                    }
                    .padding(.vertical)
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .keyboard) {
                    Button("Done") {
                        activeField = nil
                    }
                }
                
                #if DEBUG
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu("Debug") {
                        Button("Toggle Premium") {
                            purchaseManager.toggleDebugPremium()
                        }
                        
                        Button("Reset Call Count") {
                            UserDefaults.standard.removeObject(forKey: "callsMadeCount")
                            purchaseManager.objectWillChange.send()
                        }
                        
                        Button("Add Test Call") {
                            let currentCalls = UserDefaults.standard.integer(forKey: "callsMadeCount")
                            UserDefaults.standard.set(currentCalls + 1, forKey: "callsMadeCount")
                            purchaseManager.objectWillChange.send()
                        }
                        
                        Text("Calls Made: \(purchaseManager.callsMade)")
                    }
                }
                #endif
            }
            .sheet(isPresented: $showScheduleSheet) {
                ScheduleCallView(phoneNumber: phoneNumber, scenario: selectedScenario)
            }
            .alert(alertTitle, isPresented: $showAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(alertMessage)
            }
            .onChange(of: callViewModel.errorMessage) { oldValue, newValue in
                if let error = newValue {
                    alertTitle = "Error"
                    alertMessage = error
                    showAlert = true
                }
            }
            .onChange(of: callViewModel.successMessage) { oldValue, newValue in
                if let success = newValue {
                    alertTitle = "Success"
                    alertMessage = success
                    showAlert = true
                }
            }
            .sheet(isPresented: $showAuthPrompt) {
                AuthPromptView(showAuthView: $showAuthView)
            }
            .fullScreenCover(isPresented: $showAuthView) {
                AuthView()
            }
        }
    }
    
    private func makeCall() {
        guard !phoneNumber.isEmpty else {
            alertTitle = "Error"
            alertMessage = "Please enter a phone number."
            showAlert = true
            return
        }
        
        if !authViewModel.isLoggedIn {
            showAuthPrompt = true
            return
        }
        
        callViewModel.initiateCall(phoneNumber: phoneNumber, scenario: selectedScenario)
    }
    
    private func updateUserName() {
        logger.debug("Starting updateUserName function")
        let trimmedName = userName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else {
            logger.error("Attempted to update with empty username")
            alertTitle = "Error"
            alertMessage = "Name cannot be empty."
            showAlert = true
            return
        }
        
        Task {
            do {
                let message = try await viewModel.updateUserName(to: trimmedName)
                logger.debug("Successfully updated username: \(message)")
                alertTitle = "Success"
                alertMessage = message
                UserDefaults.standard.set(trimmedName, forKey: "userName")
            } catch {
                logger.error("Failed to update username: \(error.localizedDescription)")
                alertTitle = "Error"
                alertMessage = "Failed to update name: \(error.localizedDescription)"
            }
            showAlert = true
        }
    }
    
    private func displayName(for scenario: String) -> String {
        if scenario.hasPrefix("custom_") {
            return "Custom: " + scenario.replacingOccurrences(of: "custom_", with: "")
        }
        return scenario.replacingOccurrences(of: "_", with: " ").capitalized
    }
}

// Add shake animation modifier
extension View {
    func shake(_ shake: Bool) -> some View {
        modifier(ShakeEffect(shake: shake))
    }
}

struct ShakeEffect: GeometryEffect {
    var amount: CGFloat = 10
    var shakesPerUnit = 3
    var shake: Bool
    
    var animatableData: CGFloat {
        get { CGFloat(shake ? 1 : 0) }
        set { _ = newValue }
    }
    
    func effectValue(size: CGSize) -> ProjectionTransform {
        guard shake else { return ProjectionTransform(.identity) }
        
        let translation = amount * sin(animatableData * .pi * CGFloat(shakesPerUnit))
        return ProjectionTransform(CGAffineTransform(translationX: translation, y: 0))
    }
}
