import SwiftUI

struct AccountView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @Environment(\.dismiss) var dismiss
    @StateObject private var purchaseManager = PurchaseManager.shared
    @State private var showChangePassword = false
    @State private var showPrivacyPolicy = false
    @State private var showTerms = false
    @State private var showEULA = false
    @State private var showSubscriptionOptions = false
    
    var body: some View {
        NavigationView {
            List {
                Section("Profile") {
                    HStack {
                        Label("Email", systemImage: "envelope")
                        Spacer()
                        Text(authViewModel.user?.email ?? "Not available")
                            .foregroundColor(.gray)
                    }
                    
                    HStack {
                        Label("Subscription", systemImage: "star.circle")
                        Spacer()
                        Text(purchaseManager.isSubscribed ? "Weekly Premium Active" : "Free Trial")
                            .foregroundColor(purchaseManager.isSubscribed ? .green : .orange)
                    }
                    
                    if !purchaseManager.isSubscribed {
                        HStack {
                            Label("Trial Calls", systemImage: "phone.circle")
                            Spacer()
                            Text("\(purchaseManager.getRemainingTrialCalls()) remaining")
                                .foregroundColor(.orange)
                        }
                    }
                }
                
                Section("Subscription Information") {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Weekly Premium")
                                .font(.headline)
                            Spacer()
                            Text("$4.99/week")
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
                        
                        if !purchaseManager.isSubscribed {
                            Button(action: { showSubscriptionOptions = true }) {
                                Text("Upgrade to Weekly Premium")
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.blue)
                                    .foregroundColor(.white)
                                    .cornerRadius(8)
                            }
                            .padding(.top, 8)
                        }
                    }
                    .padding(.vertical, 4)
                }
                
                Section("Subscription Management") {
                    Button(action: { purchaseManager.restorePurchases() }) {
                        Label("Restore Purchases", systemImage: "arrow.clockwise")
                    }
                    
                    if purchaseManager.isSubscribed {
                        Button(action: {
                            // Open App Store subscription management
                            if let url = URL(string: "https://apps.apple.com/account/subscriptions") {
                                UIApplication.shared.open(url)
                            }
                        }) {
                            Label("Manage Subscription", systemImage: "creditcard")
                        }
                    }
                }
                
                Section("Privacy & Legal") {
                    Button(action: { showChangePassword = true }) {
                        Label("Change Password", systemImage: "lock.rotation")
                    }
                    
                    Button(action: { showPrivacyPolicy = true }) {
                        Label("Privacy Policy", systemImage: "hand.raised.fill")
                    }
                    
                    Button(action: { showTerms = true }) {
                        Label("Terms of Service", systemImage: "doc.text")
                    }
                    
                    Button(action: { showEULA = true }) {
                        Label("End User License Agreement", systemImage: "doc.text.fill")
                    }
                }
                
                Section("Account Actions") {
                    Button(role: .destructive, action: {
                        authViewModel.logout()
                        dismiss()
                    }) {
                        Label("Logout", systemImage: "rectangle.portrait.and.arrow.right")
                    }
                }
            }
            .navigationTitle("Account")
            .navigationBarItems(trailing: Button("Done") { dismiss() })
            .sheet(isPresented: $showChangePassword) {
                ChangePasswordView()
            }
            .sheet(isPresented: $showPrivacyPolicy) {
                PrivacyPolicyView()
            }
            .sheet(isPresented: $showTerms) {
                TermsOfServiceView()
            }
            .sheet(isPresented: $showEULA) {
                EULAView()
            }
            .alert("Upgrade to Weekly Premium", isPresented: $showSubscriptionOptions) {
                if let product = purchaseManager.preferredSubscriptionProduct {
                    Button("Subscribe (\(product.priceLocale.currencySymbol ?? "$")\(product.price)/week)", role: .none) {
                        purchaseManager.purchase(product: product)
                    }
                    Button("Cancel", role: .cancel) {}
                }
            } message: {
                Text("Get unlimited calls and scheduling features with our Weekly Premium subscription!")
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}

// Placeholder views - implement these based on your needs
struct ChangePasswordView: View {
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    SecureField("Current Password", text: .constant(""))
                    SecureField("New Password", text: .constant(""))
                    SecureField("Confirm New Password", text: .constant(""))
                }
                
                Button("Change Password") {
                    // Implement password change logic
                }
                .disabled(true) // Enable when fields are valid
            }
            .navigationTitle("Change Password")
            .navigationBarItems(trailing: Button("Cancel") { dismiss() })
        }
    }
}

struct PrivacyPolicyView: View {
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Privacy Policy")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .padding(.bottom)
                    
                    Text("""
                    At Hyperlabs AI and AI Friend Chat, we prioritize your privacy. We do not sell your data to anyone, and we take extensive measures to store it securely. Your trust is essential to us and we are committed to protecting your personal information.
                    
                    For our complete privacy policy, please visit:
                    """)
                    .padding(.bottom)
                    
                    Link("Privacy Policy", destination: URL(string: "https://www.hyperlabsai.com/privacypolicy")!)
                        .foregroundColor(.blue)
                        .underline()
                    
                    Spacer()
                }
                .padding()
            }
            .navigationTitle("Privacy Policy")
            .navigationBarItems(trailing: Button("Done") { dismiss() })
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}

struct TermsOfServiceView: View {
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Terms of Service")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .padding(.bottom)
                    
                    Text("""
                    By using AI Friend Chat, you agree to these terms:
                    
                    • You must be 13 years or older to use this service
                    • You are responsible for all calls made through your account
                    • We reserve the right to modify these terms at any time
                    • Service is provided "as is" without warranties
                    • We are not responsible for any damages from use of the service
                    
                    For complete terms, please contact support.
                    """)
                    
                    Spacer()
                }
                .padding()
            }
            .navigationTitle("Terms of Service")
            .navigationBarItems(trailing: Button("Done") { dismiss() })
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
} 
