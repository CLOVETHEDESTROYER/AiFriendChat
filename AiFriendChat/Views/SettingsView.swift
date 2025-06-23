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
                
                Section("Debug Options") {
                    #if DEBUG
                    Button("Toggle Premium Status") {
                        purchaseManager.toggleDebugPremium()
                    }
                    
                    Button("Reset Call Count") {
                        UserDefaults.standard.removeObject(forKey: "callsMadeCount")
                        purchaseManager.objectWillChange.send()
                    }
                    
                    Button("Clear All Data") {
                        clearAllData()
                    }
                    .foregroundColor(.red)
                    #endif
                }
                
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
                Text("Get unlimited calls and scheduling features!")
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .onAppear {
            if !purchaseManager.isLoadingProducts && purchaseManager.products.isEmpty {
                purchaseManager.loadProducts()
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
}

struct CallPreferencesView: View {
    @Environment(\.dismiss) var dismiss
    @AppStorage("defaultScenario") private var defaultScenario = "default"
    @AppStorage("autoConfirmCalls") private var autoConfirmCalls = false
    @AppStorage("callTimeout") private var callTimeout = 5
    
    let scenarios = ["default", "sister_emergency", "mother_emergency", "yacht_party", "instigator", "gameshow_host"]
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

#Preview {
    SettingsView()
} 
