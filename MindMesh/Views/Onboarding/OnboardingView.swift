import SwiftUI

struct OnboardingView: View {
    @Binding var hasSeenOnboarding: Bool
    @State private var orb = false
    @State private var appear = false

    private let features = [
        ("text.alignleft", "Sintesi chiare", "Trovi subito il punto della giornata senza schermate inutili."),
        ("heart.text.square.fill", "Umore leggibile", "Tieni traccia di come stai con un gesto semplice."),
        ("sparkles", "Riflessioni utili", "Ricevi spunti corti, concreti e facili da usare.")
    ]

    var body: some View {
        ZStack {
            AmbientBackground()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    Spacer(minLength: MMSpacing.xxxl)

                    hero
                        .padding(.bottom, MMSpacing.xxxl)

                    intro
                        .padding(.bottom, MMSpacing.xxl)

                    featureList
                        .padding(.bottom, MMSpacing.xxxl)

                    actions
                }
                .padding(.horizontal, MMSpacing.xl)
                .padding(.bottom, MMSpacing.xxl)
            }
        }
        .onAppear {
            orb = true
            withAnimation(.easeOut(duration: 0.8).delay(0.15)) {
                appear = true
            }
        }
    }

    private var hero: some View {
        ZStack {
            PulsingCircle(color: .mmAccent, size: 126)

            Circle()
                .fill(
                    LinearGradient(
                        colors: [.mmAccent, .mmAccent2, .mmAccent3],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 126, height: 126)
                .overlay(
                    Image(systemName: "scribble.variable")
                        .font(.system(size: 42, weight: .light))
                        .foregroundStyle(.white.opacity(0.94))
                )
                .shadow(color: .mmAccent.opacity(0.28), radius: 30, x: 0, y: 14)
                .scaleEffect(orb ? 1.03 : 1.0)
                .animation(.easeInOut(duration: 3).repeatForever(autoreverses: true), value: orb)
        }
        .frame(maxWidth: .infinity)
        .opacity(appear ? 1 : 0)
        .offset(y: appear ? 0 : 26)
    }

    private var intro: some View {
        VStack(spacing: 14) {
            Text("Metti ordine nei pensieri.")
                .font(.system(size: 38, weight: .bold, design: .serif))
                .foregroundStyle(.mmTextPrimary)
                .multilineTextAlignment(.center)

            Text("MindMesh ti aiuta a ritrovare il filo tra idee, umore e piccole decisioni quotidiane. Senza schermate che urlano.")
                .font(.system(size: 16, weight: .regular))
                .foregroundStyle(.mmTextMuted)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .padding(.horizontal, MMSpacing.md)
        }
        .opacity(appear ? 1 : 0)
        .offset(y: appear ? 0 : 18)
    }

    private var featureList: some View {
        VStack(spacing: MMSpacing.md) {
            ForEach(features, id: \.0) { icon, title, text in
                MMCard(padding: MMSpacing.lg, cornerRadius: MMRadius.md) {
                    HStack(alignment: .top, spacing: MMSpacing.md) {
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(Color.mmSurface)
                            .frame(width: 46, height: 46)
                            .overlay(
                                Image(systemName: icon)
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundStyle(.mmAccent)
                            )

                        VStack(alignment: .leading, spacing: 6) {
                            Text(title)
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundStyle(.mmTextPrimary)

                            Text(text)
                                .font(.system(size: 13))
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

    private var actions: some View {
        VStack(spacing: 12) {
            MMPrimaryButton(title: "Entra in MindMesh", icon: "arrow.right") {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.86)) {
                    hasSeenOnboarding = true
                }
            }

            MMSecondaryButton(title: "Ho gia un profilo") {
                hasSeenOnboarding = true
            }
        }
        .opacity(appear ? 1 : 0)
    }
}

struct OnboardingView_Previews: PreviewProvider {
    static var previews: some View {
        OnboardingView(hasSeenOnboarding: .constant(false))
    }
}
