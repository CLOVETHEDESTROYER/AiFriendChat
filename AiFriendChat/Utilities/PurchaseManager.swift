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
    
    private let maxTrialCalls = 2
    private let userDefaults = UserDefaults.standard
    private let callCountKey = "callsMadeCount"
    private let monthlySubscriptionId = "com.aifriendchat.monthly_subscription"

    override init() {
        super.init()
        callsMade = userDefaults.integer(forKey: callCountKey)
        SKPaymentQueue.default().add(self)
        fetchProducts()
    }

    func fetchProducts() {
        let productIDs: Set<String> = [monthlySubscriptionId]
        let request = SKProductsRequest(productIdentifiers: productIDs)
        request.delegate = self
        request.start()
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
            self.products = response.products
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
