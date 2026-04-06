import SwiftUI

struct AskLaymanView: View {
    let article: Article
    @StateObject private var viewModel: ChatViewModel
    @EnvironmentObject private var theme: ThemeManager
    @Environment(\.colorScheme) private var colorScheme

    init(article: Article) {
        self.article = article
        _viewModel = StateObject(wrappedValue: ChatViewModel(article: article))
    }

    var body: some View {
        VStack(spacing: 18) {
            HStack {
                Text("Ask Layman")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(LaymanTheme.text(colorScheme))
                Spacer()
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(viewModel.suggestions, id: \.self) { suggestion in
                        Button(suggestion) {
                            Haptics.selection()
                            Task { await viewModel.send(suggestion) }
                        }
                        .font(.system(size: 14, weight: .semibold))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(LaymanTheme.accent.opacity(colorScheme == .dark ? 0.22 : 0.16))
                        .foregroundStyle(LaymanTheme.accent)
                        .clipShape(Capsule())
                    }
                }
            }

            ScrollViewReader { proxy in
                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(viewModel.messages) { message in
                            HStack(alignment: .bottom, spacing: 8) {
                                if message.role == .assistant {
                                    Image(systemName: "sparkle")
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundStyle(.white)
                                        .frame(width: 28, height: 28)
                                        .background(LaymanTheme.actionFill)
                                        .clipShape(Circle())
                                } else {
                                    Spacer(minLength: 36)
                                }

                                Text(message.text)
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundStyle(message.role == .assistant ? LaymanTheme.text(colorScheme) : Color.white)
                                    .padding(14)
                                    .background(message.role == .assistant ? LaymanTheme.card(colorScheme) : LaymanTheme.actionFill)
                                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))

                                if message.role == .user {
                                    Image(systemName: "person.fill")
                                        .font(.system(size: 13, weight: .bold))
                                        .foregroundStyle(.white)
                                        .frame(width: 28, height: 28)
                                        .background(LaymanTheme.accent)
                                        .clipShape(Circle())
                                } else {
                                    Spacer(minLength: 36)
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: message.role == .assistant ? .leading : .trailing)
                            .id(message.id)
                        }
                    }
                    .padding(.vertical, 8)
                }
                .onChange(of: viewModel.messages) { _, newValue in
                    guard let lastID = newValue.last?.id else { return }
                    withAnimation(.easeOut(duration: 0.25)) {
                        proxy.scrollTo(lastID, anchor: .bottom)
                    }
                }
                .onAppear {
                    if let lastID = viewModel.messages.last?.id {
                        proxy.scrollTo(lastID, anchor: .bottom)
                    }
                }
            }

            HStack(spacing: 12) {
                TextField("Type your question...", text: $viewModel.draft)
                    .padding(14)
                    .background(LaymanTheme.card(colorScheme))
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                    .foregroundStyle(LaymanTheme.text(colorScheme))
                    .tint(LaymanTheme.accent)
                    .submitLabel(.send)

                CircleIconButton(systemName: "mic.fill") {}
                CircleIconButton(systemName: viewModel.isSending ? "hourglass" : "arrow.up") {
                    Haptics.impact(.medium)
                    Task {
                        await viewModel.send()
                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                    }
                }
                .disabled(viewModel.isSending || viewModel.draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .opacity(viewModel.isSending || viewModel.draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.45 : 1)
            }

            Spacer(minLength: 0)
        }
        .padding(20)
        .background(LaymanTheme.background(colorScheme).ignoresSafeArea())
    }
}
