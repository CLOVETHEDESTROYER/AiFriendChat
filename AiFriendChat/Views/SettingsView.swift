import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) var dismiss
    @AppStorage("notificationsEnabled") private var notificationsEnabled = true
    @AppStorage("callSound") private var callSound = true
    @AppStorage("darkMode") private var darkMode = false
    @AppStorage("userName") private var userName = ""
    @StateObject private var purchaseManager = PurchaseManager.shared
    
    var body: some View {
        NavigationView {
            List {
                Section("Notifications") {
                    Toggle("Enable Notifications", isOn: $notificationsEnabled)
                    Toggle("Call Sound", isOn: $callSound)
                }
                
                Section("Appearance") {
                    Toggle("Dark Mode", isOn: $darkMode)
                }
                
                Section("Call Settings") {
                    if purchaseManager.isSubscribed {
                        NavigationLink("Manage Call Preferences") {
                            CallPreferencesView()
                        }
                    } else {
                        HStack {
                            Text("Call Preferences")
                            Spacer()
                            Text("Premium Only")
                                .foregroundColor(.gray)
                        }
                    }
                }
                
                Section("Subscription") {
                    if !purchaseManager.isSubscribed {
                        VStack(alignment: .leading, spacing: 8) {
                            if purchaseManager.isLoadingProducts {
                                HStack {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                    Text("Loading subscription options...")
                                        .font(.subheadline)
                                        .foregroundColor(.gray)
                                }
                            } else if let error = purchaseManager.loadingError {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Unable to load subscription options")
                                        .font(.subheadline)
                                        .foregroundColor(.red)
                                    Text(error)
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                    Button("Retry") {
                                        purchaseManager.loadProducts()
                                    }
                                    .padding(.top, 4)
                                }
                            } else if let product = purchaseManager.preferredSubscriptionProduct {
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack {
                                        Text("Weekly Premium")
                                            .font(.headline)
                                        Spacer()
                                        Text("\(product.priceLocale.currencySymbol ?? "$")\(product.price)/week")
                                            .font(.headline)
                                            .foregroundColor(.blue)
                                    }
                                    
                                    Text("• Unlimited calls")
                                        .font(.subheadline)
                                        .foregroundColor(.gray)
                                    Text("• Call scheduling")
                                        .font(.subheadline)
                                        .foregroundColor(.gray)
                                    Text("• All scenarios")
                                        .font(.subheadline)
                                        .foregroundColor(.gray)
                                    
                                    Button(action: { 
                                        purchaseManager.purchase(product: product)
                                    }) {
                                        Text("Subscribe Now")
                                            .frame(maxWidth: .infinity)
                                            .padding()
                                            .background(Color.blue)
                                            .foregroundColor(.white)
                                            .cornerRadius(8)
                                    }
                                    .padding(.top, 4)
                                }
                            } else {
                                Text("No subscription options available")
                                    .foregroundColor(.gray)
                                    .font(.subheadline)
                            }
                        }
                        
                        Button(action: { purchaseManager.restorePurchases() }) {
                            Text("Restore Purchases")
                        }
                    } else {
                        Text("Premium Subscription Active")
                            .foregroundColor(.green)
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
            }
            .navigationTitle("Settings")
            .navigationBarItems(trailing: Button("Done") { dismiss() })
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .onAppear {
            if !purchaseManager.isLoadingProducts && purchaseManager.products.isEmpty {
                purchaseManager.loadProducts()
            }
        }
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

#Preview {
    SettingsView()
} 