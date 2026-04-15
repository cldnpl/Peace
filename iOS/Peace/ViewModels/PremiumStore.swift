import Foundation
import OSLog
import StoreKit

@MainActor
final class PremiumStore: ObservableObject {
    @Published private(set) var hasPremiumAccess: Bool
    @Published private(set) var premiumProduct: Product?
    @Published private(set) var isLoadingProducts = false
    @Published private(set) var isPurchasing = false
    @Published private(set) var isRestoring = false
    @Published private(set) var lastProductRefreshAt: Date?
    @Published private(set) var fetchedProductIDs: [String] = []
    @Published private(set) var invalidProductIDs: [String] = []
    @Published var purchaseNotice: String?
    @Published var purchaseError: String?

    private let productIDs: [String]
    private let storeKitEnabled: Bool
    private let logger: Logger
    private let cacheKey = "mindmesh.premium.cachedAccess"
    private let legacyAccessKey = "peace.premiumUnlocked"
    private let debugUnlockKey = "mindmesh.premium.debug.localUnlock"
    private var transactionUpdatesTask: Task<Void, Never>?
    private typealias RegionalPrice = (currencyCode: String, amount: String)

    init(
        productIDs: [String] = ["com.claudia.peace.monthly"],
        storeKitEnabled: Bool = true,
        initialPremiumAccess: Bool? = nil
    ) {
        let debugLocalUnlockEnabled = Self.debugLocalUnlockEnabled()

        self.productIDs = productIDs
        self.storeKitEnabled = storeKitEnabled
        self.logger = Logger(
            subsystem: Bundle.main.bundleIdentifier ?? "com.claudianapolitano.mindmesh",
            category: "PremiumStore"
        )

        if let initialPremiumAccess {
            self.hasPremiumAccess = initialPremiumAccess
        } else {
            let defaults = UserDefaults.standard
            if !debugLocalUnlockEnabled {
                defaults.removeObject(forKey: debugUnlockKey)
            }
            let cachedPremiumAccess =
                defaults.bool(forKey: cacheKey) ||
                defaults.bool(forKey: legacyAccessKey) ||
                (debugLocalUnlockEnabled && defaults.bool(forKey: debugUnlockKey))
            self.hasPremiumAccess = cachedPremiumAccess
        }

        logStoreConfiguration()

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
        return t.purchasePremiumMonthly(price: displayedMonthlyPrice)
    }

    var purchaseButtonIcon: String {
        "sparkles"
    }

    var storeStatusText: String {
        let t = AppStrings.current
        let configuredProducts = productIDs.joined(separator: ", ")

        if hasPremiumAccess {
            return t.premiumActiveAccount
        }

        if isLoadingProducts {
            return t.purchaseLoadingProducts
        }

        if premiumProduct != nil {
            return t.purchaseUsesStoreKit
        }

        if canUseDebugLocalUnlock {
            return t.debugPremiumStatus
        }

        return t.shopNotReady(productIDs: configuredProducts)
    }

    var premiumProductName: String? {
        premiumProduct?.displayName
    }

    var premiumProductPrice: String? {
        premiumProduct?.displayPrice
    }

    var displayedMonthlyPrice: String {
        if let premiumProduct {
            return premiumProduct.displayPrice
        }

        return localizedFallbackMonthlyPrice
    }

    func prepare(force: Bool = false) async {
        if !force, (isLoadingProducts || isPurchasing || isRestoring) {
            return
        }

        await refreshProducts(reportFailureToUser: false)
        await refreshEntitlements()
    }

    func refreshProducts(reportFailureToUser: Bool = false) async {
        guard storeKitEnabled else { return }
        guard !isLoadingProducts else { return }

        isLoadingProducts = true
        defer { isLoadingProducts = false }

        if reportFailureToUser {
            purchaseError = nil
        }

        let configuredProducts = productIDs.joined(separator: ", ")

        do {
            logger.info("Refreshing StoreKit products. env=\(self.storeEnvironmentDescription, privacy: .public) bundleID=\(self.bundleIdentifier, privacy: .public) productIDs=\(configuredProducts, privacy: .public)")

            var diagnostics = try await fetchProductsWithDiagnostics()
            if shouldRetryEmptyProductFetch(diagnostics: diagnostics) {
                logger.warning("StoreKit returned no products on first attempt. Retrying once after short delay.")
                try? await Task.sleep(nanoseconds: 750_000_000)
                diagnostics = try await fetchProductsWithDiagnostics()
            }

            fetchedProductIDs = diagnostics.fetchedProductIDs
            invalidProductIDs = diagnostics.invalidProductIDs
            premiumProduct = preferredProduct(from: diagnostics.fetchedProducts)
            lastProductRefreshAt = .now

            logProductDiagnostics(diagnostics)
        } catch {
            premiumProduct = nil
            fetchedProductIDs = []
            invalidProductIDs = []
            lastProductRefreshAt = .now
            logger.error("Failed to refresh StoreKit products: \(error.localizedDescription, privacy: .public)")

            if reportFailureToUser {
                purchaseError = AppStrings.current.cannotLoadShop
            }
        }
    }

    func purchasePremium() async {
        guard storeKitEnabled else { return }
        guard !isPurchasing else { return }

        purchaseError = nil
        purchaseNotice = nil

        if premiumProduct == nil {
            await refreshProducts(reportFailureToUser: false)
        }

        guard let premiumProduct else {
            logger.error("Purchase requested without available product. fetchedIDs=\(self.fetchedProductIDs.joined(separator: ","), privacy: .public) invalidIDs=\(self.invalidProductIDs.joined(separator: ","), privacy: .public)")
            purchaseError = unavailablePurchaseMessage(configuredProducts: productIDs.joined(separator: ", "))
            return
        }

        isPurchasing = true
        defer { isPurchasing = false }

        do {
            logger.info("Starting purchase for productID=\(premiumProduct.id, privacy: .public) env=\(self.storeEnvironmentDescription, privacy: .public)")
            let result = try await premiumProduct.purchase()

            switch result {
            case .success(let verification):
                let transaction = try checkVerified(verification)
                logger.info("Purchase verified. productID=\(transaction.productID, privacy: .public) transactionID=\(String(transaction.id), privacy: .public)")
                await refreshEntitlements()
                await transaction.finish()
                purchaseNotice = AppStrings.current.premiumActivated

            case .userCancelled:
                logger.info("Purchase cancelled by user for productID=\(premiumProduct.id, privacy: .public)")
                purchaseNotice = nil

            case .pending:
                logger.warning("Purchase pending approval for productID=\(premiumProduct.id, privacy: .public)")
                purchaseNotice = AppStrings.current.purchasePending

            @unknown default:
                logger.error("Purchase returned unknown state for productID=\(premiumProduct.id, privacy: .public)")
                purchaseError = AppStrings.current.purchaseUnknownState
            }
        } catch {
            logger.error("Purchase failed for productID=\(premiumProduct.id, privacy: .public): \(error.localizedDescription, privacy: .public)")
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
            logger.info("Starting restore purchases. env=\(self.storeEnvironmentDescription, privacy: .public)")
            await refreshProducts(reportFailureToUser: false)
            try await AppStore.sync()
            await refreshEntitlements()
            logger.info("Restore finished. activePremium=\(self.hasPremiumAccess, privacy: .public)")
            purchaseNotice = hasPremiumAccess
                ? AppStrings.current.purchasesRestored
                : AppStrings.current.noPremiumPurchaseFound
        } catch {
            logger.error("Restore purchases failed: \(error.localizedDescription, privacy: .public)")
            purchaseError = AppStrings.current.restoreFailed
        }
    }

    private func refreshEntitlements() async {
        guard storeKitEnabled else { return }

        let activeProductIDs = await currentActiveEntitlementProductIDs()
        let premiumActive = activeProductIDs.contains { productIDs.contains($0) }

        logger.info("Refreshed entitlements. activeIDs=\(activeProductIDs.joined(separator: ","), privacy: .public) premiumActive=\(premiumActive, privacy: .public)")
        applyPremiumAccess(premiumActive)
    }

    private func applyPremiumAccess(_ isActive: Bool, debugLocalUnlock: Bool = false) {
        hasPremiumAccess = isActive
        let defaults = UserDefaults.standard
        defaults.set(isActive, forKey: cacheKey)
        defaults.set(isActive, forKey: legacyAccessKey)
        defaults.set(debugLocalUnlock && isActive, forKey: debugUnlockKey)
    }

    private var canUseDebugLocalUnlock: Bool {
        Self.debugLocalUnlockEnabled()
    }

    private static func debugLocalUnlockEnabled() -> Bool {
        #if DEBUG
        return ProcessInfo.processInfo.environment["MINDMESH_ENABLE_PREMIUM_DEBUG_UNLOCK"] == "1"
        #else
        return false
        #endif
    }

    private var localizedFallbackMonthlyPrice: String {
        let locale = Locale.autoupdatingCurrent
        let regionCode = locale.region?.identifier ?? "US"
        let regionalPrice = fallbackRegionalPrices[regionCode] ?? fallbackRegionalPrices["US"] ?? (currencyCode: "USD", amount: "4.99")
        let localizedAmount = NSDecimalNumber(string: regionalPrice.amount)

        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = locale
        formatter.currencyCode = regionalPrice.currencyCode

        if let formattedPrice = formatter.string(from: localizedAmount) {
            return formattedPrice
        }

        return "$4.99"
    }

    private var fallbackRegionalPrices: [String: RegionalPrice] {
        [
            "AE": (currencyCode: "AED", amount: "19.99"),
            "AF": (currencyCode: "USD", amount: "4.99"),
            "AG": (currencyCode: "USD", amount: "4.99"),
            "AI": (currencyCode: "USD", amount: "4.99"),
            "AL": (currencyCode: "USD", amount: "5.99"),
            "AM": (currencyCode: "USD", amount: "5.99"),
            "AO": (currencyCode: "USD", amount: "4.99"),
            "AR": (currencyCode: "USD", amount: "4.99"),
            "AT": (currencyCode: "EUR", amount: "5.99"),
            "AU": (currencyCode: "AUD", amount: "7.99"),
            "AZ": (currencyCode: "USD", amount: "5.99"),
            "BA": (currencyCode: "EUR", amount: "5.99"),
            "BB": (currencyCode: "USD", amount: "5.99"),
            "BE": (currencyCode: "EUR", amount: "5.99"),
            "BF": (currencyCode: "USD", amount: "4.99"),
            "BG": (currencyCode: "EUR", amount: "5.99"),
            "BH": (currencyCode: "USD", amount: "4.99"),
            "BJ": (currencyCode: "USD", amount: "5.99"),
            "BM": (currencyCode: "USD", amount: "4.99"),
            "BN": (currencyCode: "USD", amount: "4.99"),
            "BO": (currencyCode: "USD", amount: "4.99"),
            "BR": (currencyCode: "BRL", amount: "29.9"),
            "BS": (currencyCode: "USD", amount: "4.99"),
            "BT": (currencyCode: "USD", amount: "4.99"),
            "BW": (currencyCode: "USD", amount: "4.99"),
            "BY": (currencyCode: "USD", amount: "5.99"),
            "BZ": (currencyCode: "USD", amount: "4.99"),
            "CA": (currencyCode: "CAD", amount: "6.99"),
            "CD": (currencyCode: "USD", amount: "4.99"),
            "CG": (currencyCode: "USD", amount: "4.99"),
            "CH": (currencyCode: "CHF", amount: "4.0"),
            "CI": (currencyCode: "USD", amount: "5.99"),
            "CL": (currencyCode: "CLP", amount: "5990"),
            "CM": (currencyCode: "USD", amount: "5.99"),
            "CN": (currencyCode: "CNY", amount: "38.0"),
            "CO": (currencyCode: "COP", amount: "24900.0"),
            "CR": (currencyCode: "USD", amount: "4.99"),
            "CV": (currencyCode: "USD", amount: "4.99"),
            "CY": (currencyCode: "EUR", amount: "5.99"),
            "CZ": (currencyCode: "CZK", amount: "129.0"),
            "DE": (currencyCode: "EUR", amount: "5.99"),
            "DK": (currencyCode: "DKK", amount: "39.0"),
            "DM": (currencyCode: "USD", amount: "4.99"),
            "DO": (currencyCode: "USD", amount: "4.99"),
            "DZ": (currencyCode: "USD", amount: "4.99"),
            "EC": (currencyCode: "USD", amount: "4.99"),
            "EE": (currencyCode: "EUR", amount: "5.99"),
            "EG": (currencyCode: "EGP", amount: "249.99"),
            "ES": (currencyCode: "EUR", amount: "5.99"),
            "FI": (currencyCode: "EUR", amount: "5.99"),
            "FJ": (currencyCode: "USD", amount: "4.99"),
            "FM": (currencyCode: "USD", amount: "4.99"),
            "FR": (currencyCode: "EUR", amount: "5.99"),
            "GA": (currencyCode: "USD", amount: "4.99"),
            "GB": (currencyCode: "GBP", amount: "4.99"),
            "GD": (currencyCode: "USD", amount: "4.99"),
            "GE": (currencyCode: "USD", amount: "5.99"),
            "GH": (currencyCode: "USD", amount: "5.99"),
            "GM": (currencyCode: "USD", amount: "4.99"),
            "GR": (currencyCode: "EUR", amount: "5.99"),
            "GT": (currencyCode: "USD", amount: "4.99"),
            "GW": (currencyCode: "USD", amount: "4.99"),
            "GY": (currencyCode: "USD", amount: "4.99"),
            "HK": (currencyCode: "HKD", amount: "38.0"),
            "HN": (currencyCode: "USD", amount: "4.99"),
            "HR": (currencyCode: "EUR", amount: "5.99"),
            "HU": (currencyCode: "HUF", amount: "1990"),
            "ID": (currencyCode: "IDR", amount: "89000"),
            "IE": (currencyCode: "EUR", amount: "5.99"),
            "IL": (currencyCode: "ILS", amount: "17.9"),
            "IN": (currencyCode: "INR", amount: "499.0"),
            "IQ": (currencyCode: "USD", amount: "4.99"),
            "IS": (currencyCode: "USD", amount: "5.99"),
            "IT": (currencyCode: "EUR", amount: "5.99"),
            "JM": (currencyCode: "USD", amount: "4.99"),
            "JO": (currencyCode: "USD", amount: "4.99"),
            "JP": (currencyCode: "JPY", amount: "800"),
            "KE": (currencyCode: "USD", amount: "5.99"),
            "KG": (currencyCode: "USD", amount: "4.99"),
            "KH": (currencyCode: "USD", amount: "4.99"),
            "KN": (currencyCode: "USD", amount: "4.99"),
            "KR": (currencyCode: "KRW", amount: "6600"),
            "KW": (currencyCode: "USD", amount: "4.99"),
            "KY": (currencyCode: "USD", amount: "4.99"),
            "KZ": (currencyCode: "KZT", amount: "2990.0"),
            "LA": (currencyCode: "USD", amount: "4.99"),
            "LB": (currencyCode: "USD", amount: "4.99"),
            "LC": (currencyCode: "USD", amount: "4.99"),
            "LK": (currencyCode: "USD", amount: "4.99"),
            "LR": (currencyCode: "USD", amount: "4.99"),
            "LT": (currencyCode: "EUR", amount: "5.99"),
            "LU": (currencyCode: "EUR", amount: "5.99"),
            "LV": (currencyCode: "EUR", amount: "5.99"),
            "LY": (currencyCode: "USD", amount: "4.99"),
            "MA": (currencyCode: "USD", amount: "4.99"),
            "MD": (currencyCode: "USD", amount: "5.99"),
            "ME": (currencyCode: "EUR", amount: "4.99"),
            "MG": (currencyCode: "USD", amount: "4.99"),
            "MK": (currencyCode: "USD", amount: "4.99"),
            "ML": (currencyCode: "USD", amount: "4.99"),
            "MM": (currencyCode: "USD", amount: "4.99"),
            "MN": (currencyCode: "USD", amount: "4.99"),
            "MO": (currencyCode: "USD", amount: "4.99"),
            "MR": (currencyCode: "USD", amount: "4.99"),
            "MS": (currencyCode: "USD", amount: "4.99"),
            "MT": (currencyCode: "EUR", amount: "5.99"),
            "MU": (currencyCode: "USD", amount: "5.99"),
            "MV": (currencyCode: "USD", amount: "4.99"),
            "MW": (currencyCode: "USD", amount: "4.99"),
            "MX": (currencyCode: "MXN", amount: "99.0"),
            "MY": (currencyCode: "MYR", amount: "22.9"),
            "MZ": (currencyCode: "USD", amount: "4.99"),
            "NA": (currencyCode: "USD", amount: "4.99"),
            "NE": (currencyCode: "USD", amount: "4.99"),
            "NG": (currencyCode: "NGN", amount: "7900.0"),
            "NI": (currencyCode: "USD", amount: "4.99"),
            "NL": (currencyCode: "EUR", amount: "5.99"),
            "NO": (currencyCode: "NOK", amount: "59.0"),
            "NP": (currencyCode: "USD", amount: "5.99"),
            "NR": (currencyCode: "USD", amount: "4.99"),
            "NZ": (currencyCode: "NZD", amount: "9.99"),
            "OM": (currencyCode: "USD", amount: "4.99"),
            "PA": (currencyCode: "USD", amount: "4.99"),
            "PE": (currencyCode: "PEN", amount: "22.9"),
            "PG": (currencyCode: "USD", amount: "4.99"),
            "PH": (currencyCode: "PHP", amount: "299.0"),
            "PK": (currencyCode: "PKR", amount: "1300.0"),
            "PL": (currencyCode: "PLN", amount: "24.99"),
            "PT": (currencyCode: "EUR", amount: "5.99"),
            "PW": (currencyCode: "USD", amount: "4.99"),
            "PY": (currencyCode: "USD", amount: "4.99"),
            "QA": (currencyCode: "QAR", amount: "19.99"),
            "RO": (currencyCode: "RON", amount: "29.99"),
            "RS": (currencyCode: "EUR", amount: "5.99"),
            "RU": (currencyCode: "RUB", amount: "449.0"),
            "RW": (currencyCode: "USD", amount: "4.99"),
            "SA": (currencyCode: "SAR", amount: "19.99"),
            "SB": (currencyCode: "USD", amount: "4.99"),
            "SC": (currencyCode: "USD", amount: "4.99"),
            "SE": (currencyCode: "SEK", amount: "69.0"),
            "SG": (currencyCode: "SGD", amount: "6.98"),
            "SI": (currencyCode: "EUR", amount: "5.99"),
            "SK": (currencyCode: "EUR", amount: "5.99"),
            "SL": (currencyCode: "USD", amount: "4.99"),
            "SN": (currencyCode: "USD", amount: "5.99"),
            "SR": (currencyCode: "USD", amount: "4.99"),
            "ST": (currencyCode: "USD", amount: "4.99"),
            "SV": (currencyCode: "USD", amount: "4.99"),
            "SZ": (currencyCode: "USD", amount: "4.99"),
            "TC": (currencyCode: "USD", amount: "4.99"),
            "TD": (currencyCode: "USD", amount: "4.99"),
            "TH": (currencyCode: "THB", amount: "199.0"),
            "TJ": (currencyCode: "USD", amount: "4.99"),
            "TM": (currencyCode: "USD", amount: "4.99"),
            "TN": (currencyCode: "USD", amount: "4.99"),
            "TO": (currencyCode: "USD", amount: "4.99"),
            "TR": (currencyCode: "TRY", amount: "249.99"),
            "TT": (currencyCode: "USD", amount: "4.99"),
            "TW": (currencyCode: "TWD", amount: "150"),
            "TZ": (currencyCode: "TZS", amount: "14900.0"),
            "UA": (currencyCode: "USD", amount: "5.99"),
            "UG": (currencyCode: "USD", amount: "5.99"),
            "US": (currencyCode: "USD", amount: "4.99"),
            "UY": (currencyCode: "USD", amount: "4.99"),
            "UZ": (currencyCode: "USD", amount: "4.99"),
            "VC": (currencyCode: "USD", amount: "4.99"),
            "VE": (currencyCode: "USD", amount: "4.99"),
            "VG": (currencyCode: "USD", amount: "4.99"),
            "VN": (currencyCode: "VND", amount: "149000"),
            "VU": (currencyCode: "USD", amount: "4.99"),
            "XK": (currencyCode: "EUR", amount: "5.99"),
            "YE": (currencyCode: "USD", amount: "4.99"),
            "ZA": (currencyCode: "ZAR", amount: "99.99"),
            "ZM": (currencyCode: "USD", amount: "5.99"),
            "ZW": (currencyCode: "USD", amount: "5.99")
        ]
    }

    private func observeTransactionUpdates() async {
        for await result in Transaction.updates {
            guard !Task.isCancelled else { return }

            do {
                let transaction = try checkVerified(result)
                logger.info("Observed transaction update. productID=\(transaction.productID, privacy: .public) transactionID=\(String(transaction.id), privacy: .public)")
                await refreshEntitlements()
                await transaction.finish()
            } catch {
                logger.error("Received unverified transaction update.")
                purchaseError = AppStrings.current.purchaseUpdateUnverified
            }
        }
    }

    private func preferredProduct(from products: [Product]) -> Product? {
        let productsByID = Dictionary(uniqueKeysWithValues: products.map { ($0.id, $0) })

        for productID in productIDs {
            if let product = productsByID[productID] {
                return product
            }
        }

        return nil
    }

    private func fetchProductsWithDiagnostics() async throws -> ProductFetchDiagnostics {
        let products = try await Product.products(for: productIDs)
        let diagnostics = await ProductIDDiagnosticsRequester.fetchDiagnostics(for: productIDs)
        return ProductFetchDiagnostics(
            requestedProductIDs: productIDs,
            fetchedProducts: products,
            invalidProductIDs: diagnostics.invalidProductIDs
        )
    }

    private func shouldRetryEmptyProductFetch(diagnostics: ProductFetchDiagnostics) -> Bool {
        diagnostics.fetchedProducts.isEmpty &&
        diagnostics.invalidProductIDs.isEmpty &&
        (isRunningFromXcode || storeEnvironmentDescription == "sandbox" || storeEnvironmentDescription == "unknown")
    }

    private func logProductDiagnostics(_ diagnostics: ProductFetchDiagnostics) {
        let fetchedDescriptions = diagnostics.fetchedProducts
            .map { "\($0.id) [\($0.type)] \($0.displayPrice)" }
            .joined(separator: " | ")

        logger.info("Fetched StoreKit products count=\(diagnostics.fetchedProducts.count, privacy: .public) fetchedIDs=\(diagnostics.fetchedProductIDs.joined(separator: ","), privacy: .public)")

        if !fetchedDescriptions.isEmpty {
            logger.info("Fetched product details: \(fetchedDescriptions, privacy: .public)")
        }

        if !diagnostics.invalidProductIDs.isEmpty {
            logger.error("Invalid product identifiers: \(diagnostics.invalidProductIDs.joined(separator: ","), privacy: .public)")
        }

        if !diagnostics.missingProductIDs.isEmpty {
            logger.error("Requested product IDs missing from StoreKit response: \(diagnostics.missingProductIDs.joined(separator: ","), privacy: .public)")
        }
    }

    private func currentActiveEntitlementProductIDs() async -> [String] {
        var activeProductIDs: [String] = []

        for await result in Transaction.currentEntitlements {
            guard let transaction = try? checkVerified(result) else { continue }
            guard transaction.revocationDate == nil else { continue }
            guard transaction.expirationDate.map({ $0 > .now }) ?? true else { continue }
            activeProductIDs.append(transaction.productID)
        }

        return activeProductIDs
    }

    private func unavailablePurchaseMessage(configuredProducts: String) -> String {
        if !invalidProductIDs.isEmpty {
            return AppStrings.current.noPremiumProductFound(productIDs: invalidProductIDs.joined(separator: ", "))
        }

        return AppStrings.current.noPremiumProductFound(productIDs: configuredProducts)
    }

    private func logStoreConfiguration() {
        logger.info("PremiumStore configured. bundleID=\(self.bundleIdentifier, privacy: .public) env=\(self.storeEnvironmentDescription, privacy: .public) productIDs=\(self.productIDs.joined(separator: ","), privacy: .public) receipt=\(self.receiptFileName, privacy: .public) debugUnlockEnabled=\(self.canUseDebugLocalUnlock, privacy: .public)")
    }

    private var bundleIdentifier: String {
        Bundle.main.bundleIdentifier ?? "missing-bundle-id"
    }

    private var receiptFileName: String {
        Bundle.main.appStoreReceiptURL?.lastPathComponent ?? "no-receipt"
    }

    private var isRunningFromXcode: Bool {
        let environment = ProcessInfo.processInfo.environment
        return environment["OS_ACTIVITY_DT_MODE"] == "YES" ||
            environment["__XCODE_BUILT_PRODUCTS_DIR_PATHS"] != nil
    }

    private var storeEnvironmentDescription: String {
        let receiptName = receiptFileName
        if receiptName == "sandboxReceipt" {
            return "sandbox"
        }
        if receiptName == "receipt" {
            return "production"
        }
        if isRunningFromXcode {
            return "xcode"
        }
        return "unknown"
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

private struct ProductFetchDiagnostics {
    let requestedProductIDs: [String]
    let fetchedProducts: [Product]
    let invalidProductIDs: [String]

    var fetchedProductIDs: [String] {
        fetchedProducts.map(\.id)
    }

    var missingProductIDs: [String] {
        requestedProductIDs.filter { !fetchedProductIDs.contains($0) }
    }
}

private struct ProductIDDiagnostics {
    let invalidProductIDs: [String]
}

private final class ProductIDDiagnosticsRequester: NSObject, SKProductsRequestDelegate {
    private var continuation: CheckedContinuation<ProductIDDiagnostics, Never>?
    private var request: SKProductsRequest?

    static func fetchDiagnostics(for productIDs: [String]) async -> ProductIDDiagnostics {
        let requester = ProductIDDiagnosticsRequester()
        return await requester.start(productIDs: productIDs)
    }

    private func start(productIDs: [String]) async -> ProductIDDiagnostics {
        await withCheckedContinuation { continuation in
            self.continuation = continuation
            let request = SKProductsRequest(productIdentifiers: Set(productIDs))
            request.delegate = self
            self.request = request
            request.start()
        }
    }

    func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
        finish(with: ProductIDDiagnostics(invalidProductIDs: response.invalidProductIdentifiers))
    }

    func request(_ request: SKRequest, didFailWithError error: Error) {
        finish(with: ProductIDDiagnostics(invalidProductIDs: []))
    }

    private func finish(with diagnostics: ProductIDDiagnostics) {
        continuation?.resume(returning: diagnostics)
        continuation = nil
        request = nil
    }
}
