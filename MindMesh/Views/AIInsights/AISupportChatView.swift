import SwiftUI

struct AISupportChatView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var languageStore: AppLanguageStore
    @StateObject private var vm = AISupportChatViewModel()

    private var t: AppStrings {
        AppStrings(language: languageStore.selectedLanguage)
    }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                AmbientBackground()

                VStack(spacing: 0) {
                    safetyBanner

                    ScrollViewReader { proxy in
                        ScrollView(showsIndicators: false) {
                            VStack(alignment: .leading, spacing: MMSpacing.lg) {
                                recentSessionsStrip
                                quickPromptStrip

                                ForEach(vm.messages) { message in
                                    messageBubble(message)
                                        .id(message.id)
                                }

                                if vm.isProcessing {
                                    typingBubble
                                }
                            }
                            .padding(.horizontal, MMSpacing.lg)
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
                }

                composer
            }
            .navigationTitle(t.premiumChatTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbar {
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

    private var safetyBanner: some View {
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
                    .font(MMFont.body(13))
                    .foregroundStyle(.mmTextMuted)
                    .lineSpacing(3)
            }
        }
        .padding(.horizontal, MMSpacing.lg)
        .padding(.top, MMSpacing.md)
    }

    @ViewBuilder
    private var recentSessionsStrip: some View {
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
                                .frame(width: 188, alignment: .leading)
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

    private var quickPromptStrip: some View {
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
    private func messageBubble(_ message: SupportChatMessage) -> some View {
        HStack {
            if message.role == .assistant {
                bubble(message.text, isAssistant: true)
                Spacer(minLength: 40)
            } else {
                Spacer(minLength: 40)
                bubble(message.text, isAssistant: false)
            }
        }
    }

    private var typingBubble: some View {
        HStack {
            bubble(t.supportTyping, isAssistant: true)
            Spacer(minLength: 40)
        }
        .transition(.opacity)
    }

    private func bubble(_ text: String, isAssistant: Bool) -> some View {
        Text(text)
            .font(MMFont.body(14))
            .foregroundStyle(isAssistant ? .mmTextPrimary : Color.white)
            .lineSpacing(4)
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(isAssistant ? Color.mmCard.opacity(0.96) : Color.mmAccent)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .strokeBorder(isAssistant ? Color.mmBorderStrong : Color.mmAccent.opacity(0.18), lineWidth: 1)
                    )
            )
    }

    private var composer: some View {
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
            .padding(.horizontal, MMSpacing.lg)
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
