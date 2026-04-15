import SwiftUI

struct AISupportChatView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var languageStore: AppLanguageStore
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @StateObject private var vm = AISupportChatViewModel()

    private var t: AppStrings {
        AppStrings(language: languageStore.selectedLanguage)
    }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                AmbientBackground()

                GeometryReader { proxy in
                    let layout = MMLayoutMetrics(size: proxy.size, horizontalSizeClass: horizontalSizeClass)

                    VStack(spacing: 0) {
                        safetyBanner(layout: layout)

                        ScrollViewReader { proxy in
                            ScrollView(showsIndicators: false) {
                                VStack(alignment: .leading, spacing: MMSpacing.lg) {
                                    recentSessionsStrip(layout: layout)
                                    quickPromptStrip(layout: layout)

                                    ForEach(vm.messages) { message in
                                        messageBubble(message, layout: layout)
                                            .id(message.id)
                                    }

                                    if vm.isProcessing {
                                        typingBubble(layout: layout)
                                    }
                                }
                                .frame(maxWidth: layout.readingContentWidth, alignment: .leading)
                                .frame(maxWidth: .infinity, alignment: .center)
                                .padding(.horizontal, layout.horizontalPadding)
                                .padding(.top, MMSpacing.lg)
                                .padding(.bottom, 120)
                            }
                            .onChange(of: vm.messages.count) { _, _ in
                                scrollToLatest(using: proxy)
                            }
                            .onChange(of: vm.isProcessing) { _, _ in
                                scrollToLatest(using: proxy)
                            }
                        }

                        composer(layout: layout)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    MMNavigationBarTitle(text: t.premiumChatTitle)
                }

                ToolbarItem(placement: .topBarLeading) {
                    Button(t.close) {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button(t.newChat) {
                        vm.resetConversation()
                    }
                }
            }
        }
    }

    private func safetyBanner(layout: MMLayoutMetrics) -> some View {
        MMCard(
            padding: MMSpacing.md,
            cornerRadius: MMRadius.md,
            borderColor: Color.mmAmber.opacity(0.22),
            backgroundColor: Color.mmCard.opacity(0.88)
        ) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "shield.lefthalf.filled")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.mmAmber)

                Text(t.supportChatSafety)
                    .font(MMFont.body(layout.isPad ? 14 : 13))
                    .foregroundStyle(.mmTextMuted)
                    .lineSpacing(3)
            }
        }
        .frame(maxWidth: layout.readingContentWidth)
        .frame(maxWidth: .infinity)
        .padding(.horizontal, layout.horizontalPadding)
        .padding(.top, MMSpacing.md)
    }

    @ViewBuilder
    private func recentSessionsStrip(layout: MMLayoutMetrics) -> some View {
        if !vm.recentSessions.isEmpty {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text(t.recentChats)
                        .font(MMFont.caption(12, weight: .semibold))
                        .foregroundStyle(.mmTextMuted)

                    Spacer()

                    Text(t.premiumOnly)
                        .font(MMFont.caption(11, weight: .medium))
                        .foregroundStyle(.mmTextDim)
                }

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(vm.recentSessions) { session in
                            Button {
                                vm.loadSession(session)
                            } label: {
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack(spacing: 8) {
                                        Image(systemName: "quote.bubble")
                                            .font(.system(size: 13, weight: .semibold))
                                            .foregroundStyle(.mmAccent)

                                        Text(session.updatedAt.formatted(date: .abbreviated, time: .omitted))
                                            .font(MMFont.caption(11, weight: .medium))
                                            .foregroundStyle(.mmTextDim)

                                        Spacer(minLength: 0)
                                    }

                                    Text(session.title)
                                        .font(MMFont.body(13))
                                        .foregroundStyle(.mmTextPrimary)
                                        .lineLimit(2)

                                    Text(session.previewText)
                                        .font(MMFont.caption(11))
                                        .foregroundStyle(.mmTextMuted)
                                        .lineLimit(2)
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 12)
                                .frame(width: layout.isPad ? 220 : 188, alignment: .leading)
                                .background(
                                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                                        .fill(Color.mmCard.opacity(0.92))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                                .strokeBorder(
                                                    vm.isCurrentSession(session)
                                                        ? Color.mmAccent.opacity(0.28)
                                                        : Color.mmBorderStrong,
                                                    lineWidth: 1
                                                )
                                        )
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
    }

    private func quickPromptStrip(layout: MMLayoutMetrics) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(vm.quickPrompts, id: \.self) { prompt in
                    Button {
                        vm.sendQuickPrompt(prompt)
                    } label: {
                        Text(prompt)
                            .font(MMFont.caption(12, weight: .medium))
                            .foregroundStyle(.mmTextPrimary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 10)
                            .background(
                                Capsule()
                                    .fill(Color.mmCard.opacity(0.92))
                                    .overlay(
                                        Capsule()
                                            .strokeBorder(Color.mmBorderStrong, lineWidth: 1)
                                    )
                            )
                    }
                    .buttonStyle(.plain)
                    .disabled(vm.isProcessing)
                }
            }
        }
    }

    @ViewBuilder
    private func messageBubble(_ message: SupportChatMessage, layout: MMLayoutMetrics) -> some View {
        HStack {
            if message.role == .assistant {
                bubble(message.text, isAssistant: true, layout: layout)
                Spacer(minLength: 40)
            } else {
                Spacer(minLength: 40)
                bubble(message.text, isAssistant: false, layout: layout)
            }
        }
    }

    private func typingBubble(layout: MMLayoutMetrics) -> some View {
        HStack {
            bubble(t.supportTyping, isAssistant: true, layout: layout)
            Spacer(minLength: 40)
        }
        .transition(.opacity)
    }

    private func bubble(_ text: String, isAssistant: Bool, layout: MMLayoutMetrics) -> some View {
        Text(text)
            .font(MMFont.body(layout.isPad ? 15 : 14))
            .foregroundStyle(isAssistant ? .mmTextPrimary : Color.white)
            .lineSpacing(4)
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .frame(maxWidth: layout.messageBubbleWidth, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(isAssistant ? Color.mmCard.opacity(0.96) : Color.mmAccent)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .strokeBorder(isAssistant ? Color.mmBorderStrong : Color.mmAccent.opacity(0.18), lineWidth: 1)
                    )
            )
    }

    private func composer(layout: MMLayoutMetrics) -> some View {
        VStack(spacing: 10) {
            Divider()
                .overlay(Color.mmBorder)

            HStack(alignment: .bottom, spacing: 12) {
                TextField(t.supportInputPlaceholder, text: $vm.draft, axis: .vertical)
                    .font(MMFont.body(14))
                    .foregroundStyle(.mmTextPrimary)
                    .lineLimit(1...5)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(Color.mmCard.opacity(0.94))
                            .overlay(
                                RoundedRectangle(cornerRadius: 18, style: .continuous)
                                    .strokeBorder(Color.mmBorderStrong, lineWidth: 1)
                            )
                    )

                Button {
                    vm.sendMessage()
                } label: {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 30, weight: .semibold))
                        .foregroundStyle(vm.draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? .mmTextDim : .mmAccent)
                }
                    .buttonStyle(.plain)
                    .disabled(vm.draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || vm.isProcessing)
            }
            .frame(maxWidth: layout.readingContentWidth, alignment: .center)
            .frame(maxWidth: .infinity)
            .padding(.horizontal, layout.horizontalPadding)
            .padding(.bottom, MMSpacing.md)
            .padding(.top, 10)
            .background(.ultraThinMaterial)
        }
    }

    private func scrollToLatest(using proxy: ScrollViewProxy) {
        guard let lastID = vm.messages.last?.id else { return }
        DispatchQueue.main.async {
            withAnimation(.easeOut(duration: 0.2)) {
                proxy.scrollTo(lastID, anchor: .bottom)
            }
        }
    }
}

struct AISupportChatView_Previews: PreviewProvider {
    static var previews: some View {
        AISupportChatView()
            .environmentObject(AppLanguageStore(initialLanguage: .italian))
    }
}
