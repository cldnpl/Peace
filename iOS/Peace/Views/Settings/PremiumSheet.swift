import SwiftUI

struct PremiumSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase
    @EnvironmentObject private var languageStore: AppLanguageStore
    @EnvironmentObject private var premiumStore: PremiumStore
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @State private var showPurchaseFeedback = false
    @State private var showPrivacyPolicy = false

    private var t: AppStrings {
        AppStrings(language: languageStore.selectedLanguage)
    }

    private var features: [(String, String, String)] {
        [
            ("sparkles", t.premiumFeatureInsightsTitle, t.premiumFeatureInsightsBody),
            ("bubble.left.and.bubble.right", t.premiumFeatureChatTitle, t.premiumFeatureChatBody),
            ("person.text.rectangle", t.premiumFeaturePersonalisedTitle, t.premiumFeaturePersonalisedBody)
        ]
    }

    private var purchaseFeedbackMessage: String? {
        premiumStore.purchaseError ?? premiumStore.purchaseNotice
    }

    var body: some View {
        ZStack {
            AmbientBackground()

            GeometryReader { proxy in
                let layout = MMLayoutMetrics(size: proxy.size, horizontalSizeClass: horizontalSizeClass)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: MMSpacing.xxxl) {
                        VStack(spacing: 12) {
                            RoundedRectangle(cornerRadius: 24, style: .continuous)
                                .fill(Color.mmAccent.opacity(0.12))
                                .frame(width: layout.isPad ? 88 : 76, height: layout.isPad ? 88 : 76)
                                .overlay(
                                    Image(systemName: "sparkles")
                                        .font(.system(size: layout.isPad ? 34 : 30, weight: .semibold))
                                        .foregroundStyle(.mmAccent)
                                )

                            Text(t.premiumTitle)
                                .font(MMFont.display(layout.isPad ? 34 : 30, weight: .bold))
                                .foregroundStyle(.mmTextPrimary)

                            Text(t.premiumHeroSubtitle)
                                .font(MMFont.body(layout.isPad ? 16 : 15))
                                .foregroundStyle(.mmTextMuted)
                                .multilineTextAlignment(.center)
                                .lineSpacing(4)
                                .padding(.horizontal, MMSpacing.md)

                            Text(t.premiumMonthlyPriceLabel(price: premiumStore.displayedMonthlyPrice))
                                .font(MMFont.title(layout.isPad ? 22 : 20, weight: .semibold))
                                .foregroundStyle(.mmAccent)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.top, MMSpacing.xxxl)

                        MMCard(padding: layout.cardPadding) {
                            VStack(spacing: MMSpacing.lg) {
                                ForEach(features, id: \.0) { icon, title, subtitle in
                                    HStack(alignment: .top, spacing: 14) {
                                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                                            .fill(Color.mmSurface)
                                            .frame(width: layout.isPad ? 48 : 42, height: layout.isPad ? 48 : 42)
                                            .overlay(
                                                Image(systemName: icon)
                                                    .font(.system(size: layout.isPad ? 18 : 16, weight: .semibold))
                                                    .foregroundStyle(.mmAccent)
                                            )

                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(title)
                                                .font(MMFont.title(layout.isPad ? 16 : 15, weight: .semibold))
                                                .foregroundStyle(.mmTextPrimary)

                                            Text(subtitle)
                                                .font(MMFont.body(layout.isPad ? 14 : 13))
                                                .foregroundStyle(.mmTextMuted)
                                        }

                                        Spacer(minLength: 0)
                                    }
                                }
                            }
                        }

                        VStack(spacing: 12) {
                            MMPrimaryButton(
                                title: premiumStore.purchaseButtonTitle,
                                icon: premiumStore.purchaseButtonIcon,
                                gradient: LinearGradient.mmAccentGradient,
                                glowColor: .mmAccent
                            ) {
                                Task {
                                    await premiumStore.purchasePremium()
                                    if premiumStore.hasPremiumAccess {
                                        dismiss()
                                    } else if purchaseFeedbackMessage != nil {
                                        showPurchaseFeedback = true
                                    }
                                }
                            }
                            .disabled(premiumStore.hasPremiumAccess || premiumStore.isPurchasing || premiumStore.isLoadingProducts)
                            .opacity((premiumStore.hasPremiumAccess || premiumStore.isPurchasing) ? 0.7 : 1)

                            MMSecondaryButton(title: t.restorePurchases, icon: "arrow.clockwise.circle", tint: .mmAccent3) {
                                Task {
                                    await premiumStore.restorePurchases()
                                    if premiumStore.hasPremiumAccess {
                                        dismiss()
                                    } else if purchaseFeedbackMessage != nil {
                                        showPurchaseFeedback = true
                                    }
                                }
                            }
                            .disabled(premiumStore.isRestoring)

                            VStack(spacing: 10) {
                                Text(t.premiumSubscriptionDetails(price: premiumStore.displayedMonthlyPrice))
                                    .font(MMFont.caption(layout.isPad ? 13 : 12))
                                    .foregroundStyle(.mmTextMuted)
                                    .multilineTextAlignment(.center)
                                    .fixedSize(horizontal: false, vertical: true)

                                ViewThatFits(in: .horizontal) {
                                    HStack(spacing: 10) {
                                        Button {
                                            showPrivacyPolicy = true
                                        } label: {
                                            Text(t.privacyPolicyTitle)
                                                .underline()
                                        }
                                        .buttonStyle(.plain)

                                        Text("|")
                                            .foregroundStyle(.mmTextDim)

                                        Link(destination: AppLegalLinks.termsOfUseURL) {
                                            Text(t.termsOfUseTitle)
                                                .underline()
                                        }
                                    }

                                    VStack(spacing: 8) {
                                        Button {
                                            showPrivacyPolicy = true
                                        } label: {
                                            Text(t.privacyPolicyTitle)
                                                .underline()
                                        }
                                        .buttonStyle(.plain)

                                        Link(destination: AppLegalLinks.termsOfUseURL) {
                                            Text(t.termsOfUseTitle)
                                                .underline()
                                        }
                                    }
                                }
                                .font(MMFont.caption(layout.isPad ? 13 : 12, weight: .semibold))
                                .foregroundStyle(.mmAccent)
                                .multilineTextAlignment(.center)
                            }
                            .padding(.top, 2)
                        }
                        .padding(.bottom, 40)
                    }
                    .frame(maxWidth: layout.modalContentWidth, alignment: .center)
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, layout.horizontalPadding)
                }
            }
        }
        .task {
            await premiumStore.prepare(force: true)
        }
        .onChange(of: scenePhase) { _, newPhase in
            guard newPhase == .active else { return }
            Task {
                await premiumStore.prepare(force: true)
            }
        }
        .alert(
            t.premiumTitle,
            isPresented: $showPurchaseFeedback
        ) {
            Button(t.close, role: .cancel) {
                premiumStore.purchaseError = nil
                premiumStore.purchaseNotice = nil
            }
        } message: {
            Text(purchaseFeedbackMessage ?? "")
        }
        .sheet(isPresented: $showPrivacyPolicy) {
            NavigationStack {
                PrivacyPolicyView()
                    .toolbar {
                        ToolbarItem(placement: .topBarTrailing) {
                            Button(t.close) {
                                showPrivacyPolicy = false
                            }
                            .foregroundStyle(.mmAccent)
                        }
                    }
            }
        }
    }
}

struct PremiumSheet_Previews: PreviewProvider {
    static var previews: some View {
        PremiumSheet()
            .environmentObject(PremiumStore(storeKitEnabled: false, initialPremiumAccess: false))
            .environmentObject(AppLanguageStore(initialLanguage: .italian))
    }
}
