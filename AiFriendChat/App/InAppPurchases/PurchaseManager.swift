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
    private let trialCallsLimit = 3
    
    @Published private(set) var products: [Product] = []
    @Published private(set) var purchasedProducts: Set<String> = []
    @Published private(set) var isSubscribed = false
    
    private var updateListenerTask: Task<Void, Error>?
    
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
        UserDefaults.standard.integer(forKey: "callsMadeCount")
    }
    
    func incrementCallCount() {
        let currentCount = callsMade
        UserDefaults.standard.set(currentCount + 1, forKey: "callsMadeCount")
        objectWillChange.send()
    }
    
    func getRemainingTrialCalls() -> Int {
        return max(0, trialCallsLimit - callsMade)
    }
    
    func canMakeCall() async -> Bool {
        await updateSubscriptionStatus()
        return isSubscribed || getRemainingTrialCalls() > 0
    }
    
    func canScheduleCall() async -> Bool {
        await updateSubscriptionStatus()
        return isSubscribed
    }
    
    private func listenForTransactions() -> Task<Void, Error> {
        return Task.detached {
            for await result in Transaction.updates {
                do {
                    let transaction = try await result.payloadValue
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
                let transaction = try await verification.payloadValue
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
    
    func updateSubscriptionStatus() async {
        for await result in Transaction.currentEntitlements {
            do {
                let transaction = try await result.payloadValue
                await handle(transaction: transaction)
            } catch {
                logger.error("Failed to update subscription status: \(error.localizedDescription)")
            }
        }
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
