import SwiftUI
import StoreKit

struct PremiumUpgradeButton: View {
    @ObservedObject var purchaseManager: PurchaseManager
    @State private var showError = false
    @State private var errorMessage = ""
    
    var style: ButtonStyle = .primary
    
    enum ButtonStyle {
        case primary
        case secondary
        case compact
    }
    
    var body: some View {
        Group {
            if let product = purchaseManager.products.first {
                switch style {
                case .primary:
                    primaryButton(product: product)
                case .secondary:
                    secondaryButton(product: product)
                case .compact:
                    compactButton(product: product)
                }
            }
        }
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
    }
    
    private func primaryButton(product: Product) -> some View {
        Button {
            handlePurchase()
        } label: {
            HStack {
                Image(systemName: "star.fill")
                Text("Upgrade to Premium - \(product.displayPrice)/month")
            }
            .font(.headline)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color("highlight"))
            .cornerRadius(15)
        }
        .padding(.horizontal)
    }
    
    private func secondaryButton(product: Product) -> some View {
        Button {
            handlePurchase()
        } label: {
            HStack {
                Image(systemName: "star.fill")
                Text("Subscribe for \(product.displayPrice)")
            }
            .font(.subheadline)
            .foregroundColor(.white)
            .padding(.vertical, 8)
            .padding(.horizontal, 16)
            .background(Color("highlight"))
            .cornerRadius(10)
        }
    }
    
    private func compactButton(product: Product) -> some View {
        Button {
            handlePurchase()
        } label: {
            Label("Premium \(product.displayPrice)", systemImage: "star.fill")
                .font(.subheadline)
                .foregroundColor(.white)
        }
    }
    
    private func handlePurchase() {
        Task {
            do {
                try await purchaseManager.purchase()
            } catch {
                errorMessage = error.localizedDescription
                showError = true
            }
        }
    }
}

struct RestorePurchasesButton: View {
    @ObservedObject var purchaseManager: PurchaseManager
    @State private var showError = false
    @State private var errorMessage = ""
    
    var body: some View {
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
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
    }
} 