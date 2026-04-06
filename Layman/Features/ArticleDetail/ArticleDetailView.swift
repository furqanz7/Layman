import SafariServices
import SwiftUI
import UIKit

struct ArticleDetailView: View {
    let article: Article
    let isSaved: Bool
    let onToggleSave: () async -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @State private var cardIndex = 0
    @State private var showBrowser = false
    @State private var showChat = false
    @State private var showShareSheet = false

    var body: some View {
        ZStack(alignment: .bottom) {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 16) {
                    topBar

                    Text(article.headline)
                        .font(.system(size: 24, weight: .bold))
                        .foregroundStyle(LaymanTheme.text(colorScheme))
                        .lineLimit(2)
                        .frame(maxWidth: .infinity, minHeight: 64, alignment: .leading)

                    RemoteImage(url: article.imageURL)
                        .frame(height: 188)
                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))

                    TabView(selection: $cardIndex) {
                        ForEach(Array(article.summaryCards.enumerated()), id: \.offset) { index, card in
                            SummaryCard(text: card).tag(index)
                        }
                    }
                    .frame(height: 220)
                    .tabViewStyle(.page(indexDisplayMode: .never))

                    HStack(spacing: 8) {
                        ForEach(0..<article.summaryCards.count, id: \.self) { index in
                            Circle()
                                .fill(index == cardIndex ? LaymanTheme.text(colorScheme) : LaymanTheme.text(colorScheme).opacity(0.16))
                                .frame(width: 7, height: 7)
                        }
                    }
                    .frame(maxWidth: .infinity)

                    Color.clear.frame(height: 92)
                }
                .padding(20)
            }

            VStack(spacing: 0) {
                Button {
                    showChat = true
                } label: {
                    Text("Ask Layman")
                        .font(.system(size: 17, weight: .bold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(LaymanTheme.accent)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                    .padding(.horizontal, 20)
                    .padding(.bottom, 10)
                }
                .background(LaymanTheme.background(colorScheme))
            }
        }
        .background(LaymanTheme.background(colorScheme))
        .ignoresSafeArea()
        .sheet(isPresented: $showBrowser) {
            if let url = article.originalURL {
                SafariSheet(url: url)
            }
        }
        .sheet(isPresented: $showShareSheet) {
            ShareSheet(items: shareItems)
        }
        .sheet(isPresented: $showChat) {
            AskLaymanView(article: article)
        }
    }

    private var topBar: some View {
        HStack(spacing: 14) {
            CircleIconButton(systemName: "chevron.left") {
                dismiss()
            }

            Spacer()

            CircleIconButton(systemName: "link") {
                showBrowser = true
            }
            CircleIconButton(systemName: isSaved ? "bookmark.fill" : "bookmark") {
                Task { await onToggleSave() }
            }
            CircleIconButton(systemName: "square.and.arrow.up") {
                showShareSheet = true
            }
        }
    }

    private var shareItems: [Any] {
        var items: [Any] = [article.headline]
        if let originalURL = article.originalURL {
            items.append(originalURL)
        }
        return items
    }
}

private struct SummaryCard: View {
    let text: String
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(text)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(LaymanTheme.text(colorScheme))
                .lineLimit(6)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 18)
        .background(LaymanTheme.card(colorScheme))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}

private struct SafariSheet: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: Context) -> SFSafariViewController {
        SFSafariViewController(url: url)
    }

    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {}
}

private struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
