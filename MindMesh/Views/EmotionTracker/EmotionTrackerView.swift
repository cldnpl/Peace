import SwiftUI

struct EmotionTrackerView: View {
    @StateObject private var vm = EmotionViewModel()
    @State private var crownSelection = Double(MoodLevel.neutral.rawValue)

    var body: some View {
        NavigationStack {
            ZStack {
                AmbientBackground()

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: MMSpacing.xxxl) {
                        emotionSelector
                        noteField
                        logButton

                        if vm.showSuccess {
                            successBanner
                        }

                        weekStrip
                        energyChart
                    }
                    .padding(.bottom, 40)
                }
                .safeAreaPadding(.horizontal, MMSpacing.lg)
                .safeAreaPadding(.bottom, MMSpacing.md)
                .scrollDismissesKeyboard(.interactively)
                .mmCrownSelection($crownSelection, range: 0...Double(MoodLevel.allCases.count - 1))
            }
            .navigationTitle("Umore")
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(.hidden, for: .navigationBar)
            .sensoryFeedback(.selection, trigger: vm.selectedMood?.rawValue ?? -1)
            .sensoryFeedback(.success, trigger: vm.showSuccess) { _, newValue in
                newValue
            }
            .onAppear {
                crownSelection = Double(vm.selectedMood?.rawValue ?? MoodLevel.neutral.rawValue)
            }
            .onChange(of: crownSelection) { _, newValue in
                vm.selectedMood = MoodLevel(rawValue: Int(newValue.rounded()))
            }
            .onChange(of: vm.selectedMood?.rawValue ?? MoodLevel.neutral.rawValue) { _, newValue in
                crownSelection = Double(newValue)
            }
        }
    }

    private var emotionSelector: some View {
        VStack(alignment: .leading, spacing: MMSpacing.lg) {
            Text("Scegli la voce che ti somiglia di piu adesso.")
                .font(.system(size: 16))
                .foregroundStyle(.mmTextMuted)
                .lineSpacing(4)

            LazyVGrid(
                columns: [GridItem(.flexible(), spacing: MMSpacing.md), GridItem(.flexible(), spacing: MMSpacing.md)],
                spacing: MMSpacing.md
            ) {
                ForEach(MoodLevel.allCases) { mood in
                    Button {
                        withAnimation(.spring(response: 0.28, dampingFraction: 0.82)) {
                            vm.selectedMood = mood
                        }
                    } label: {
                        MoodCard(mood: mood, isSelected: vm.selectedMood == mood)
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.plain)
                }
            }

            if let selectedMood = vm.selectedMood {
                MMCard(
                    padding: MMSpacing.lg,
                    cornerRadius: MMRadius.md,
                    borderColor: selectedMood.color.opacity(0.16),
                    backgroundColor: selectedMood.color.opacity(0.08)
                ) {
                    Text(selectedMood.detail)
                        .font(.system(size: 14))
                        .foregroundStyle(.mmTextPrimary)
                        .lineSpacing(4)
                }
            }
        }
    }

    private var noteField: some View {
        VStack(alignment: .leading, spacing: 10) {
            MMSectionLabel(text: "Nota")

            TextField("Se vuoi, aggiungi una riga su com'e andata.", text: $vm.noteText, axis: .vertical)
                .font(.system(size: 14))
                .foregroundStyle(.mmTextPrimary)
                .lineLimit(3...5)
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

    private var logButton: some View {
        MMPrimaryButton(
            title: vm.hasLoggedToday ? "Aggiorna la giornata" : "Salva come stai",
            icon: "checkmark",
            gradient: .mmRoseGradient,
            glowColor: .mmRose
        ) {
            vm.logMood()
        }
        .disabled(vm.selectedMood == nil)
        .opacity(vm.selectedMood == nil ? 0.48 : 1)
    }

    private var successBanner: some View {
        MMCard(
            padding: MMSpacing.lg,
            cornerRadius: MMRadius.md,
            borderColor: Color.mmAccent3.opacity(0.18),
            backgroundColor: Color.mmAccent3.opacity(0.08)
        ) {
            HStack(spacing: 12) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 18))
                    .foregroundStyle(.mmAccent3)

                Text("Fatto! Tutto pronto.")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.mmTextPrimary)
            }
        }
        .transition(.move(edge: .top).combined(with: .opacity))
    }

    private var weekStrip: some View {
        MMCard(backgroundColor: Color.mmCard.opacity(0.88)) {
            VStack(alignment: .leading, spacing: MMSpacing.lg) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        MMSectionLabel(text: "Settimana")
                        Text("Il ritmo dei giorni")
                            .font(.system(size: 22, weight: .semibold, design: .rounded))
                            .foregroundStyle(.mmTextPrimary)
                    }

                    Spacer()

                    MMInlineBadge(title: "\(vm.loggedDaysThisMonth) registrazioni", icon: "calendar", tint: .mmAccent3)
                }

                HStack(spacing: 8) {
                    ForEach(vm.weekData, id: \.day) { item in
                        VStack(spacing: 8) {
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill((item.entry?.mood.color ?? Color.mmSurface).opacity(item.entry == nil ? 0.42 : 0.14))
                                .frame(height: 46)
                                .overlay(
                                    Image(systemName: item.entry?.mood.symbolName ?? "minus")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundStyle(item.entry?.mood.color ?? .mmTextDim)
                                )

                            Text(item.day)
                                .font(.system(size: 11, weight: .medium))
                                .foregroundStyle(.mmTextDim)
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
            }
        }
    }

    private var energyChart: some View {
        MMCard {
            VStack(alignment: .leading, spacing: MMSpacing.lg) {
                VStack(alignment: .leading, spacing: 4) {
                    MMSectionLabel(text: "Andamento")
                    Text("Come si muove l'energia")
                        .font(.system(size: 22, weight: .semibold, design: .rounded))
                        .foregroundStyle(.mmTextPrimary)
                }

                HStack(alignment: .bottom, spacing: 8) {
                    ForEach(vm.weekBarData, id: \.day) { bar in
                        VStack(spacing: 8) {
                            Spacer()

                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .fill(bar.color.opacity(bar.height <= 0.05 ? 0.55 : 1))
                                .frame(maxWidth: .infinity)
                                .frame(height: max(10, bar.height * 104))

                            Text(bar.day)
                                .font(.system(size: 10, weight: .medium))
                                .foregroundStyle(.mmTextDim)
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
                .frame(height: 128)
            }
        }
    }
}

private struct MoodCard: View {
    let mood: MoodLevel
    let isSelected: Bool

    var body: some View {
        MMCard(
            padding: MMSpacing.lg,
            cornerRadius: MMRadius.md,
            borderColor: isSelected ? mood.color.opacity(0.50) : Color.mmBorder,
            backgroundColor: isSelected ? Color.mmCard.opacity(0.98) : Color.mmCard.opacity(0.86)
        ) {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .top) {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(mood.color.opacity(isSelected ? 0.18 : 0.12))
                        .frame(width: 44, height: 44)
                        .overlay(
                            Image(systemName: mood.symbolName)
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundStyle(mood.color)
                        )

                    Spacer()

                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(mood.color)
                    }
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(mood.label)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.mmTextPrimary)

                    Text(mood.detail)
                        .font(.system(size: 12))
                        .foregroundStyle(.mmTextMuted)
                        .lineLimit(3)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .frame(minHeight: 128, alignment: .topLeading)
        }
        .frame(maxWidth: .infinity)
        .shadow(
            color: isSelected ? mood.color.opacity(0.16) : .clear,
            radius: isSelected ? 14 : 0,
            x: 0,
            y: 6
        )
    }
}

struct EmotionTrackerView_Previews: PreviewProvider {
    static var previews: some View {
        EmotionTrackerView()
    }
}
