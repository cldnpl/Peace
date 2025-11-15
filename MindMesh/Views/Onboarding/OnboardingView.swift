import SwiftUI

struct OnboardingView: View {
    @Binding var hasSeenOnboarding: Bool
    @AppStorage("peace.userName") private var storedUserName = ""
    @State private var orb = false
    @State private var appear = false
    @State private var draftName = ""

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
                    Spacer(minLength: MMSpacing.xl)

                    hero
                        .padding(.bottom, MMSpacing.xxl)

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
            draftName = storedUserName
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
        .padding(.top, MMSpacing.lg)
    }

    private var intro: some View {
        VStack(spacing: 14) {
            Text("Benvenuto/a in Peace.")
                .font(.system(size: 38, weight: .bold, design: .serif))
                .foregroundStyle(.mmTextPrimary)
                .multilineTextAlignment(.center)

            Text("Un posto semplice per capire come stai, con calma. Prima di iniziare, dimmi solo come vuoi essere chiamato/a.")
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
            VStack(alignment: .leading, spacing: 10) {
                MMSectionLabel(text: "Il tuo nome")

                TextField("Come ti chiami?", text: $draftName)
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

            MMPrimaryButton(title: "Continua", icon: "arrow.right") {
                storedUserName = normalizedName
                withAnimation(.spring(response: 0.4, dampingFraction: 0.86)) {
                    hasSeenOnboarding = true
                }
            }
            .disabled(normalizedName.isEmpty)
            .opacity(normalizedName.isEmpty ? 0.48 : 1)
        }
        .opacity(appear ? 1 : 0)
    }

    private var normalizedName: String {
        draftName.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

struct OnboardingView_Previews: PreviewProvider {
    static var previews: some View {
        OnboardingView(hasSeenOnboarding: .constant(false))
    }
}
