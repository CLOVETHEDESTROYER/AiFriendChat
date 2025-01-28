//
//  PurchaseManager.swift
//  AiFriendChat
//
//  Created by Carlos Alvarez on 1/22/25.
//

import StoreKit

class PurchaseManager: NSObject, ObservableObject {
    static let shared = PurchaseManager()
    @Published var products: [SKProduct] = []
    @Published var purchasedProducts: Set<String> = []

    override init() {
        super.init()
        SKPaymentQueue.default().add(self)
        fetchProducts()
    }

    func fetchProducts() {
        let productIDs: Set<String> = ["com.yourapp.premium_voice", "com.yourapp.custom_scenarios"]
        let request = SKProductsRequest(productIdentifiers: productIDs)
        request.delegate = self
        request.start()
    }

    func purchase(product: SKProduct) {
        let payment = SKPayment(product: product)
        SKPaymentQueue.default().add(payment)
    }
}
