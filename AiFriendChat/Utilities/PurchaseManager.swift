//
//  PurchaseManager.swift
//  AiFriendChat
//
//  Created by Carlos Alvarez on 1/23/25.
//

import StoreKit

class PurchaseManager: NSObject, ObservableObject {
    static let shared = PurchaseManager()
    @Published var products: [SKProduct] = []
    @Published var purchasedProducts: Set<String> = []
    @Published var callsMade: Int = 0
    @Published var isLoadingProducts = false
    @Published var loadingError: String? = nil
    
    private let maxTrialCalls = 2
    private let userDefaults = UserDefaults.standard
    private let callCountKey = "callsMadeCount"
    private let monthlySubscriptionId = "com.aifriendchat.monthly_subscription"
    private var productRequest: SKProductsRequest?

    override init() {
        super.init()
        callsMade = userDefaults.integer(forKey: callCountKey)
        SKPaymentQueue.default().add(self)
        loadProducts()
    }

    func loadProducts() {
        // Reset state
        isLoadingProducts = true
        loadingError = nil
        products = []
        
        let productIDs: Set<String> = [monthlySubscriptionId]
        productRequest?.cancel() // Cancel any existing request
        
        let request = SKProductsRequest(productIdentifiers: productIDs)
        productRequest = request
        request.delegate = self
        request.start()
        
        // Add timeout
        DispatchQueue.main.asyncAfter(deadline: .now() + 30) { [weak self] in
            guard let self = self else { return }
            if self.isLoadingProducts {
                self.isLoadingProducts = false
                self.loadingError = "Request timed out. Please try again."
                self.productRequest?.cancel()
            }
        }
    }

    func incrementCallCount() {
        callsMade += 1
        userDefaults.set(callsMade, forKey: callCountKey)
    }

    func canMakeCall() -> Bool {
        return isSubscribed || callsMade < maxTrialCalls
    }

    func canScheduleCall() -> Bool {
        return isSubscribed
    }

    func getRemainingTrialCalls() -> Int {
        return max(0, maxTrialCalls - callsMade)
    }

    func purchase(product: SKProduct) {
        let payment = SKPayment(product: product)
        SKPaymentQueue.default().add(payment)
    }

    func restorePurchases() {
        SKPaymentQueue.default().restoreCompletedTransactions()
    }

    var isSubscribed: Bool {
        #if DEBUG
        // Check for debug override
        if UserDefaults.standard.bool(forKey: "debugPremiumEnabled") {
            return true
        }
        #endif
        // Regular subscription check
        return UserDefaults.standard.bool(forKey: "hasActiveSubscription")
    }
    
    // Add debug helper
    #if DEBUG
    func toggleDebugPremium() {
        UserDefaults.standard.set(!isSubscribed, forKey: "debugPremiumEnabled")
        objectWillChange.send()
    }
    #endif
}

extension PurchaseManager: SKProductsRequestDelegate, SKPaymentTransactionObserver {
    func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
        DispatchQueue.main.async {
            self.isLoadingProducts = false
            self.products = response.products
            
            if response.products.isEmpty {
                self.loadingError = "No products available"
            }
        }
    }
    
    func request(_ request: SKRequest, didFailWithError error: Error) {
        DispatchQueue.main.async {
            self.isLoadingProducts = false
            self.loadingError = error.localizedDescription
        }
    }

    func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        for transaction in transactions {
            switch transaction.transactionState {
            case .purchased, .restored:
                if transaction.payment.productIdentifier == monthlySubscriptionId {
                    DispatchQueue.main.async {
                        UserDefaults.standard.set(true, forKey: "hasActiveSubscription")
                        self.objectWillChange.send()
                    }
                }
                self.purchasedProducts.insert(transaction.payment.productIdentifier)
                SKPaymentQueue.default().finishTransaction(transaction)
            case .failed:
                if let error = transaction.error {
                    print("Transaction Failed: \(error.localizedDescription)")
                }
                SKPaymentQueue.default().finishTransaction(transaction)
            case .deferred:
                print("Transaction deferred")
            case .purchasing:
                print("Transaction in progress")
            @unknown default:
                break
            }
        }
    }
}
