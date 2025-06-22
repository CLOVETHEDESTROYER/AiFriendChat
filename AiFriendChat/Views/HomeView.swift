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
<<<<<<< HEAD
    @StateObject private var callViewModel = CallViewModel()
    @StateObject private var backendService = BackendService.shared
=======
    @StateObject private var callViewModel: CallViewModel
    @StateObject private var purchaseManager = PurchaseManager.shared
    
    // MARK: - State Properties
>>>>>>> webrtc-integration
    @State private var phoneNumber = ""
    @State private var selectedScenario = "default"
    @State private var userName = ""
    @State private var isUpdatingName = false
<<<<<<< HEAD
    @State private var usageStats: UsageStats?

    // Notification state variables
=======
    @State private var showAlert = false
>>>>>>> webrtc-integration
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
<<<<<<< HEAD
                // Gradient background
                LinearGradient(
                    gradient: Gradient(colors: [Color("Color 1"), Color("Color 2")]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .edgesIgnoringSafeArea(.all)
                
                VStack(spacing: 20) {
                    // Header
                    Text("Welcome to AI Friend Chat")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(.black)
                        .padding()
                    
                    // Trial/Subscription Status
                    if let stats = usageStats {
                        VStack(spacing: 8) {
                            if stats.is_subscribed {
                                HStack {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.green)
                                    Text("Premium Subscription Active")
                                        .font(.headline)
                                        .foregroundColor(.green)
                                }
                            } else if stats.is_trial_active {
                                HStack {
                                    Image(systemName: "clock.fill")
                                        .foregroundColor(.orange)
                                    Text("Trial Calls Remaining: \(stats.trial_calls_remaining)")
                                        .font(.headline)
                                        .foregroundColor(.black)
                                }
                            } else {
                                HStack {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .foregroundColor(.red)
                                    Text("Trial Expired")
                                        .font(.headline)
                                        .foregroundColor(.red)
                                }
                            }
                            
                            if stats.upgrade_recommended {
                                Text("💡 Ready to upgrade?")
                                    .font(.subheadline)
                                    .foregroundColor(.orange)
                            }
                        }
                        .padding(.horizontal)
                    } else {
                        // Fallback to local purchase manager
                        if !purchaseManager.isSubscribed {
                            Text("Trial Calls Remaining: \(purchaseManager.getRemainingTrialCalls())")
                                .font(.subheadline)
                                .foregroundColor(.black)
                                .padding(.horizontal)
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
                            .foregroundColor(.black)
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
                                            .foregroundColor(selectedScenario == scenario ? .white : .black)
                                            .scaleEffect(selectedScenario == scenario ? 1.2 : 1.0)
                                            .animation(.spring(), value: selectedScenario)
                                        
                                        Text(scenario.replacingOccurrences(of: "_", with: " ").capitalized)
                                            .font(.system(size: 14, weight: .bold))
                                            .foregroundColor(selectedScenario == scenario ? .white : .black)
                                            .multilineTextAlignment(.center)
                                    }
                                    .padding()
                                    .frame(width: 100, height: 100)
                                    .background(selectedScenario == scenario ? Color("highlight") : Color.white.opacity(0.8))
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
                                Image(systemName: "phone.arrow.up.right")
                                Text("Make Immediate Call")
                            }
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color("highlight"))
                            .cornerRadius(10)
                        }
                        .disabled(phoneNumber.isEmpty || callViewModel.isCallInProgress)
                        
                        NavigationLink(
                            destination: ScheduleCallView(phoneNumber: phoneNumber, scenario: selectedScenario)
                        ) {
                            HStack {
                                Image(systemName: "calendar.badge.plus")
                                Text("Schedule Call")
                            }
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(purchaseManager.isSubscribed ? Color("AccentColor") : Color.gray)
                            .cornerRadius(10)
                        }
                        .disabled(!purchaseManager.isSubscribed)
                        .onTapGesture {
                            if !purchaseManager.isSubscribed {
                                showSubscriptionPrompt = true
                            }
                        }
                        
                        if !purchaseManager.isSubscribed {
                            Button(action: {
                                showSubscriptionAlert = true
                            }) {
                                HStack {
                                    Image(systemName: "star.fill")
                                    Text("Upgrade to Weekly Premium")
                                }
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(Color.yellow)
                                .cornerRadius(10)
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                }
                .navigationTitle("")
                .navigationBarItems(
                    leading: Button("Logout") {
                        authViewModel.logout()
                    }
                )
                .onTapGesture {
                    hideKeyboard()
                }
            }
            .alert(isPresented: $showAlert) {
                Alert(
                    title: Text(alertTitle),
                    message: Text(alertMessage),
                    dismissButton: .default(Text("OK"))
                )
            }
            .alert("Upgrade to Weekly Premium", isPresented: $showSubscriptionAlert) {
                if let product = purchaseManager.preferredSubscriptionProduct {
                    Button("Subscribe (\(product.priceLocale.currencySymbol ?? "$")\(product.price)/week)", role: .none) {
                        purchaseManager.purchase(product: product)
                    }
                    Button("Restore Purchases", role: .none) {
                        purchaseManager.restorePurchases()
                    }
                    Button("Cancel", role: .cancel) {}
                }
            } message: {
                Text("Get unlimited calls and scheduling features with our Weekly Premium subscription!")
            }
            .alert("Premium Feature", isPresented: $showPremiumAlert) {
                Button("Subscribe", role: .none) {
                    showSubscriptionAlert = true
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Call scheduling is available for premium subscribers only.")
            }
            .alert("Upgrade to Weekly Premium", isPresented: $showSubscriptionPrompt) {
                Button("View Premium Features", role: .none) {
                    showSubscriptionAlert = true
                }
                Button("Maybe Later", role: .cancel) {}
            } message: {
                Text("Schedule calls and get unlimited immediate calls with our Weekly Premium subscription!")
            }
            .alert("Upgrade Required", isPresented: $callViewModel.showUpgradePrompt) {
                Button("Upgrade Now", role: .none) {
                    showSubscriptionAlert = true
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text(callViewModel.upgradeMessage)
            }
            .onChange(of: callViewModel.errorMessage) { newValue in
                if let error = newValue {
                    alertTitle = "Error"
                    alertMessage = error
                    showAlert = true
                }
            }
            .onChange(of: callViewModel.successMessage) { newValue in
                if let success = newValue {
                    alertTitle = "Success"
                    alertMessage = success
                    showAlert = true
                }
            }
            .onAppear {
                loadUsageStats()
            }
            #if DEBUG
=======
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
>>>>>>> webrtc-integration
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
    
<<<<<<< HEAD
    private func loadUsageStats() {
        Task {
            do {
                let stats = try await backendService.getUsageStats()
                await MainActor.run {
                    self.usageStats = stats
                }
            } catch {
                print("Failed to load usage stats: \(error)")
                // Keep using local purchase manager as fallback
            }
        }
    }
    
    private func makeImmediateCall() {
        guard !phoneNumber.isEmpty else {
=======
    // MARK: - Helper Views and Methods
    private func handleCallViewModelError(_ error: String?) {
        if let error = error {
>>>>>>> webrtc-integration
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




