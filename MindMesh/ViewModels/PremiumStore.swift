import Foundation
import StoreKit

@MainActor
final class PremiumStore: ObservableObject {
    @Published private(set) var hasPremiumAccess: Bool
    @Published private(set) var premiumProduct: Product?
    @Published private(set) var isLoadingProducts = false
    @Published private(set) var isPurchasing = false
    @Published private(set) var isRestoring = false
    @Published var purchaseNotice: String?
    @Published var purchaseError: String?

    private let productIDs: [String]
    private let storeKitEnabled: Bool
    private let cacheKey = "mindmesh.premium.cachedAccess"
    private let legacyAccessKey = "peace.premiumUnlocked"
    private var transactionUpdatesTask: Task<Void, Never>?

    init(
        productIDs: [String] = ["com.claudianapolitano.mindmesh.premium.monthly"],
        storeKitEnabled: Bool = true,
        initialPremiumAccess: Bool? = nil
    ) {
        self.productIDs = productIDs
        self.storeKitEnabled = storeKitEnabled

        if let initialPremiumAccess {
            self.hasPremiumAccess = initialPremiumAccess
        } else {
            let defaults = UserDefaults.standard
            self.hasPremiumAccess = defaults.bool(forKey: cacheKey) || defaults.bool(forKey: legacyAccessKey)
        }

        guard storeKitEnabled else { return }

        transactionUpdatesTask = Task { [weak self] in
            guard let self else { return }
            await self.observeTransactionUpdates()
        }

        Task { [weak self] in
            guard let self else { return }
            await self.prepare()
        }
    }

    deinit {
        transactionUpdatesTask?.cancel()
    }

    var purchaseButtonTitle: String {
        let t = AppStrings.current
        if hasPremiumAccess {
            return t.purchasePremiumActive
        }

        if let premiumProduct {
            return t.purchasePremiumMonthly(price: premiumProduct.displayPrice)
        }

        return t.purchaseActivatePremium
    }

    var purchaseButtonIcon: String {
        hasPremiumAccess ? "checkmark.circle.fill" : "sparkles"
    }

    var storeStatusText: String {
        let t = AppStrings.current
        let configuredProducts = productIDs.joined(separator: ", ")

        if hasPremiumAccess {
            return t.premiumActiveAccount
        }

        if premiumProduct != nil {
            return t.purchaseUsesStoreKit
        }

        if isLoadingProducts {
            return t.purchaseLoadingProducts
        }

        return t.shopNotReady(productIDs: configuredProducts)
    }

    func prepare() async {
        await refreshProducts()
        await refreshEntitlements()
    }

    func refreshProducts() async {
        guard storeKitEnabled else { return }

        isLoadingProducts = true
        defer { isLoadingProducts = false }
        let configuredProducts = productIDs.joined(separator: ", ")

        do {
            let products = try await Product.products(for: productIDs)
            premiumProduct = products.sorted { $0.price < $1.price }.first
            if premiumProduct == nil {
                purchaseError = AppStrings.current.noPremiumProductFound(productIDs: configuredProducts)
            }
        } catch {
            purchaseError = AppStrings.current.cannotLoadShop
        }
    }

    func purchasePremium() async {
        guard storeKitEnabled else { return }
        guard !isPurchasing else { return }

        purchaseError = nil
        purchaseNotice = nil

        if premiumProduct == nil {
            await refreshProducts()
        }

        guard let premiumProduct else {
            purchaseError = AppStrings.current.premiumProductUnavailable
            return
        }

        isPurchasing = true
        defer { isPurchasing = false }

        do {
            let result = try await premiumProduct.purchase()

            switch result {
            case .success(let verification):
                let transaction = try checkVerified(verification)
                await refreshEntitlements()
                await transaction.finish()
                purchaseNotice = AppStrings.current.premiumActivated

            case .userCancelled:
                purchaseNotice = nil

            case .pending:
                purchaseNotice = AppStrings.current.purchasePending

            @unknown default:
                purchaseError = AppStrings.current.purchaseUnknownState
            }
        } catch {
            purchaseError = AppStrings.current.purchaseFailed
        }
    }

    func restorePurchases() async {
        guard storeKitEnabled else { return }
        guard !isRestoring else { return }

        isRestoring = true
        defer { isRestoring = false }

        purchaseError = nil
        purchaseNotice = nil

        do {
            try await AppStore.sync()
            await refreshEntitlements()
            purchaseNotice = hasPremiumAccess
                ? AppStrings.current.purchasesRestored
                : AppStrings.current.noPremiumPurchaseFound
        } catch {
            purchaseError = AppStrings.current.restoreFailed
        }
    }

    private func refreshEntitlements() async {
        guard storeKitEnabled else { return }

        var premiumActive = false

        for await result in Transaction.currentEntitlements {
            guard let transaction = try? checkVerified(result) else { continue }
            guard productIDs.contains(transaction.productID) else { continue }
            guard transaction.revocationDate == nil else { continue }
            guard transaction.expirationDate.map({ $0 > .now }) ?? true else { continue }
            premiumActive = true
            break
        }

        applyPremiumAccess(premiumActive)
    }

    private func applyPremiumAccess(_ isActive: Bool) {
        hasPremiumAccess = isActive
        let defaults = UserDefaults.standard
        defaults.set(isActive, forKey: cacheKey)
        defaults.set(isActive, forKey: legacyAccessKey)
    }

    private func observeTransactionUpdates() async {
        for await result in Transaction.updates {
            guard !Task.isCancelled else { return }

            do {
                let transaction = try checkVerified(result)
                await refreshEntitlements()
                await transaction.finish()
            } catch {
                purchaseError = AppStrings.current.purchaseUpdateUnverified
            }
        }
    }

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw PremiumStoreError.verificationFailed
        case .verified(let value):
            return value
        }
    }
}

enum PremiumStoreError: Error {
    case verificationFailed
}
