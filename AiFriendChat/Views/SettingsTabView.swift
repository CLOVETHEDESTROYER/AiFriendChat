import SwiftUI
import StoreKit

struct SettingsTabView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var purchaseManager = PurchaseManager.shared
    @State private var showSubscriptionAlert = false
    @State private var showCustomPrompts = false
    @State private var showHelpSheet = false
    @State private var showAuthView = false
    
    var body: some View {
        NavigationView {
            ZStack {
                BackgroundGradient()
                
                ScrollView {
                    VStack(spacing: 20) {
                        if !purchaseManager.isSubscribed {
                            PremiumUpgradeSection(purchaseManager: purchaseManager)
                        }
                        SettingsListSection(
                            showCustomPrompts: $showCustomPrompts,
                            showHelpSheet: $showHelpSheet,
                            purchaseManager: purchaseManager,
                            authViewModel: authViewModel
                        )
                    }
                    .padding()
                }
            }
            .navigationTitle("Settings")
        }
    }
}

// MARK: - Supporting Views
private struct BackgroundGradient: View {
    var body: some View {
        LinearGradient(
            gradient: Gradient(colors: [Color("Color"), Color("Color 2")]),
            startPoint: .top,
            endPoint: .bottom
        )
        .edgesIgnoringSafeArea(.all)
    }
}

private struct PremiumUpgradeSection: View {
    @ObservedObject var purchaseManager: PurchaseManager
    @State private var showError = false
    @State private var errorMessage = ""
    
    var body: some View {
        VStack(spacing: 15) {
            // Premium Header
            VStack(spacing: 8) {
                Image(systemName: "star.circle.fill")
                    .font(.system(size: 44))
                    .foregroundColor(.yellow)
                
                Text("Upgrade to Premium")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text("Get 10 minutes of call time per week and custom scenarios")
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
            }
            .padding(.bottom, 8)
            
            // Features List
            VStack(alignment: .leading, spacing: 12) {
                FeatureRow(icon: "infinity", text: "10 minutes of call time per week")
                FeatureRow(icon: "calendar", text: "Schedule calls in advance")
                FeatureRow(icon: "text.bubble", text: "Custom conversation scenarios")
                FeatureRow(icon: "person.2", text: "Priority support")
            }
            .padding(.bottom, 16)
            
            // Subscribe Button
            if let product = purchaseManager.products.first {
                Button {
                    Task {
                        do {
                            try await purchaseManager.purchase()
                        } catch {
                            errorMessage = error.localizedDescription
                            showError = true
                        }
                    }
                } label: {
                    HStack {
                        Image(systemName: "star.fill")
                        Text("Subscribe for \(product.displayPrice)/month")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color("highlight"))
                    .cornerRadius(15)
                }
                .padding(.horizontal)
            } else {
                ProgressView()
                    .tint(.white)
            }
            
            // Restore Purchases Button
            Button {
                Task {
                    do {
                        try await purchaseManager.restorePurchases()
                    } catch {
                        errorMessage = error.localizedDescription
                        showError = true
                    }
                }
            } label: {
                Text("Restore Purchases")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.8))
            }
        }
        .padding()
        .background(Color.black.opacity(0.3))
        .cornerRadius(15)
        .padding(.horizontal)
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
    }
}

private struct FeatureRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.yellow)
                .frame(width: 24)
            Text(text)
                .foregroundColor(.white)
            Spacer()
        }
    }
}

private struct SettingsListSection: View {
    @Binding var showCustomPrompts: Bool
    @Binding var showHelpSheet: Bool
    @ObservedObject var purchaseManager: PurchaseManager
    @ObservedObject var authViewModel: AuthViewModel
    
    var body: some View {
        VStack(spacing: 2) {
            NavigationLink(destination: CustomPromptView()) {
                SettingsRow(icon: "text.bubble.fill", title: "Custom Prompts", showArrow: true)
            }
            
            NavigationLink(destination: HelpSupportView()) {
                SettingsRow(icon: "questionmark.circle.fill", title: "Help & Support", showArrow: true)
            }
            
            if purchaseManager.isSubscribed {
                Button {
                    Task {
                        try? await purchaseManager.restorePurchases()
                    }
                } label: {
                    SettingsRow(icon: "arrow.clockwise", title: "Restore Purchases", showArrow: false)
                }
            }
            
            Button {
                Task {
                    authViewModel.logout()
                    authViewModel.errorMessage = "unauthorized"
                }
            } label: {
                SettingsRow(
                    icon: "rectangle.portrait.and.arrow.right",
                    title: "Logout",
                    showArrow: false,
                    isDestructive: true
                )
            }
        }
    }
}

struct SettingsRow: View {
    let icon: String
    let title: String
    let showArrow: Bool
    var isDestructive: Bool = false
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(isDestructive ? .red : .white)
                .frame(width: 30)
            
            Text(title)
                .foregroundColor(isDestructive ? .red : .white)
            
            Spacer()
            
            if showArrow {
                Image(systemName: "chevron.right")
                    .foregroundColor(.gray)
                    .font(.system(size: 14))
            }
        }
        .padding()
    }
}

struct SettingsTabView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsTabView()
            .environmentObject(AuthViewModel())
    }
} 
