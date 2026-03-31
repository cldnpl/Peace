import SwiftUI

struct OnboardingView: View {
    @Binding var hasSeenOnboarding: Bool
    @EnvironmentObject private var languageStore: AppLanguageStore
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @AppStorage("peace.userName") private var storedUserName = ""
    @State private var orb = false
    @State private var appear = false
    @State private var draftName = ""

    private var t: AppStrings {
        AppStrings(language: languageStore.selectedLanguage)
    }

    private var features: [(String, String, String)] {
        [
            ("text.alignleft", t.onboardingFeatureSummaryTitle, t.onboardingFeatureSummaryBody),
            ("heart.text.square.fill", t.onboardingFeatureMoodTitle, t.onboardingFeatureMoodBody),
            ("sparkles", t.onboardingFeatureInsightsTitle, t.onboardingFeatureInsightsBody)
        ]
    }

    var body: some View {
        ZStack {
            AmbientBackground()

            GeometryReader { proxy in
                let layout = MMLayoutMetrics(size: proxy.size, horizontalSizeClass: horizontalSizeClass)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        Spacer(minLength: layout.isPad ? MMSpacing.xxxl : MMSpacing.xl)

                        if layout.prefersSplitLayout {
                            HStack(alignment: .center, spacing: layout.sectionSpacing) {
                                VStack(spacing: 0) {
                                    hero(layout: layout)
                                        .padding(.bottom, MMSpacing.xxl)

                                    intro(layout: layout)
                                }
                                .frame(maxWidth: .infinity)

                                VStack(spacing: 0) {
                                    featureList(layout: layout)
                                        .padding(.bottom, MMSpacing.xxxl)

                                    actions(layout: layout)
                                }
                                .frame(maxWidth: .infinity)
                            }
                        } else {
                            hero(layout: layout)
                                .padding(.bottom, MMSpacing.xxl)

                            intro(layout: layout)
                                .padding(.bottom, MMSpacing.xxl)

                            featureList(layout: layout)
                                .padding(.bottom, MMSpacing.xxxl)

                            actions(layout: layout)
                        }
                    }
                    .frame(maxWidth: layout.screenContentWidth, alignment: .center)
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, layout.horizontalPadding)
                    .padding(.bottom, layout.isPad ? MMSpacing.xxxl : MMSpacing.xxl)
                }
            }
        }
        .onAppear {
            orb = true
            draftName = storedUserName
            withAnimation(.easeOut(duration: 0.8).delay(0.15)) {
                appear = true
            }
        }
    }

    private func hero(layout: MMLayoutMetrics) -> some View {
        ZStack {
            PulsingCircle(color: .mmAccent, size: layout.isPad ? 162 : 126)

            Circle()
                .fill(Color.mmCard.opacity(0.92))
                .frame(width: layout.isPad ? 162 : 126, height: layout.isPad ? 162 : 126)
                .overlay(
                    Image("OnboardingHero")
                        .resizable()
                        .scaledToFill()
                        .frame(width: layout.isPad ? 152 : 118, height: layout.isPad ? 152 : 118)
                        .clipShape(Circle())
                )
                .overlay(
                    Circle()
                        .strokeBorder(Color.white.opacity(0.44), lineWidth: 1.5)
                )
                .shadow(color: .mmAccent.opacity(0.28), radius: 30, x: 0, y: 14)
                .scaleEffect(orb ? 1.03 : 1.0)
                .animation(.easeInOut(duration: 3).repeatForever(autoreverses: true), value: orb)
        }
        .frame(maxWidth: .infinity)
        .opacity(appear ? 1 : 0)
        .padding(.top, MMSpacing.lg)
    }

    private func intro(layout: MMLayoutMetrics) -> some View {
        VStack(spacing: 14) {
            Text(t.onboardingWelcomeTitle)
                .font(.system(size: layout.isPad ? 50 : 38, weight: .bold, design: .serif))
                .foregroundStyle(.mmTextPrimary)
                .multilineTextAlignment(.center)

            Text(t.onboardingWelcomeBody)
                .font(.system(size: layout.isPad ? 18 : 16, weight: .regular))
                .foregroundStyle(.mmTextMuted)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .padding(.horizontal, MMSpacing.md)
        }
        .opacity(appear ? 1 : 0)
        .offset(y: appear ? 0 : 18)
    }

    private func featureList(layout: MMLayoutMetrics) -> some View {
        VStack(spacing: MMSpacing.md) {
            ForEach(features, id: \.0) { icon, title, text in
                MMCard(padding: layout.cardPadding, cornerRadius: MMRadius.md) {
                    HStack(alignment: .top, spacing: MMSpacing.md) {
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(Color.mmSurface)
                            .frame(width: layout.isPad ? 52 : 46, height: layout.isPad ? 52 : 46)
                            .overlay(
                                Image(systemName: icon)
                                    .font(.system(size: layout.isPad ? 20 : 18, weight: .semibold))
                                    .foregroundStyle(.mmAccent)
                            )

                        VStack(alignment: .leading, spacing: 6) {
                            Text(title)
                                .font(.system(size: layout.isPad ? 17 : 15, weight: .semibold))
                                .foregroundStyle(.mmTextPrimary)

                            Text(text)
                                .font(.system(size: layout.isPad ? 14 : 13))
                                .foregroundStyle(.mmTextMuted)
                                .lineSpacing(3)
                        }

                        Spacer(minLength: 0)
                    }
                }
            }
        }
        .opacity(appear ? 1 : 0)
    }

    private func actions(layout: MMLayoutMetrics) -> some View {
        VStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 10) {
                MMSectionLabel(text: t.onboardingYourName)

                TextField(t.onboardingNamePlaceholder, text: $draftName)
                    .font(MMFont.body(16))
                    .foregroundStyle(.mmTextPrimary)
                    .textInputAutocapitalization(.words)
                    .autocorrectionDisabled()
                    .padding(MMSpacing.lg)
                    .background(
                        RoundedRectangle(cornerRadius: MMRadius.md, style: .continuous)
                            .fill(Color.mmCard.opacity(0.94))
                            .overlay(
                                RoundedRectangle(cornerRadius: MMRadius.md, style: .continuous)
                                    .strokeBorder(Color.mmBorderStrong, lineWidth: 1)
                            )
                            .mmCardShadow()
                    )
            }

            MMPrimaryButton(title: t.continueButton, icon: "arrow.right") {
                storedUserName = normalizedName
                withAnimation(.spring(response: 0.4, dampingFraction: 0.86)) {
                    hasSeenOnboarding = true
                }
            }
            .disabled(normalizedName.isEmpty)
            .opacity(normalizedName.isEmpty ? 0.48 : 1)
        }
        .frame(maxWidth: layout.formContentWidth, alignment: .center)
        .opacity(appear ? 1 : 0)
    }

    private var normalizedName: String {
        draftName.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

struct OnboardingView_Previews: PreviewProvider {
    static var previews: some View {
        OnboardingView(hasSeenOnboarding: .constant(false))
            .environmentObject(AppLanguageStore(initialLanguage: .italian))
    }
}
