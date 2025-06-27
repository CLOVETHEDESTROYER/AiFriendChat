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
    private let monthlyCallTimeLimit: TimeInterval = 20 * 60 // 20 minutes in seconds
    private let weeklyCallTimeLimit: TimeInterval = 20 * 60 // 20 minutes in seconds
    
    @Published private(set) var products: [Product] = []
    @Published private(set) var purchasedProducts: Set<String> = []
    @Published private(set) var isSubscribed = false
    @Published private(set) var subscriptionType: SubscriptionType = .none
    
    private var updateListenerTask: Task<Void, Error>?
    
    private let callTimeQueue = DispatchQueue(label: "com.aifriendchat.calltime")
    private let defaults = UserDefaults.standard
    
    enum SubscriptionType {
        case none
        case weekly
        case monthly
    }
    
    init() {
        updateListenerTask = listenForTransactions()
        Task {
            await fetchProducts()
            do {
                try await updateSubscriptionStatus()
            } catch {
                logger.error("Failed to update subscription status during init: \(error.localizedDescription)")
            }
        }
    }
    
    deinit {
        updateListenerTask?.cancel()
    }
    
    // MARK: - Trial Call Tracking
    var callsMade: Int {
        callTimeQueue.sync {
            defaults.integer(forKey: "callsMadeCount")
        }
    }
    
    func incrementCallCount() {
        callTimeQueue.sync {
            let currentCount = defaults.integer(forKey: "callsMadeCount")
            defaults.set(currentCount + 1, forKey: "callsMadeCount")
            DispatchQueue.main.async {
                self.objectWillChange.send()
            }
        }
    }
    
    func decrementCallCount() {
        callTimeQueue.sync {
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
    
    // MARK: - Call Time Tracking
    var totalCallTimeThisPeriod: TimeInterval {
        callTimeQueue.sync {
            let key = getCurrentPeriodKey()
            return defaults.double(forKey: key)
        }
    }
    
    var remainingCallTime: TimeInterval {
        if !isSubscribed {
            return 0
        }
        
        let limit = subscriptionType == .weekly ? weeklyCallTimeLimit : monthlyCallTimeLimit
        return max(0, limit - totalCallTimeThisPeriod)
    }
    
    func addCallTime(_ duration: TimeInterval) {
        callTimeQueue.sync {
            let key = getCurrentPeriodKey()
            let currentTime = defaults.double(forKey: key)
            defaults.set(currentTime + duration, forKey: key)
            DispatchQueue.main.async {
                self.objectWillChange.send()
            }
        }
    }
    
    private func getCurrentPeriodKey() -> String {
        let calendar = Calendar.current
        let now = Date()
        
        if subscriptionType == .weekly {
            let weekOfYear = calendar.component(.weekOfYear, from: now)
            let year = calendar.component(.year, from: now)
            return "callTime_week_\(year)_\(weekOfYear)"
        } else {
            let month = calendar.component(.month, from: now)
            let year = calendar.component(.year, from: now)
            return "callTime_month_\(year)_\(month)"
        }
    }
    
    // MARK: - Call Permission Checks
    func canMakeCall() async throws -> Bool {
        try await updateSubscriptionStatus()
        
        if isSubscribed {
            return remainingCallTime > 0
        } else {
            return getRemainingTrialCalls() > 0
        }
    }
    
    func canScheduleCall() async throws -> Bool {
        try await updateSubscriptionStatus()
        return isSubscribed
    }
    
    // MARK: - Display Methods
    func getRemainingTimeDisplay() -> String {
        if !isSubscribed {
            return "\(getRemainingTrialCalls()) trial calls"
        }
        
        let minutes = Int(remainingCallTime / 60)
        let seconds = Int(remainingCallTime.truncatingRemainder(dividingBy: 60))
        
        if minutes > 0 {
            return "\(minutes)m \(seconds)s remaining"
        } else {
            return "\(seconds)s remaining"
        }
    }
    
    func getTotalTimeUsedDisplay() -> String {
        let minutes = Int(totalCallTimeThisPeriod / 60)
        let seconds = Int(totalCallTimeThisPeriod.truncatingRemainder(dividingBy: 60))
        
        if minutes > 0 {
            return "\(minutes)m \(seconds)s used"
        } else {
            return "\(seconds)s used"
        }
    }
    
    // MARK: - Subscription Management
    private func updateSubscriptionStatus() async throws {
        for await result in Transaction.currentEntitlements {
            let transaction = try result.payloadValue
            await handle(transaction: transaction)
        }
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
            subscriptionType = .none
        case .none:
            purchasedProducts.insert(productId)
            isSubscribed = true
            // Determine subscription type based on product ID
            if productId.contains("weekly") {
                subscriptionType = .weekly
            } else {
                subscriptionType = .monthly
            }
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
        try await updateSubscriptionStatus()
    }
    
    #if DEBUG
    func toggleDebugPremium() {
        isSubscribed.toggle()
        if isSubscribed {
            subscriptionType = .monthly
        } else {
            subscriptionType = .none
        }
        objectWillChange.send()
    }
    
    func addTestCallTime(_ minutes: Double) {
        addCallTime(minutes * 60)
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
