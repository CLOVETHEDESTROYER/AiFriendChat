import SwiftUI
import StoreKit

struct SettingsView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var authViewModel = AuthViewModel()
    @StateObject private var purchaseManager = PurchaseManager.shared
    @State private var showSubscriptionOptions = false
    
    var body: some View {
        NavigationView {
            Form {
                Section("Call Preferences") {
                    NavigationLink(destination: CallPreferencesView()) {
                        Label("Call Settings", systemImage: "phone.circle")
                    }
                }
                
                Section("Appearance") {
                    NavigationLink(destination: ThemeSettingsView()) {
                        Label("Theme & Appearance", systemImage: "paintbrush")
                    }
                }
                
                Section("Notifications") {
                    NavigationLink(destination: NotificationSettingsView()) {
                        Label("Notification Settings", systemImage: "bell")
                    }
                }
                
                Section("Subscription") {
                    if !purchaseManager.isSubscribed {
                        Button(action: { showSubscriptionOptions = true }) {
                            Label("Upgrade to Premium", systemImage: "star.fill")
                                .foregroundColor(.yellow)
                        }
                    }
                    
                    Button(action: {
                        Task {
                            try? await purchaseManager.restorePurchases()
                        }
                    }) {
                        Label("Restore Purchases", systemImage: "arrow.clockwise")
                    }
                }
                
                #if DEBUG
                Section("Debug Info") {
                    Text("Calls Made: \(purchaseManager.callsMade)")
                    Text("Is Subscribed: \(purchaseManager.isSubscribed)")
                    Text("Has Token: \(KeychainManager.shared.getToken(forKey: "accessToken") != nil)")
                    Text("Onboarding Complete: \(UserDefaults.standard.bool(forKey: "hasCompletedOnboarding"))")
                    
                    Button("Test Backend Connection") {
                        testBackendConnection()
                    }
                    
                    Button("Reset Onboarding", role: .destructive) {
                        resetOnboarding()
                    }
                    
                    Button("Test Onboarding API") {
                        testOnboardingAPI()
                    }
                }
                #endif
                
                Section("Account") {
                    Button(role: .destructive, action: logout) {
                        Label("Logout", systemImage: "rectangle.portrait.and.arrow.right")
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarItems(trailing: Button("Done") { dismiss() })
            .alert("Upgrade to Premium", isPresented: $showSubscriptionOptions) {
                if let product = purchaseManager.products.first {
                    Button("Subscribe (\(product.displayPrice))", role: .none) {
                        Task {
                            try? await purchaseManager.purchase()
                        }
                    }
                    Button("Cancel", role: .cancel) {}
                }
            } message: {
                Text("Get 10 minutes of call time per week and scheduling features!")
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .onAppear {
            if purchaseManager.products.isEmpty {
                Task {
                    await purchaseManager.fetchProducts()
                }
            }
        }
    }
    
    private func logout() {
        authViewModel.logout()
        dismiss()
    }
    
    private func clearAllData() {
        let domain = Bundle.main.bundleIdentifier!
        UserDefaults.standard.removePersistentDomain(forName: domain)
        UserDefaults.standard.synchronize()
    }
    
    private func testBackendConnection() {
        Task {
            do {
                let stats = try await BackendService.shared.getUsageStats()
                print("✅ Backend connection successful: \(stats)")
            } catch {
                print("❌ Backend connection failed: \(error)")
            }
        }
    }
    
    private func resetOnboarding() {
        UserDefaults.standard.set(false, forKey: "hasCompletedOnboarding")
        UserDefaults.standard.synchronize()
        print("🔄 Onboarding reset - user will see onboarding on next app restart")
    }
    
    private func testOnboardingAPI() {
        Task {
            do {
                let status = try await BackendService.shared.getOnboardingStatus()
                print("✅ Onboarding API successful: \(status)")
            } catch {
                print("❌ Onboarding API failed: \(error)")
                
                // Test initialization
                do {
                    let initStatus = try await BackendService.shared.initializeOnboarding()
                    print("✅ Onboarding initialization successful: \(initStatus)")
                } catch {
                    print("❌ Onboarding initialization failed: \(error)")
                }
            }
        }
    }
}

struct CallPreferencesView: View {
    @Environment(\.dismiss) var dismiss
    @AppStorage("defaultScenario") private var defaultScenario = "default"
    @AppStorage("autoConfirmCalls") private var autoConfirmCalls = false
    @AppStorage("callTimeout") private var callTimeout = 5
    
    let scenarios = ["fake_doctor", "fake_celebrity", "fake_boss", "fake_tech_support", "fake_lottery_winner", "fake_old_friend"]
    let timeoutOptions = [1, 2, 5, 10, 15]
    
    var body: some View {
        Form {
            Section("Default Settings") {
                Picker("Default Scenario", selection: $defaultScenario) {
                    ForEach(scenarios, id: \.self) { scenario in
                        Text(scenario.replacingOccurrences(of: "_", with: " ").capitalized)
                            .tag(scenario)
                    }
                }
                
                Toggle("Auto-confirm Calls", isOn: $autoConfirmCalls)
            }
            
            Section("Timeouts") {
                Picker("Call Timeout (minutes)", selection: $callTimeout) {
                    ForEach(timeoutOptions, id: \.self) { timeout in
                        Text("\(timeout) minutes")
                            .tag(timeout)
                    }
                }
            }
        }
        .navigationTitle("Call Preferences")
    }
}

struct ThemeSettingsView: View {
    @Environment(\.dismiss) var dismiss
    @AppStorage("selectedTheme") private var selectedTheme = "default"
    
    let themes = ["default", "dark", "light"]
    
    var body: some View {
        Form {
            Section("Theme") {
                Picker("App Theme", selection: $selectedTheme) {
                    ForEach(themes, id: \.self) { theme in
                        Text(theme.capitalized)
                            .tag(theme)
                    }
                }
            }
        }
        .navigationTitle("Theme Settings")
    }
}

struct NotificationSettingsView: View {
    @Environment(\.dismiss) var dismiss
    @AppStorage("enableNotifications") private var enableNotifications = true
    @AppStorage("callReminders") private var callReminders = true
    @AppStorage("subscriptionUpdates") private var subscriptionUpdates = true
    
    var body: some View {
        Form {
            Section("Notifications") {
                Toggle("Enable Notifications", isOn: $enableNotifications)
                Toggle("Call Reminders", isOn: $callReminders)
                Toggle("Subscription Updates", isOn: $subscriptionUpdates)
            }
        }
        .navigationTitle("Notification Settings")
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
} 
