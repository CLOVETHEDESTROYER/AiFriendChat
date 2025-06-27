import SwiftUI
import SwiftData
import os
import StoreKit

private enum Field: Hashable {
    case userName, phoneNumber
}
struct HomeView: View {
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.app", category: "HomeView")
    
    @EnvironmentObject var authViewModel: AuthViewModel
    @Environment(\.modelContext) private var modelContext
    @StateObject private var viewModel: HomeViewModel
    @StateObject private var callViewModel: CallViewModel
    @StateObject private var purchaseManager = PurchaseManager.shared
    
    // MARK: - State Properties
    @State private var phoneNumber = ""
    @State private var selectedScenario = "default"
    @State private var userName = ""
    @State private var isUpdatingName = false
    @State private var showAlert = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    @State private var showPremiumAlert = false
    @State private var showSubscriptionAlert = false
    @State private var showSubscriptionPrompt = false
    @State private var showAccountSheet = false
    @State private var showSettingsSheet = false
    @State private var showHelpSheet = false
    @State private var showCallHistory = false
    
    @FocusState private var activeField: Field?
    
    init(modelContext: ModelContext) {
        _viewModel = StateObject(wrappedValue: HomeViewModel(modelContext: modelContext))
        _callViewModel = StateObject(wrappedValue: CallViewModel(modelContext: modelContext))
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Gradient background
                LinearGradient(
                    gradient: Gradient(colors: [Color("Color"), Color("Color 2")]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .edgesIgnoringSafeArea(.all)
                
                VStack(spacing: 20) {
                    // Header
                    Text("Welcome to AI Friend Chat")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .padding()
                    
                    // Trial/Subscription Status
                    if !purchaseManager.isSubscribed {
                        Text(purchaseManager.isSubscribed ? 
                             "Call Time: \(purchaseManager.getRemainingTimeDisplay())" : 
                             "Trial Calls: \(purchaseManager.getRemainingTrialCalls())")
                            .font(.subheadline)
                            .foregroundColor(.white)
                            .padding(.horizontal)
                    } else {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text("Premium Subscription Active")
                                .font(.headline)
                                .foregroundColor(.green)
                        }
                    }
                    
                    // User Name Input
                    TextField("Enter your name", text: $userName)
                        .padding()
                        .background(Color.white.opacity(0.9))
                        .cornerRadius(15)
                        .padding(.horizontal, 20)
                        .focused($activeField, equals: .userName)
                        .autocapitalization(.words)
                        .toolbar {
                            ToolbarItem(placement: .keyboard) {
                                Button("Done") {
                                    hideKeyboard()
                                }
                            }
                        }
                    
                    // Update Name Button
                    Button(action: {
                        updateUserName()
                    }) {
                        HStack {
                            Image(systemName: "person.fill.checkmark")
                            Text("Update Name")
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color("highlight"))
                        .cornerRadius(10)
                    }
                    .padding(.horizontal, 20)
                    
                    // Phone Number Input
                    TextField("Enter phone number", text: $phoneNumber)
                        .padding()
                        .background(Color.white.opacity(0.9))
                        .cornerRadius(15)
                        .padding(.horizontal, 20)
                        .keyboardType(.phonePad)
                        .focused($activeField, equals: .phoneNumber)
                        .toolbar {
                            ToolbarItem(placement: .keyboard) {
                                Button("Done") {
                                    hideKeyboard()
                                }
                            }
                        }
                    
                    // Scenario Picker Section
                    VStack(spacing: 10) {
                        Text("Select a Scenario")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding(.bottom, 10)
                        
                        let columns = [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())]
                        
                        LazyVGrid(columns: columns, spacing: 15) {
                            ForEach(scenarios, id: \.self) { scenario in
                                Button(action: {
                                    selectedScenario = scenario
                                }) {
                                    VStack {
                                        Image(systemName: "hexagon.fill")
                                            .resizable()
                                            .frame(width: 30, height: 30)
                                            .foregroundColor(selectedScenario == scenario ? .white : .white)
                                            .scaleEffect(selectedScenario == scenario ? 1.2 : 1.0)
                                            .animation(.spring(), value: selectedScenario)
                                        
                                        Text(scenario.replacingOccurrences(of: "_", with: " ").capitalized)
                                            .font(.system(size: 14, weight: .bold))
                                            .foregroundColor(selectedScenario == scenario ? .white : .white)
                                            .multilineTextAlignment(.center)
                                    }
                                    .padding()
                                    .frame(width: 100, height: 100)
                                    .background(selectedScenario == scenario ? Color("highlight") : Color.white.opacity(0.2))
                                    .cornerRadius(15)
                                    .shadow(color: .gray.opacity(0.5), radius: 5, x: 0, y: 2)
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                    
                    // Action Buttons
                    VStack(spacing: 15) {
                        Button(action: {
                            makeImmediateCall()
                        }) {
                            HStack {
                                Image(systemName: "phone.fill")
                                Text("Make Call Now")
                            }
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color("highlight"))
                            .cornerRadius(10)
                        }
                        .padding(.horizontal, 20)
                        .disabled(callViewModel.isCallInProgress)
                        
                        Button(action: {
                            showCallHistory = true
                        }) {
                            HStack {
                                Image(systemName: "clock.arrow.circlepath")
                                Text("Call History")
                            }
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.white.opacity(0.2))
                            .cornerRadius(10)
                        }
                        .padding(.horizontal, 20)
                    }
                    
                    Spacer()
                }
            }
            .navigationTitle("AI Friend Chat")
            .navigationBarItems(
                leading: Button(action: { showAccountSheet = true }) {
                    Image(systemName: "person.circle")
                        .foregroundColor(.white)
                },
                trailing: HStack {
                    Button(action: { showSettingsSheet = true }) {
                        Image(systemName: "gearshape")
                            .foregroundColor(.white)
                    }
                    Button(action: { showHelpSheet = true }) {
                        Image(systemName: "questionmark.circle")
                            .foregroundColor(.white)
                    }
                }
            )
            .sheet(isPresented: $showAccountSheet) {
                AccountView()
            }
            .sheet(isPresented: $showSettingsSheet) {
                SettingsView()
            }
            .sheet(isPresented: $showHelpSheet) {
                HelpSupportView()
            }
            .sheet(isPresented: $showCallHistory) {
                CallHistoryView()
            }
            .alert(alertTitle, isPresented: $showAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(alertMessage)
            }
            .alert("Upgrade to Premium", isPresented: $showSubscriptionPrompt) {
                if let product = purchaseManager.products.first {
                    Button("Subscribe (\(product.displayPrice))", role: .none) {
                        Task {
                            try? await purchaseManager.purchase()
                        }
                    }
                    Button("Cancel", role: .cancel) {}
                }
            } message: {
                Text("Get unlimited calls and scheduling features!")
            }
        }
        .onAppear {
            loadUserData()
        }
    }
    
    // MARK: - Helper Methods
    private func loadUserData() {
        userName = UserDefaults.standard.string(forKey: "userName") ?? ""
    }
    
    private func updateUserName() {
        guard !userName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            alertTitle = "Error"
            alertMessage = "Please enter a valid name"
            showAlert = true
            return
        }
        
        isUpdatingName = true
        
        Task {
            do {
                _ = try await viewModel.updateUserName(to: userName)
                await MainActor.run {
                    UserDefaults.standard.set(userName, forKey: "userName")
                    isUpdatingName = false
                    alertTitle = "Success"
                    alertMessage = "Name updated successfully!"
                    showAlert = true
                }
            } catch {
                await MainActor.run {
                    isUpdatingName = false
                    alertTitle = "Error"
                    alertMessage = error.localizedDescription
                    showAlert = true
                }
            }
        }
    }
    
    private func makeImmediateCall() {
        guard !phoneNumber.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            alertTitle = "Error"
            alertMessage = "Please enter a phone number"
            showAlert = true
            return
        }
        
        callViewModel.initiateCall(phoneNumber: phoneNumber, scenario: selectedScenario)
    }
    
    private func hideKeyboard() {
        activeField = nil
    }
    
    private func handleCallViewModelError() {
        if let error = callViewModel.errorMessage {
            alertTitle = "Call Error"
            alertMessage = error
            showAlert = true
        }
    }
    
    private func handleCallViewModelSuccess() {
        if let success = callViewModel.successMessage {
            alertTitle = "Success"
            alertMessage = success
            showAlert = true
        }
    }
}

// MARK: - Supporting Types
let scenarios = [
    "default",
    "sister_emergency", 
    "mother_emergency",
    "yacht_party",
    "instigator",
    "gameshow_host"
]

#Preview {
    HomeView(modelContext: try! ModelContainer(for: CallHistory.self).mainContext)
        .environmentObject(AuthViewModel())
}




