import SwiftUI

struct InsightsView: View {
    @StateObject private var vm = AIInsightsViewModel()
    @EnvironmentObject private var languageStore: AppLanguageStore
    @EnvironmentObject private var premiumStore: PremiumStore
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @State private var showPremiumSheet = false
    @State private var showSupportChat = false

    private var premiumAnalysisTaskID: String {
        "\(premiumStore.hasPremiumAccess)-\(languageStore.selectedLanguage.rawValue)-\(vm.analysisRequestID(language: languageStore.selectedLanguage))"
    }

    private var t: AppStrings {
        AppStrings(language: languageStore.selectedLanguage)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AmbientBackground()

                GeometryReader { proxy in
                    let layout = MMLayoutMetrics(size: proxy.size, horizontalSizeClass: horizontalSizeClass)

                    ScrollView(showsIndicators: false) {
                        VStack(alignment: .leading, spacing: 0) {
                            MMNavigationHeaderBlock(
                                text: t.insightsTitle,
                                topPadding: layout.headerTopPadding,
                                bottomPadding: layout.isPad ? MMSpacing.xl : MMSpacing.md
                            )

                            VStack(alignment: .leading, spacing: layout.sectionSpacing) {
                                if let snapshot = vm.snapshot {
                                    if layout.prefersSplitLayout {
                                        HStack(alignment: .top, spacing: layout.sectionSpacing) {
                                            VStack(alignment: .leading, spacing: layout.sectionSpacing) {
                                                reflectionCard(snapshot: snapshot, layout: layout)
                                                overviewCard(snapshot: snapshot, layout: layout)
                                            }
                                            .frame(maxWidth: .infinity, alignment: .topLeading)

                                            VStack(alignment: .leading, spacing: layout.sectionSpacing) {
                                                detailCard(snapshot: snapshot, layout: layout)
                                                premiumCard(snapshot: snapshot, layout: layout)
                                            }
                                            .frame(maxWidth: .infinity, alignment: .topLeading)
                                        }
                                    } else {
                                        reflectionCard(snapshot: snapshot, layout: layout)
                                        overviewCard(snapshot: snapshot, layout: layout)
                                        detailCard(snapshot: snapshot, layout: layout)
                                        premiumCard(snapshot: snapshot, layout: layout)
                                    }
                                } else {
                                    emptyState(layout: layout)

                                    if premiumStore.hasPremiumAccess {
                                        MMSecondaryButton(title: t.openPremiumChat, icon: "bubble.left.and.bubble.right.fill", tint: .mmAccent) {
                                            showSupportChat = true
                                        }
                                    }
                                }
                            }
                        }
                        .frame(maxWidth: layout.screenContentWidth, alignment: .leading)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.bottom, 40)
                    }
                    .safeAreaPadding(.horizontal, layout.horizontalPadding)
                    .safeAreaPadding(.bottom, MMSpacing.md)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
            .sheet(isPresented: $showPremiumSheet) {
                PremiumSheet()
            }
            .sheet(isPresented: $showSupportChat) {
                AISupportChatView()
            }
            .task(id: premiumAnalysisTaskID) {
                await vm.loadPremiumAnalysisIfNeeded(hasPremiumAccess: premiumStore.hasPremiumAccess, language: languageStore.selectedLanguage)
            }
        }
    }

    private func reflectionCard(snapshot: MoodReflectionSnapshot, layout: MMLayoutMetrics) -> some View {
        MMCard(padding: layout.cardPadding, borderColor: Color.mmAccent.opacity(0.16), backgroundColor: Color.mmCard.opacity(0.92)) {
            VStack(alignment: .leading, spacing: MMSpacing.lg) {
                MMSectionLabel(text: t.last7DaysSection)

                Text(snapshot.title)
                    .font(MMFont.display(layout.isPad ? 36 : 30, weight: .bold))
                    .foregroundStyle(.mmTextPrimary)

                Text(snapshot.message)
                    .font(MMFont.body(layout.isPad ? 16 : 15))
                    .foregroundStyle(.mmTextMuted)
                    .lineSpacing(4)
            }
        }
    }

    private func detailCard(snapshot: MoodReflectionSnapshot, layout: MMLayoutMetrics) -> some View {
        MMCard(padding: layout.cardPadding) {
            VStack(alignment: .leading, spacing: MMSpacing.lg) {
                Text(snapshot.detailTitle)
                    .font(MMFont.caption(layout.isPad ? 14 : 13, weight: .semibold))
                    .foregroundStyle(.mmTextMuted)

                HStack(alignment: .firstTextBaseline, spacing: 10) {
                    Text(snapshot.detailValue)
                        .font(MMFont.display(layout.isPad ? 40 : 34, weight: .bold))
                        .foregroundStyle(.mmTextPrimary)

                    Image(systemName: "waveform.path.ecg")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(.mmAccent3)
                }

                Text(snapshot.detailMessage)
                    .font(MMFont.body(layout.isPad ? 15 : 14))
                    .foregroundStyle(.mmTextMuted)
                    .lineSpacing(4)
            }
        }
    }

    private func overviewCard(snapshot: MoodReflectionSnapshot, layout: MMLayoutMetrics) -> some View {
        MMCard(padding: layout.cardPadding, backgroundColor: Color.mmCard.opacity(0.9)) {
            VStack(alignment: .leading, spacing: MMSpacing.lg) {
                MMSectionLabel(text: t.overviewSection)

                LazyVGrid(columns: layout.compactStatColumns, spacing: MMSpacing.md) {
                    StatCard(value: snapshot.dominantMoodLabel, label: t.mostRecurringMood, color: .mmAccent, isPadLayout: layout.isPad)
                    StatCard(value: snapshot.trendLabel, label: t.recentTrend, color: .mmAccent3, isPadLayout: layout.isPad)
                    StatCard(value: snapshot.energyLabel, label: t.averageEnergy, color: .mmTeal, isPadLayout: layout.isPad)
                    StatCard(value: snapshot.consistencyLabel, label: t.toneVariation, color: .mmRose, isPadLayout: layout.isPad)
                }
            }
        }
    }

    @ViewBuilder
    private func premiumCard(snapshot: MoodReflectionSnapshot, layout: MMLayoutMetrics) -> some View {
        if premiumStore.hasPremiumAccess {
            MMCard(padding: layout.cardPadding, borderColor: Color.mmAccent.opacity(0.18), backgroundColor: Color.mmCard.opacity(0.94)) {
                VStack(alignment: .leading, spacing: MMSpacing.lg) {
                    HStack {
                        MMSectionLabel(text: t.fullAnalysis)
                        Spacer()
                        MMInlineBadge(title: t.premiumBadge, icon: "sparkles", tint: .mmAccent)
                    }

                    if vm.isGeneratingPremiumAnalysis {
                        premiumLoadingState(layout: layout)
                    } else if let premiumAnalysis = vm.premiumAnalysis {
                        premiumAnalysisContent(premiumAnalysis, layout: layout)
                    } else if let premiumAnalysisError = vm.premiumAnalysisError {
                        premiumAnalysisErrorState(premiumAnalysisError, layout: layout)
                    }

                    VStack(spacing: 12) {
                        MMSecondaryButton(title: t.regenerateAnalysis, icon: "arrow.clockwise", tint: .mmAccent3) {
                            Task {
                                await vm.regeneratePremiumAnalysis(language: languageStore.selectedLanguage)
                            }
                        }
                        .disabled(!vm.hasEnoughDataForPremiumAnalysis || vm.isGeneratingPremiumAnalysis)

                        MMSecondaryButton(title: t.openPremiumChat, icon: "bubble.left.and.bubble.right.fill", tint: .mmAccent) {
                            showSupportChat = true
                        }
                    }
                }
            }
        } else {
            lockedPremiumCard(layout: layout)
        }
    }

    private func lockedPremiumCard(layout: MMLayoutMetrics) -> some View {
        MMCard(padding: layout.cardPadding, borderColor: Color.mmAccent.opacity(0.14), backgroundColor: Color.mmCard.opacity(0.92)) {
            VStack(alignment: .leading, spacing: MMSpacing.lg) {
                HStack {
                    MMSectionLabel(text: t.fullAnalysis)
                    Spacer()
                    Image(systemName: "lock.fill")
                        .foregroundStyle(.mmAccent)
                }

                Text(t.lockedAnalysisTitle)
                    .font(MMFont.title(layout.isPad ? 24 : 22, weight: .semibold))
                    .foregroundStyle(.mmTextPrimary)

                Text(t.lockedAnalysisBody)
                    .font(MMFont.body(layout.isPad ? 15 : 14))
                    .foregroundStyle(.mmTextMuted)
                    .lineSpacing(4)

                MMCard(
                    padding: layout.isPad ? 22 : MMSpacing.lg,
                    cornerRadius: MMRadius.md,
                    borderColor: Color.mmAccent.opacity(0.14),
                    backgroundColor: Color.mmSurface.opacity(0.76)
                ) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(t.includedInPremium)
                            .font(MMFont.caption(layout.isPad ? 13 : 12, weight: .semibold))
                            .foregroundStyle(.mmAccent)

                        Text(t.premiumBundleDescription)
                            .font(MMFont.body(layout.isPad ? 15 : 14))
                            .foregroundStyle(.mmTextPrimary)
                            .lineSpacing(3)
                    }
                }

                MMPrimaryButton(title: t.unlockFullAnalysis, icon: "sparkles") {
                    showPremiumSheet = true
                }
            }
        }
    }

    private func premiumLoadingState(layout: MMLayoutMetrics) -> some View {
        MMCard(
            padding: layout.isPad ? 22 : MMSpacing.lg,
            cornerRadius: MMRadius.md,
            borderColor: Color.mmAccent.opacity(0.14),
            backgroundColor: Color.mmSurface.opacity(0.76)
        ) {
            VStack(alignment: .leading, spacing: 12) {
                ProgressView()
                    .tint(.mmAccent)

                Text(t.premiumLoadingTitle)
                    .font(MMFont.title(layout.isPad ? 20 : 18, weight: .semibold))
                    .foregroundStyle(.mmTextPrimary)

                Text(t.premiumLoadingBody)
                    .font(MMFont.body(layout.isPad ? 15 : 14))
                    .foregroundStyle(.mmTextMuted)
                    .lineSpacing(3)
            }
        }
    }

    private func premiumAnalysisContent(_ premiumAnalysis: PremiumEmotionalAnalysis, layout: MMLayoutMetrics) -> some View {
        VStack(alignment: .leading, spacing: MMSpacing.lg) {
            VStack(alignment: .leading, spacing: 8) {
                Text(premiumAnalysis.title)
                    .font(MMFont.title(layout.isPad ? 26 : 24, weight: .semibold))
                    .foregroundStyle(.mmTextPrimary)

                Text(t.premiumGeneratedAt(premiumAnalysis.generatedAt.formatted(date: .abbreviated, time: .shortened)))
                    .font(MMFont.caption(12, weight: .medium))
                    .foregroundStyle(.mmTextDim)
            }

            MMCard(
                padding: layout.isPad ? 22 : MMSpacing.lg,
                cornerRadius: MMRadius.md,
                borderColor: Color.mmAccent2.opacity(0.18),
                backgroundColor: Color.mmSurface.opacity(0.72)
            ) {
                Text(premiumAnalysis.content)
                    .font(MMFont.body(layout.isPad ? 15 : 14))
                    .foregroundStyle(.mmTextPrimary)
                    .lineSpacing(4)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private func premiumAnalysisErrorState(_ message: String, layout: MMLayoutMetrics) -> some View {
        MMCard(
            padding: layout.isPad ? 22 : MMSpacing.lg,
            cornerRadius: MMRadius.md,
            borderColor: Color.mmRose.opacity(0.18),
            backgroundColor: Color.mmRose.opacity(0.08)
        ) {
            VStack(alignment: .leading, spacing: 10) {
                Text(t.premiumAnalysisUnavailable)
                    .font(MMFont.title(layout.isPad ? 20 : 18, weight: .semibold))
                    .foregroundStyle(.mmTextPrimary)

                Text(message)
                    .font(MMFont.body(layout.isPad ? 15 : 14))
                    .foregroundStyle(.mmTextMuted)
                    .lineSpacing(3)
            }
        }
    }

    private func emptyState(layout: MMLayoutMetrics) -> some View {
        VStack(alignment: .leading, spacing: MMSpacing.xxxl) {
            MMCard(padding: layout.cardPadding, borderColor: Color.mmAccent.opacity(0.14), backgroundColor: Color.mmCard.opacity(0.92)) {
                VStack(alignment: .leading, spacing: MMSpacing.lg) {
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(Color.mmSurface)
                        .frame(width: layout.isPad ? 64 : 56, height: layout.isPad ? 64 : 56)
                        .overlay(
                            Image(systemName: "quote.bubble")
                                .font(.system(size: layout.isPad ? 28 : 24, weight: .semibold))
                                .foregroundStyle(.mmAccent)
                        )

                    Text(t.notEnoughDataTitle)
                        .font(MMFont.display(layout.isPad ? 34 : 28, weight: .bold))
                        .foregroundStyle(.mmTextPrimary)

                    Text(t.notEnoughDataBody)
                        .font(MMFont.body(layout.isPad ? 16 : 15))
                        .foregroundStyle(.mmTextMuted)
                        .lineSpacing(4)
                }
            }

            if !premiumStore.hasPremiumAccess {
                lockedPremiumCard(layout: layout)
            }
        }
    }
}

struct AIInsightsView: View {
    var body: some View {
        InsightsView()
    }
}

struct AIInsightsView_Previews: PreviewProvider {
    static var previews: some View {
        InsightsView()
            .environmentObject(PremiumStore(storeKitEnabled: false, initialPremiumAccess: true))
            .environmentObject(AppLanguageStore(initialLanguage: .italian))
    }
}
