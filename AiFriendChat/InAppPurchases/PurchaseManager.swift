//
//  PurchaseManager.swift
//  AiFriendChat
//
//  Created by Carlos Alvarez on 1/22/25.
//

import StoreKit
import OSLog

@MainActor
class PurchaseManager: ObservableObject {
    static let shared = PurchaseManager()
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.app", category: "PurchaseManager")
    
    private let productId = "com.aifriendchat.monthly_subscription"
    private let trialCallsLimit = 1
    
    @Published private(set) var products: [Product] = []
    @Published private(set) var purchasedProducts: Set<String> = []
    @Published private(set) var isSubscribed = false
    
    private var updateListenerTask: Task<Void, Error>?
    
    private let callCountQueue = DispatchQueue(label: "com.aifriendchat.callcount")
    private let defaults = UserDefaults.standard
    
    init() {
        updateListenerTask = listenForTransactions()
        Task {
            await fetchProducts()
            await updateSubscriptionStatus()
        }
    }
    
    deinit {
        updateListenerTask?.cancel()
    }
    
    var callsMade: Int {
        callCountQueue.sync {
            defaults.integer(forKey: "callsMadeCount")
        }
    }
    
    func incrementCallCount() {
        callCountQueue.sync {
            let currentCount = defaults.integer(forKey: "callsMadeCount")
            defaults.set(currentCount + 1, forKey: "callsMadeCount")
            DispatchQueue.main.async {
                self.objectWillChange.send()
            }
        }
    }
    
    func decrementCallCount() {
        callCountQueue.sync {
            let currentCount = defaults.integer(forKey: "callsMadeCount")
            if currentCount > 0 {
                defaults.set(currentCount - 1, forKey: "callsMadeCount")
                DispatchQueue.main.async {
                    self.objectWillChange.send()
                }
            }
        }
    }
    
    func getRemainingTrialCalls() -> Int {
        return max(0, trialCallsLimit - callsMade)
    }
    
    func canMakeCall() async throws -> Bool {
        do {
            try await updateSubscriptionStatus()
            return isSubscribed || getRemainingTrialCalls() > 0
        } catch {
            logger.error("Failed to update subscription status: \(error.localizedDescription)")
            throw error
        }
    }
    
    func canScheduleCall() async -> Bool {
        await updateSubscriptionStatus()
        return isSubscribed
    }
    
    private func listenForTransactions() -> Task<Void, Error> {
        return Task.detached {
            for await result in Transaction.updates {
                do {
                    let transaction = try result.payloadValue
                    await self.handle(transaction: transaction)
                } catch {
                    self.logger.error("Transaction update error: \(error.localizedDescription)")
                }
            }
        }
    }
    
    @MainActor
    private func handle(transaction: Transaction) async {
        let productId = transaction.productID
        
        switch transaction.revocationDate {
        case .some(_):
            purchasedProducts.remove(productId)
            isSubscribed = false
        case .none:
            purchasedProducts.insert(productId)
            isSubscribed = true
        }
        
        await transaction.finish()
    }
    
    func fetchProducts() async {
        do {
            products = try await Product.products(for: [productId])
            logger.debug("Fetched \(self.products.count) products")
        } catch {
            logger.error("Failed to fetch products: \(error.localizedDescription)")
            products = []
        }
    }
    
    func purchase() async throws {
        guard let product = products.first else {
            throw StoreError.productNotFound
        }
        
        do {
            let result = try await product.purchase()
            
            switch result {
            case .success(let verification):
                let transaction = try verification.payloadValue
                await handle(transaction: transaction)
                
            case .userCancelled:
                throw StoreError.userCancelled
                
            case .pending:
                throw StoreError.pending
                
            @unknown default:
                throw StoreError.unknown
            }
        } catch {
            throw StoreError.purchaseFailed(error)
        }
    }
    
    func restorePurchases() async throws {
        try await AppStore.sync()
        await updateSubscriptionStatus()
    }
    
    @discardableResult
    func updateSubscriptionStatus() async -> Bool {
        var statusUpdated = false
        for await result in Transaction.currentEntitlements {
            do {
                let transaction = try result.payloadValue
                await handle(transaction: transaction)
                statusUpdated = true
            } catch {
                logger.error("Failed to update subscription status: \(error.localizedDescription)")
            }
        }
        return statusUpdated
    }
    
    #if DEBUG
    func toggleDebugPremium() {
        isSubscribed.toggle()
        objectWillChange.send()
    }
    #endif
}

enum StoreError: LocalizedError {
    case productNotFound
    case purchaseFailed(Error)
    case userCancelled
    case pending
    case unknown
    
    var errorDescription: String? {
        switch self {
        case .productNotFound:
            return "The product could not be found."
        case .purchaseFailed(let error):
            return "The purchase failed: \(error.localizedDescription)"
        case .userCancelled:
            return "The purchase was cancelled."
        case .pending:
            return "The purchase is pending."
        case .unknown:
            return "An unknown error occurred."
        }
    }
}
