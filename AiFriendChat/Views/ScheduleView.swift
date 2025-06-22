import SwiftUI
import SwiftData
import StoreKit

struct ScheduleView: View {
    @StateObject private var viewModel = ScheduleCallViewModel()
    @StateObject private var purchaseManager = PurchaseManager.shared
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var phoneNumber = ""
    @State private var selectedScenario = "default"
    @State private var showAuthPrompt = false
    @State private var showAuthView = false
    
    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient(
                    gradient: Gradient(colors: [Color("Color"), Color("Color 2")]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .edgesIgnoringSafeArea(.all)
                
                ScrollView(showsIndicators: true) {
                    VStack(spacing: 15) {
                        // Welcome Title
                        Text("Schedule a Call")
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .padding(.top, 10)
                        
                        // Trial/Subscription Status
                        if !purchaseManager.isSubscribed {
                            HStack {
                                Text("Premium Feature")
                                    .font(.subheadline)
                                    .foregroundColor(.white)
                                Spacer()
                                Button("Restore") {
                                    Task {
                                        try? await purchaseManager.restorePurchases()
                                    }
                                }
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.8))
                            }
                            .padding(.horizontal)
                            
                            PremiumUpgradeButton(purchaseManager: purchaseManager, style: .secondary)
                                .padding(.horizontal)
                                .padding(.bottom, 5)
                        }
                        
                        // Main Content
                        ScheduleCallView(phoneNumber: phoneNumber, scenario: selectedScenario)
                            .padding(.horizontal)
                    }
                }
            }
        }
        .sheet(isPresented: $showAuthPrompt) {
            AuthPromptView(showAuthView: $showAuthView)
        }
        .fullScreenCover(isPresented: $showAuthView) {
            AuthView()
        }
        .alert("Subscribe", isPresented: $viewModel.showSubscriptionAlert) {
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
        } message: {
            Text("Scheduling calls is a premium feature. Subscribe to unlock this feature.")
        }
        .alert("Error", isPresented: $viewModel.showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(viewModel.errorMessage ?? "An unknown error occurred")
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

struct ScheduleView_Previews: PreviewProvider {
    static var previews: some View {
        ScheduleView()
    }
} 
