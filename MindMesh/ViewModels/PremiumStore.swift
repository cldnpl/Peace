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
        if hasPremiumAccess {
            return "Premium attivo"
        }

        if let premiumProduct {
            return "Attiva Premium · \(premiumProduct.displayPrice) al mese"
        }

        return "Attiva Premium"
    }

    var purchaseButtonIcon: String {
        hasPremiumAccess ? "checkmark.circle.fill" : "sparkles"
    }

    var storeStatusText: String {
        let configuredProducts = productIDs.joined(separator: ", ")

        if hasPremiumAccess {
            return "Premium attivo su questo account. Gli acquisti si ripristinano automaticamente quando disponibili."
        }

        if premiumProduct != nil {
            return "L'acquisto usa StoreKit e si sblocca tramite il tuo account App Store."
        }

        if isLoadingProducts {
            return "Sto caricando le opzioni di acquisto da App Store."
        }

        return "Lo shop non e ancora pronto. In debug usa lo scheme MindMesh con la configurazione locale MindMesh.storekit; per sandbox o produzione serve anche il prodotto App Store Connect con ID \(configuredProducts)."
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
                purchaseError = "Nessun prodotto premium trovato. Verifica la configurazione locale MindMesh.storekit oppure il prodotto App Store Connect con ID \(configuredProducts)."
            }
        } catch {
            purchaseError = "Non riesco a caricare lo shop in questo momento."
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
            purchaseError = "Il prodotto premium non e disponibile. Controlla che lo scheme MindMesh usi MindMesh.storekit oppure che il prodotto App Store Connect sia pronto."
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
                purchaseNotice = "Premium attivato correttamente."

            case .userCancelled:
                purchaseNotice = nil

            case .pending:
                purchaseNotice = "L'acquisto e in attesa di conferma."

            @unknown default:
                purchaseError = "Stato acquisto non riconosciuto."
            }
        } catch {
            purchaseError = "L'acquisto non e andato a buon fine. Se stai testando in locale, avvia l'app dallo scheme MindMesh con la configurazione StoreKit inclusa."
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
                ? "Acquisti ripristinati."
                : "Nessun acquisto Premium trovato per questo account."
        } catch {
            purchaseError = "Non riesco a ripristinare gli acquisti in questo momento."
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
                purchaseError = "Aggiornamento acquisto non verificato."
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
