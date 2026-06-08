//
//  OnboardingView.swift
//  MoonPeek
//
//  First-launch screen that asks for a nickname.
//

import SwiftUI

struct OnboardingView: View {
    @AppStorage("userNickname") private var savedNickname: String = ""
    @AppStorage("hasOnboarded") private var hasOnboarded: Bool = false

    @State private var draft: String = ""
    @FocusState private var isFocused: Bool

    private var trimmed: String {
        draft.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var body: some View {
        ZStack {
            SpaceBackground()

            VStack(spacing: 22) {
                Spacer()

                Image(systemName: "moon.stars.fill")
                    .font(.system(size: 64, weight: .light))
                    .foregroundStyle(.primary)
                    .padding(18)
                    .glassEffect(.clear, in: Circle())

                VStack(spacing: 8) {
                    Text("Welcome to MoonPeek")
                        .font(.largeTitle.weight(.bold))
                        .foregroundStyle(.primary)
                        .multilineTextAlignment(.center)

                    Text("Your front-row seat to Artemis II.\nWhat should we call you?")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 32)

                TextField("Your nickname", text: $draft)
                    .focused($isFocused)
                    .textInputAutocapitalization(.words)
                    .autocorrectionDisabled()
                    .submitLabel(.go)
                    .onSubmit(finish)
                    .font(.title3)
                    .padding(16)
                    .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                    .padding(.horizontal, 32)

                Spacer()

                Button(action: finish) {
                    Label("Continue", systemImage: "arrow.right.circle.fill")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                }
                .buttonStyle(.glassProminent)
                .disabled(trimmed.isEmpty)
                .padding(.horizontal, 32)
                .padding(.bottom, 36)
            }
        }
        .onAppear {
            draft = savedNickname
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                isFocused = true
            }
        }
    }

    private func finish() {
        guard !trimmed.isEmpty else { return }
        savedNickname = trimmed
        withAnimation(.easeInOut(duration: 0.4)) {
            hasOnboarded = true
        }
    }
}

#Preview {
    OnboardingView()
}
