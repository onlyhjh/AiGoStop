//
//  PurchaseManager.swift
//  AiGoStop
//
//  Created by Joey's Mac mini on 8/5/26.
//

import StoreKit
import Combine

@MainActor
final class PurchaseManager: ObservableObject {

    static let shared = PurchaseManager()

    @Published private(set) var isAdRemoved = false
    @Published private(set) var removeAdsProduct: Product?

    private let productID = "com.aigostop.removeads"

    private init() {
        Task {
            await loadProducts()
            await updatePurchasedProducts()
            observeTransactions()
        }
    }

    func loadProducts() async {
        do {
            let products = try await Product.products(for: ["com.aigostop.removeads"])
            removeAdsProduct = products.first
        } catch {
            print(error)
        }
    }

    func purchaseRemoveAds() async {

        guard let product = removeAdsProduct else {
            return
        }

        do {

            let result = try await product.purchase()

            switch result {

            case .success(let verification):

                let transaction = try checkVerified(verification)

                isAdRemoved = true

                await transaction.finish()

            case .userCancelled:
                break

            case .pending:
                break

            default:
                break
            }

        } catch {
            print(error)
        }
    }

    func restorePurchases() async {

        for await result in Transaction.currentEntitlements {

            if case .verified(let transaction) = result {

                if transaction.productID == productID {
                    isAdRemoved = true
                }
            }
        }
    }

    func updatePurchasedProducts() async {

        for await result in Transaction.currentEntitlements {

            if case .verified(let transaction) = result {

                if transaction.productID == productID {
                    isAdRemoved = true
                }
            }
        }
    }

    private func observeTransactions() {

        Task {

            for await result in Transaction.updates {

                if case .verified(let transaction) = result {

                    if transaction.productID == productID {
                        isAdRemoved = true
                    }

                    await transaction.finish()
                }
            }
        }
    }

    private func checkVerified<T>(
        _ result: VerificationResult<T>
    ) throws -> T {

        switch result {

        case .verified(let safe):
            return safe

        case .unverified:
            throw StoreError.failedVerification
        }
    }

    enum StoreError: Error {
        case failedVerification
    }
}
