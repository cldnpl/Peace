import SwiftUI
import UIKit

private extension UIColor {
    convenience init(hex: String, alpha: CGFloat = 1) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)

        let r: UInt64
        let g: UInt64
        let b: UInt64

        switch hex.count {
        case 3:
            (r, g, b) = ((int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (r, g, b) = (int >> 16, int >> 8 & 0xFF, int & 0xFF)
        default:
            (r, g, b) = (0, 0, 0)
        }

        self.init(
            red: CGFloat(r) / 255,
            green: CGFloat(g) / 255,
            blue: CGFloat(b) / 255,
            alpha: alpha
        )
    }
}

private extension Color {
    static func dynamic(light: String, dark: String, alpha: CGFloat = 1) -> Color {
        Color(
            uiColor: UIColor { trait in
                UIColor(
                    hex: trait.userInterfaceStyle == .dark ? dark : light,
                    alpha: alpha
                )
            }
        )
    }

    static func dynamicSystem(light: UIColor, dark: UIColor? = nil, alpha: CGFloat = 1) -> Color {
        Color(
            uiColor: UIColor { trait in
                let baseColor = trait.userInterfaceStyle == .dark ? (dark ?? light) : light
                return baseColor.withAlphaComponent(alpha)
            }
        )
    }
}

private enum MMColors {
    static let background   = Color.dynamic(light: "f8fcff", dark: "0A0E17")
    static let surface      = Color.dynamicSystem(light: UIColor(hex: "edf6ff"), dark: UIColor(hex: "1C2533"))
    static let card         = Color.dynamicSystem(light: .secondarySystemBackground, dark: UIColor(hex: "1C2533"))
    static let accent       = Color.dynamic(light: "5f95ff", dark: "78a9ff")
    static let accent2      = Color.dynamic(light: "a7d3ff", dark: "8ec3ff")
    static let accent3      = Color.dynamic(light: "72d0f2", dark: "67c7f0")
    static let teal         = Color.dynamic(light: "5db5d6", dark: "76c7e3")
    static let rose         = Color.dynamic(light: "90a9ff", dark: "a7b8ff")
    static let amber        = Color.dynamic(light: "d6e9ff", dark: "d9ebff")
    static let green        = Color.dynamic(light: "9cd7d0", dark: "a8e0d9")
    static let textPrimary  = Color.dynamicSystem(light: UIColor(hex: "1a2c43"), dark: .label)
    static let textMuted    = Color.dynamicSystem(light: UIColor(hex: "415672"), dark: .secondaryLabel, alpha: 0.88)
    static let textDim      = Color.dynamicSystem(light: UIColor(hex: "415672"), dark: .secondaryLabel, alpha: 0.62)
    static let border       = Color.dynamic(light: "1a2c43", dark: "F2F2F7", alpha: 0.08)
    static let borderStrong = Color.dynamic(light: "1a2c43", dark: "F2F2F7", alpha: 0.18)
}

extension Color {
    static let mmBackground   = MMColors.background
    static let mmSurface      = MMColors.surface
    static let mmCard         = MMColors.card
    static let mmAccent       = MMColors.accent
    static let mmAccent2      = MMColors.accent2
    static let mmAccent3      = MMColors.accent3
    static let mmTeal         = MMColors.teal
    static let mmRose         = MMColors.rose
    static let mmAmber        = MMColors.amber
    static let mmGreen        = MMColors.green
    static let mmTextPrimary  = MMColors.textPrimary
    static let mmTextMuted    = MMColors.textMuted
    static let mmTextDim      = MMColors.textDim
    static let mmBorder       = MMColors.border
    static let mmBorderStrong = MMColors.borderStrong
}

extension ShapeStyle where Self == Color {
    static var mmBackground: Color { MMColors.background }
    static var mmSurface: Color { MMColors.surface }
    static var mmCard: Color { MMColors.card }
    static var mmAccent: Color { MMColors.accent }
    static var mmAccent2: Color { MMColors.accent2 }
    static var mmAccent3: Color { MMColors.accent3 }
    static var mmTeal: Color { MMColors.teal }
    static var mmRose: Color { MMColors.rose }
    static var mmAmber: Color { MMColors.amber }
    static var mmGreen: Color { MMColors.green }
    static var mmTextPrimary: Color { MMColors.textPrimary }
    static var mmTextMuted: Color { MMColors.textMuted }
    static var mmTextDim: Color { MMColors.textDim }
    static var mmBorder: Color { MMColors.border }
    static var mmBorderStrong: Color { MMColors.borderStrong }
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)

        let a: UInt64
        let r: UInt64
        let g: UInt64
        let b: UInt64

        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

extension LinearGradient {
    static let mmAccentGradient = LinearGradient(
        colors: [.mmAccent, Color(hex: "b8dcff")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let mmTealGradient = LinearGradient(
        colors: [.mmAccent3, .mmTeal],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let mmRoseGradient = LinearGradient(
        colors: [.mmRose, .mmAccent2],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let mmHeroGradient = LinearGradient(
        colors: [.mmBackground, .mmSurface, Color.dynamic(light: "cfe7ff", dark: "102039")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

extension View {
    func mmGlowShadow(color: Color = .mmAccent, radius: CGFloat = 18) -> some View {
        shadow(color: color.opacity(0.20), radius: radius, x: 0, y: 10)
    }

    func mmCardShadow() -> some View {
        shadow(color: Color.mmTextPrimary.opacity(0.05), radius: 22, x: 0, y: 10)
    }
}

enum MMFont {
    static func display(_ size: CGFloat, weight: Font.Weight = .bold) -> Font {
        .system(size: size, weight: weight, design: .serif)
    }

    static func title(_ size: CGFloat, weight: Font.Weight = .semibold) -> Font {
        .system(size: size, weight: weight, design: .rounded)
    }

    static func body(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .rounded)
    }

    static func caption(_ size: CGFloat, weight: Font.Weight = .medium) -> Font {
        .system(size: size, weight: weight, design: .rounded)
    }
}

enum MMSpacing {
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 14
    static let lg: CGFloat = 18
    static let xl: CGFloat = 24
    static let xxl: CGFloat = 32
    static let xxxl: CGFloat = 48
}

enum MMRadius {
    static let sm: CGFloat = 12
    static let md: CGFloat = 18
    static let lg: CGFloat = 24
    static let xl: CGFloat = 30
    static let pill: CGFloat = 100
}
