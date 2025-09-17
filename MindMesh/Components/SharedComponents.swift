import SwiftUI

struct MMCard<Content: View>: View {
    var padding: CGFloat = MMSpacing.xl
    var cornerRadius: CGFloat = MMRadius.lg
    var borderColor: Color = .mmBorder
    var backgroundColor: Color = .mmCard
    @ViewBuilder let content: () -> Content

    var body: some View {
        content()
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(backgroundColor)
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .strokeBorder(borderColor, lineWidth: 1)
                    )
                    .mmCardShadow()
            )
    }
}

struct MMSectionLabel: View {
    let text: String
    var color: Color = .mmAccent

    var body: some View {
        Text(text)
            .font(MMFont.caption(11, weight: .semibold))
            .tracking(1.2)
            .foregroundStyle(color)
    }
}

struct MMInlineBadge: View {
    let title: String
    var icon: String? = nil
    var tint: Color = .mmAccent3

    var body: some View {
        HStack(spacing: 6) {
            if let icon {
                Image(systemName: icon)
                    .font(.system(size: 11, weight: .semibold))
            }

            Text(title)
                .font(MMFont.caption(11, weight: .semibold))
        }
        .foregroundStyle(tint)
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background(
            Capsule()
                .fill(tint.opacity(0.10))
                .overlay(Capsule().strokeBorder(tint.opacity(0.18), lineWidth: 1))
        )
    }
}

struct AIBadge: View {
    var body: some View {
        MMInlineBadge(title: "Assistita", icon: "sparkles", tint: .mmAccent)
    }
}

struct GradientText: View {
    let text: String
    var font: Font = .largeTitle.bold()
    var gradient: LinearGradient = .mmHeroGradient

    var body: some View {
            Text(text)
            .font(font)
            .foregroundStyle(gradient)
    }
}

struct PulsingCircle: View {
    let color: Color
    let size: CGFloat
    @State private var pulse = false

    var body: some View {
        ZStack {
            Circle()
                .stroke(color.opacity(0.14), lineWidth: 1)
                .frame(width: size + 48, height: size + 48)
                .scaleEffect(pulse ? 1.08 : 1.0)

            Circle()
                .stroke(color.opacity(0.20), lineWidth: 1)
                .frame(width: size + 24, height: size + 24)
                .scaleEffect(pulse ? 1.04 : 1.0)
        }
        .animation(.easeInOut(duration: 2.8).repeatForever(autoreverses: true), value: pulse)
        .onAppear { pulse = true }
    }
}

struct MMScoreBar: View {
    let score: Double
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(color.opacity(0.12))

                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [color, color.opacity(0.62)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geo.size.width * score)
                }
            }
            .frame(height: 6)

            HStack {
                Text("Quanto pesa")
                    .font(MMFont.caption(10, weight: .medium))
                    .foregroundStyle(.mmTextDim)

                Spacer()

                Text("\(Int(score * 100))%")
                    .font(MMFont.caption(10, weight: .semibold))
                    .foregroundStyle(color)
            }
        }
    }
}

struct MMTag: View {
    let text: String
    var color: Color = .mmAccent3
    var bgOpacity: Double = 0.12

    var body: some View {
        Text(text)
            .font(MMFont.caption(11, weight: .medium))
            .foregroundStyle(color)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(color.opacity(bgOpacity))
                    .overlay(Capsule().strokeBorder(color.opacity(0.20), lineWidth: 1))
            )
    }
}

struct StatCard: View {
    let value: String
    let label: String
    var color: Color = .mmTextPrimary

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(value)
                .font(MMFont.display(30, weight: .bold))
                .foregroundStyle(color)

            Text(label)
                .font(MMFont.caption(12, weight: .medium))
                .foregroundStyle(.mmTextMuted)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, minHeight: 116, alignment: .topLeading)
        .padding(MMSpacing.lg)
        .background(
            RoundedRectangle(cornerRadius: MMRadius.md, style: .continuous)
                .fill(Color.mmCard)
                .overlay(
                    RoundedRectangle(cornerRadius: MMRadius.md, style: .continuous)
                        .strokeBorder(Color.mmBorder, lineWidth: 1)
                )
                .mmCardShadow()
        )
    }
}

struct AmbientBackground: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(hex: "fbfdff"), Color(hex: "eef7ff"), Color(hex: "f8fbff")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            EllipticalGradient(
                colors: [Color.mmAccent2.opacity(0.24), .clear],
                center: .init(x: 0.18, y: 0.10),
                endRadiusFraction: 0.74
            )
            .ignoresSafeArea()

            EllipticalGradient(
                colors: [Color.mmTeal.opacity(0.18), .clear],
                center: .init(x: 0.78, y: 0.42),
                endRadiusFraction: 0.68
            )
            .ignoresSafeArea()

            EllipticalGradient(
                colors: [Color.mmAccent.opacity(0.10), .clear],
                center: .init(x: 0.22, y: 0.86),
                endRadiusFraction: 0.62
            )
            .ignoresSafeArea()

            EllipticalGradient(
                colors: [Color.mmAmber.opacity(0.10), .clear],
                center: .init(x: 0.84, y: 0.82),
                endRadiusFraction: 0.50
            )
            .ignoresSafeArea()
        }
    }
}

struct MMPrimaryButton: View {
    let title: String
    var icon: String? = nil
    var gradient: LinearGradient = .mmAccentGradient
    var glowColor: Color = .mmAccent
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                if let icon {
                    Image(systemName: icon)
                        .font(.system(size: 15, weight: .semibold))
                }

                Text(title)
                    .font(MMFont.title(16, weight: .semibold))
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(gradient, in: RoundedRectangle(cornerRadius: MMRadius.lg, style: .continuous))
            .mmGlowShadow(color: glowColor, radius: 20)
        }
        .buttonStyle(.plain)
    }
}

struct MMSecondaryButton: View {
    let title: String
    var icon: String? = nil
    var tint: Color = .mmTextPrimary
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let icon {
                    Image(systemName: icon)
                        .font(.system(size: 14, weight: .semibold))
                }

                Text(title)
                    .font(MMFont.title(15, weight: .medium))
            }
            .foregroundStyle(tint)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: MMRadius.lg, style: .continuous)
                    .fill(Color.mmCard.opacity(0.72))
                    .overlay(
                        RoundedRectangle(cornerRadius: MMRadius.lg, style: .continuous)
                            .strokeBorder(Color.mmBorderStrong, lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

private struct MMCrownSelectionModifier: ViewModifier {
    @Binding var crownValue: Double
    let range: ClosedRange<Double>

    func body(content: Content) -> some View {
        #if os(watchOS)
        content
            .focusable(true)
            .digitalCrownRotation(
                $crownValue,
                from: range.lowerBound,
                through: range.upperBound,
                by: 1,
                sensitivity: .medium,
                isContinuous: false,
                isHapticFeedbackEnabled: true
            )
        #else
        content
        #endif
    }
}

extension View {
    func mmCrownSelection(_ crownValue: Binding<Double>, range: ClosedRange<Double>) -> some View {
        modifier(MMCrownSelectionModifier(crownValue: crownValue, range: range))
    }
}

private struct MMToolbarAvatarButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Circle()
                .fill(LinearGradient.mmAccentGradient)
                .frame(width: 32, height: 32)
                .overlay(
                    Image(systemName: "person.crop.circle.fill")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.white)
                )
                .overlay(
                    Circle()
                        .strokeBorder(.white.opacity(0.5), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Apri profilo")
    }
}

private struct MMProfileAccessModifier: ViewModifier {
    @State private var showProfile = false

    func body(content: Content) -> some View {
        content
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    MMToolbarAvatarButton {
                        showProfile = true
                    }
                }
            }
            .sheet(isPresented: $showProfile) {
                ProfileView()
            }
    }
}

extension View {
    func mmProfileAccess() -> some View {
        modifier(MMProfileAccessModifier())
    }
}
