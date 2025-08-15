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
    @State private var showAuthPrompt = false
    @State private var showAuthView = false
    
    // NEW: Enhanced features
    @State private var showEnhancedScenarioSelection = false
    @State private var showUsageStats = false
    @State private var usageStats: UsageStats?
    @State private var isLoadingStats = true
    
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
                
                ScrollView {
                VStack(spacing: 20) {
                    // Header
                    Text("Welcome to AI Friend Chat")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .padding()
                    
                        // Enhanced Usage Stats Card
                        if let stats = usageStats {
                            EnhancedStatusCard(stats: stats)
                                .padding(.horizontal, 20)
                        } else if isLoadingStats {
                            ProgressView("Loading usage stats...")
                        .foregroundColor(.white)
                                .padding()
                        }
                        
                        // Call Duration Display (if call in progress)
                        if callViewModel.isCallInProgress {
                            CallDurationCard(
                                currentDuration: callViewModel.currentCallDuration,
                                durationLimit: callViewModel.callDurationLimit,
                                showWarning: callViewModel.showDurationWarning
                            )
                            .padding(.horizontal, 20)
                        }
                    
                    // User Name Input
                    TextField("Enter your name", text: $userName)
                        .padding()
                        .background(Color(.sRGB, white: 1, opacity: 0.9))
                        .cornerRadius(15)
                        .padding(.horizontal, 20)
                        .focused($activeField, equals: .userName)
                        .autocapitalization(.words)
                            .disableAutocorrection(true)
                    
                    // Update Name Button
                    Button(action: {
                        updateUserName()
                    }) {
                        HStack {
                                if isUpdatingName {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                } else {
                            Image(systemName: "person.fill.checkmark")
                                }
                                Text(isUpdatingName ? "Updating..." : "Update Name")
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color("highlight"))
                        .cornerRadius(10)
                    }
                    .padding(.horizontal, 20)
                        .disabled(isUpdatingName)
                    
                    // Phone Number Input
                    TextField("Enter phone number", text: $phoneNumber)
                        .padding()
                        .background(Color(.sRGB, white: 1, opacity: 0.9))
                        .cornerRadius(15)
                        .padding(.horizontal, 20)
                        .keyboardType(.phonePad)
                        .focused($activeField, equals: .phoneNumber)
                            .disableAutocorrection(true)
                        
                        // Enhanced Scenario Selection Button
                        Button(action: {
                            showEnhancedScenarioSelection = true
                        }) {
                            HStack {
                                Image(systemName: "list.bullet.circle")
                                Text("Select Scenario")
                                Spacer()
                                Text(getScenarioDisplayName(selectedScenario))
                                    .font(.caption)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.white.opacity(0.3))
                                    .cornerRadius(8)
                                Image(systemName: "chevron.right")
                            }
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding()
                            .background(Color(.sRGB, white: 1, opacity: 0.2))
                            .cornerRadius(10)
                        }
                        .padding(.horizontal, 20)
                        
                        // Action Buttons
                        enhancedActionButtons
                        
                        Spacer(minLength: 50)
                    }
                }
                .refreshable {
                    await loadUsageStats()
                }
            }
            .navigationTitle("AI Friend Chat")
            .navigationBarItems(
                leading: Button(action: { showAccountSheet = true }) {
                    Image(systemName: "person.circle")
                        .foregroundColor(.white)
                },
                trailing: HStack {
                    Button(action: { showUsageStats = true }) {
                        Image(systemName: "chart.bar.fill")
                            .foregroundColor(.white)
                    }
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
            .sheet(isPresented: $showAuthPrompt) {
                AuthPromptView(showAuthView: $showAuthView)
            }
            .sheet(isPresented: $showEnhancedScenarioSelection) {
                NavigationView {
                    EnhancedScenarioSelectionView(selectedScenario: $selectedScenario)
                        .navigationTitle("Select Scenario")
                        .navigationBarTitleDisplayMode(.inline)
                        .toolbar {
                            ToolbarItem(placement: .navigationBarTrailing) {
                                Button("Done") {
                                    showEnhancedScenarioSelection = false
                                }
                            }
                        }
                }
                .presentationDetents([.medium, .large])
            }
            .sheet(isPresented: $showUsageStats) {
                NavigationView {
                    if let stats = usageStats {
                        EnhancedUsageStatsView(stats: stats)
                            .navigationTitle("Usage Statistics")
                            .navigationBarTitleDisplayMode(.inline)
                            .toolbar {
                                ToolbarItem(placement: .navigationBarTrailing) {
                                    Button("Done") {
                                        showUsageStats = false
                                    }
                                }
                            }
                    } else {
                        ProgressView("Loading statistics...")
                    }
                }
            }
            .alert(alertTitle, isPresented: $showAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(alertMessage)
            }
            .alert("Upgrade Required", isPresented: $callViewModel.showUpgradePrompt) {
                Button("View Plans", role: .none) {
                    showUsageStats = true
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text(callViewModel.upgradeMessage ?? "Upgrade to continue making calls!")
            }
            .onAppear {
                loadUserData()
                Task {
                    await loadUsageStats()
                }
            }
            .onChange(of: callViewModel.errorMessage) { _, newValue in
                if let error = newValue {
                    alertTitle = "Call Error"
                    alertMessage = error
                    showAlert = true
                }
            }
            .onChange(of: callViewModel.successMessage) { _, newValue in
                if let success = newValue {
                    alertTitle = "Success"
                    alertMessage = success
                    showAlert = true
                }
            }
        }
    }
    
    // MARK: - Enhanced Components
    
    private var enhancedActionButtons: some View {
        VStack(spacing: 15) {
            Button(action: {
                makeImmediateCall()
            }) {
                HStack {
                    if callViewModel.isCallInProgress {
                        ProgressView()
                            .scaleEffect(0.8)
                            .tint(.white)
                    } else {
                        Image(systemName: "phone.fill")
                    }
                    Text(callViewModel.isCallInProgress ? "Call in Progress..." : "Make Call Now")
                }
                .font(.headline)
                .foregroundColor(.white)
                .padding()
                .frame(maxWidth: .infinity)
                .background(callViewModel.isCallInProgress ? Color.orange : Color("highlight"))
                .cornerRadius(10)
            }
            .padding(.horizontal, 20)
            .disabled(callViewModel.isCallInProgress)
            
            // End Call Button (when call is in progress)
            if callViewModel.isCallInProgress {
                Button(action: {
                    callViewModel.endCall()
                }) {
                    HStack {
                        Image(systemName: "phone.down.fill")
                        Text("End Call")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.red)
                    .cornerRadius(10)
                }
                .padding(.horizontal, 20)
            }
            
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
                .background(Color(.sRGB, white: 1, opacity: 0.2))
                .cornerRadius(10)
            }
            .padding(.horizontal, 20)
        }
    }
    
    // MARK: - Helper Methods
    
    private func loadUserData() {
        userName = UserDefaults.standard.string(forKey: "userName") ?? ""
    }
    
    private func loadUsageStats() async {
        isLoadingStats = true
        await callViewModel.loadUsageStats()
        await MainActor.run {
            self.usageStats = callViewModel.usageStats
            self.isLoadingStats = false
        }
    }
    
    private func updateUserName() {
        guard !userName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            alertTitle = "Error"
            alertMessage = "Please enter a valid name"
            showAlert = true
            return
        }
        
        // If not signed in, show the auth prompt modal
        guard authViewModel.user != nil else {
            showAuthPrompt = true
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
    
    private func getScenarioDisplayName(_ scenario: String) -> String {
        return scenario.replacingOccurrences(of: "_", with: " ").capitalized
    }
}

// MARK: - Enhanced Status Card

struct EnhancedStatusCard: View {
    let stats: UsageStats
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading) {
                    Text("Status")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))
                    Text(statusText)
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                }
                Spacer()
                VStack(alignment: .trailing) {
                    Text("Calls")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))
                    Text(callsText)
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                }
            }
            
            if stats.upgrade_recommended {
                HStack {
                    Text("💡 Ready to upgrade for more calls?")
                        .font(.caption)
                        .foregroundColor(.yellow)
                    Spacer()
                }
            }
        }
        .padding()
        .background(Color(.sRGB, white: 1, opacity: 0.2))
        .cornerRadius(12)
    }
    
    private var statusText: String {
        if stats.is_subscribed {
            switch stats.subscription_tier {
            case "mobile_basic":
                return "Basic Plan"
            case "mobile_premium":
                return "Premium Plan"
            default:
                return "Subscribed"
            }
        } else if stats.is_trial_active {
            return "Trial Active"
        } else {
            return "Trial Ended"
        }
    }
    
    private var callsText: String {
        if stats.is_subscribed {
            if stats.subscription_tier == "mobile_basic" {
                return "\(max(0, 5 - stats.calls_made_this_week))/5"
            } else if stats.subscription_tier == "mobile_premium" {
                return "\(max(0, 30 - stats.calls_made_this_month))/30"
            }
        }
        return "\(stats.trial_calls_remaining) left"
    }
}

// MARK: - Call Duration Card

struct CallDurationCard: View {
    let currentDuration: TimeInterval
    let durationLimit: Int
    let showWarning: Bool
    
    var body: some View {
        VStack(spacing: 8) {
                HStack {
                Text("⏱️ Call Duration")
                .font(.headline)
                .foregroundColor(.white)
                Spacer()
                Text("\(formatDuration(Int(currentDuration))) / \(formatDuration(durationLimit))")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(showWarning ? .red : .white)
            }
            
            ProgressView(value: currentDuration, total: Double(durationLimit))
                .progressViewStyle(LinearProgressViewStyle(tint: showWarning ? .red : .green))
            
            if showWarning {
                Text("⚠️ Call will end soon!")
                    .font(.caption)
                    .foregroundColor(.red)
                    .fontWeight(.bold)
            }
        }
        .padding()
        .background(Color(.sRGB, white: 1, opacity: 0.2))
        .cornerRadius(12)
    }
    
    private func formatDuration(_ seconds: Int) -> String {
        let minutes = seconds / 60
        let remainingSeconds = seconds % 60
        return String(format: "%d:%02d", minutes, remainingSeconds)
    }
}

#Preview {
    HomeView(modelContext: try! ModelContainer(for: CallHistory.self).mainContext)
        .environmentObject(AuthViewModel())
}
