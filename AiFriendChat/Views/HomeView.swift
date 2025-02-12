import SwiftUI
import SwiftData
import os.log
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
                BackgroundView()
                MainContentView(
                    phoneNumber: $phoneNumber,
                    selectedScenario: $selectedScenario,
                    userName: $userName,
                    activeField: _activeField.projectedValue,
                    viewModel: viewModel,
                    callViewModel: callViewModel,
                    purchaseManager: purchaseManager,
                    showSubscriptionPrompt: $showSubscriptionPrompt,
                    showSubscriptionAlert: $showSubscriptionAlert
                )
            }
            .navigationTitle("")
            .navigationBarItems(leading: LogoutButton(authViewModel: authViewModel))
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    MenuButtons(
                        showAccountSheet: $showAccountSheet,
                        showCallHistory: $showCallHistory,
                        showSettingsSheet: $showSettingsSheet,
                        showHelpSheet: $showHelpSheet,
                        showSubscriptionAlert: $showSubscriptionAlert,
                        purchaseManager: purchaseManager,
                        authViewModel: authViewModel
                    )
                }
            }
        }
        .alert("Upgrade to Premium", isPresented: $showSubscriptionAlert) {
            SubscriptionAlertButtons(purchaseManager: purchaseManager)
        } message: {
            Text("Get unlimited calls and scheduling features!")
        }
        .alert("Premium Feature", isPresented: $showPremiumAlert) {
            PremiumAlertButtons(showSubscriptionAlert: $showSubscriptionAlert)
        } message: {
            Text("Call scheduling is available for premium subscribers only.")
        }
        .onChange(of: callViewModel.errorMessage) { oldValue, newValue in
            handleCallViewModelError(newValue)
        }
        .onChange(of: callViewModel.successMessage) { oldValue, newValue in
            handleCallViewModelSuccess(newValue)
        }
    }
    
    // MARK: - Helper Views and Methods
    private func handleCallViewModelError(_ error: String?) {
        if let error = error {
            alertTitle = "Error"
            alertMessage = error
            showAlert = true
        }
    }
    
    private func handleCallViewModelSuccess(_ success: String?) {
        if let success = success {
            alertTitle = "Success"
            alertMessage = success
            showAlert = true
        }
    }
}

// MARK: - Supporting Views
private struct BackgroundView: View {
    var body: some View {
        LinearGradient(
            gradient: Gradient(colors: [Color("Color"), Color("Color 2")]),
            startPoint: .top,
            endPoint: .bottom
        )
        .edgesIgnoringSafeArea(.all)
    }
}

private struct SubscriptionAlertButtons: View {
    @ObservedObject var purchaseManager: PurchaseManager
    
    var body: some View {
        Group {
            if let product = purchaseManager.products.first {
                Button("Subscribe (\(product.displayPrice))", role: .none) {
                    Task {
                        try? await purchaseManager.purchase()
                    }
                }
                Button("Restore Purchases", role: .none) {
                    Task {
                        try? await purchaseManager.restorePurchases()
                    }
                }
            }
            Button("Cancel", role: .cancel) {}
        }
    }
}

private struct MainContentView: View {
    @Binding var phoneNumber: String
    @Binding var selectedScenario: String
    @Binding var userName: String
    @FocusState.Binding var activeField: Field?
    @ObservedObject var viewModel: HomeViewModel
    @ObservedObject var callViewModel: CallViewModel
    @ObservedObject var purchaseManager: PurchaseManager
    @Binding var showSubscriptionPrompt: Bool
    @Binding var showSubscriptionAlert: Bool
    
    var body: some View {
        ScrollView {
            VStack(spacing: 25) {
                Text("Welcome to AI Friend Chat")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding(.top)
                
                CallInputSection(
                    phoneNumber: $phoneNumber,
                    selectedScenario: $selectedScenario,
                    userName: $userName,
                    activeField: $activeField,
                    viewModel: viewModel,
                    callViewModel: callViewModel,
                    purchaseManager: purchaseManager
                )
            }
            .padding()
        }
    }
}

private struct LogoutButton: View {
    @ObservedObject var authViewModel: AuthViewModel
    
    var body: some View {
        Button {
            Task {
                authViewModel.logout()
            }
        } label: {
            Text("Logout")
                .foregroundColor(.white)
        }
    }
}

private struct PremiumAlertButtons: View {
    @Binding var showSubscriptionAlert: Bool
    
    var body: some View {
        Button("Subscribe", role: .none) {
            showSubscriptionAlert = true
        }
        Button("Cancel", role: .cancel) {}
    }
}

private struct MenuButtons: View {
    @Binding var showAccountSheet: Bool
    @Binding var showCallHistory: Bool
    @Binding var showSettingsSheet: Bool
    @Binding var showHelpSheet: Bool
    @Binding var showSubscriptionAlert: Bool
    @ObservedObject var purchaseManager: PurchaseManager
    @ObservedObject var authViewModel: AuthViewModel
    
    var body: some View {
        Menu {
            Button(action: { showAccountSheet = true }) {
                Label("Account", systemImage: "person.circle")
            }
            Button(action: { showCallHistory = true }) {
                Label("Call History", systemImage: "clock")
            }
            Button(action: { showSettingsSheet = true }) {
                Label("Settings", systemImage: "gear")
            }
            Button(action: { showHelpSheet = true }) {
                Label("Help", systemImage: "questionmark.circle")
            }
            
            if !purchaseManager.isSubscribed {
                Button(action: { showSubscriptionAlert = true }) {
                    Label("Upgrade to Premium", systemImage: "star.fill")
                }
            }
            
            Divider()
            
            Button(role: .destructive, action: {
                authViewModel.logout()
            }) {
                Label("Logout", systemImage: "rectangle.portrait.and.arrow.right")
            }
            
            #if DEBUG
            Menu("Debug") {
                Button("Toggle Premium") {
                    purchaseManager.toggleDebugPremium()
                }
            }
            #endif
        } label: {
            Image(systemName: "ellipsis.circle")
                .foregroundColor(.white)
        }
    }
}

private struct CallInputSection: View {
    @Binding var phoneNumber: String
    @Binding var selectedScenario: String
    @Binding var userName: String
    @FocusState.Binding var activeField: Field?
    @ObservedObject var viewModel: HomeViewModel
    @ObservedObject var callViewModel: CallViewModel
    @ObservedObject var purchaseManager: PurchaseManager
    
    var body: some View {
        VStack(spacing: 15) {
            TextField("Phone Number", text: $phoneNumber)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .keyboardType(.phonePad)
                .focused($activeField, equals: .phoneNumber)
            
            Picker("Scenario", selection: $selectedScenario) {
                ForEach(scenarios, id: \.self) { scenario in
                    Text(scenario.replacingOccurrences(of: "_", with: " ").capitalized)
                        .tag(scenario)
                }
            }
            .pickerStyle(MenuPickerStyle())
            
            Button(action: makeCall) {
                Text("Make Call")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(10)
            }
        }
        .padding()
    }
    
    private var scenarios: [String] {
        ["default", "sister_emergency", "mother_emergency", "yacht_party", "instigator", "gameshow_host"]
    }
    
    private func makeCall() {
        callViewModel.initiateCall(phoneNumber: phoneNumber, scenario: selectedScenario)
    }
}

// Additional supporting view structs would go here...




