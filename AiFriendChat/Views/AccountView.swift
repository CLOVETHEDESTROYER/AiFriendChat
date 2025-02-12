import SwiftUI

struct AccountView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @Environment(\.dismiss) var dismiss
    @StateObject private var purchaseManager = PurchaseManager.shared
    @State private var showChangePassword = false
    @State private var showPrivacyPolicy = false
    @State private var showTerms = false
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
                        Text(purchaseManager.isSubscribed ? "Premium" : "Free Trial")
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
                
                Section("Privacy & Security") {
                    Button(action: { showChangePassword = true }) {
                        Label("Change Password", systemImage: "lock.rotation")
                    }
                    
                    Button(action: { showPrivacyPolicy = true }) {
                        Label("Privacy Policy", systemImage: "hand.raised.fill")
                    }
                    
                    Button(action: { showTerms = true }) {
                        Label("Terms of Service", systemImage: "doc.text")
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
                Text("Your Privacy Policy content here...")
                    .padding()
            }
            .navigationTitle("Privacy Policy")
            .navigationBarItems(trailing: Button("Done") { dismiss() })
        }
    }
}

struct TermsOfServiceView: View {
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                Text("Your Terms of Service content here...")
                    .padding()
            }
            .navigationTitle("Terms of Service")
            .navigationBarItems(trailing: Button("Done") { dismiss() })
        }
    }
} 
