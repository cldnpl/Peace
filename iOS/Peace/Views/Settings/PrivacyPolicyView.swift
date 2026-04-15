import SwiftUI
import WebKit

struct PrivacyPolicyView: View {
    @EnvironmentObject private var languageStore: AppLanguageStore
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    private var t: AppStrings {
        AppStrings(language: languageStore.selectedLanguage)
    }

    var body: some View {
        ZStack {
            AmbientBackground()

            GeometryReader { proxy in
                let layout = MMLayoutMetrics(size: proxy.size, horizontalSizeClass: horizontalSizeClass)

                if let fileURL = Bundle.main.url(forResource: "privacy", withExtension: "html") {
                    PrivacyPolicyWebView(fileURL: fileURL)
                        .clipShape(RoundedRectangle(cornerRadius: MMRadius.lg, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: MMRadius.lg, style: .continuous)
                                .strokeBorder(Color.mmBorder, lineWidth: 1)
                        )
                        .frame(maxWidth: layout.readingContentWidth)
                        .frame(maxWidth: .infinity)
                        .safeAreaPadding(.horizontal, layout.horizontalPadding)
                        .safeAreaPadding(.vertical, MMSpacing.md)
                } else {
                    ScrollView(showsIndicators: false) {
                        MMCard {
                            Text(t.privacyPolicyMissing)
                                .font(MMFont.body(15))
                                .foregroundStyle(.mmTextPrimary)
                        }
                        .padding(.horizontal, layout.horizontalPadding)
                        .padding(.top, MMSpacing.lg)
                    }
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .principal) {
                MMNavigationBarTitle(text: t.privacyPolicyTitle)
            }
        }
    }
}

private struct PrivacyPolicyWebView: UIViewRepresentable {
    let fileURL: URL

    func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.defaultWebpagePreferences.allowsContentJavaScript = false

        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.isOpaque = false
        webView.backgroundColor = .clear
        webView.scrollView.backgroundColor = .clear
        webView.scrollView.contentInsetAdjustmentBehavior = .never
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        guard webView.url != fileURL else { return }
        webView.loadFileURL(fileURL, allowingReadAccessTo: fileURL.deletingLastPathComponent())
    }
}
