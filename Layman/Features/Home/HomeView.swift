import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var theme: ThemeManager
    @Environment(\.colorScheme) private var colorScheme
    @StateObject private var viewModel = HomeViewModel()
    @State private var selectedArticle: Article?
    @State private var featureIndex = 0
    @State private var isSearchVisible = false
    @State private var isShowingAll = false
    private let carouselTimer = Timer.publish(every: 4.5, on: .main, in: .common).autoconnect()

    var body: some View {
        NavigationStack {
            ZStack {
                (theme.isNight ? Color(.systemGroupedBackground) : Color(red: 0.97, green: 0.95, blue: 0.92))
                    .ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 30) {
                        header
                        if isSearchVisible {
                            searchBar
                        }
                        if viewModel.isLoading && viewModel.allArticles.isEmpty {
                            loadingState
                        } else {
                            featuredCarousel
                            picksSection
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 10)
                    .padding(.bottom, 28)
                }
                .refreshable {
                    await viewModel.load(session: appState.session, force: true, desiredCount: 30)
                }
                .background(theme.isNight ? Color(.systemGroupedBackground) : Color(red: 0.97, green: 0.95, blue: 0.92))
                .navigationBarHidden(true)
                .sheet(item: $selectedArticle) { article in
                    ArticleDetailView(article: article, isSaved: viewModel.savedIDs.contains(article.id)) {
                        await viewModel.toggleSave(article: article, session: appState.session)
                    }
                }
                .navigationDestination(isPresented: $isShowingAll) {
                    AllArticlesView(viewModel: viewModel, selectedArticle: $selectedArticle, session: appState.session)
                }
                .task {
                    await viewModel.load(session: appState.session, desiredCount: 30)
                }
                .onReceive(carouselTimer) { _ in
                    guard !viewModel.featuredArticles.isEmpty else { return }
                    withAnimation(.spring(response: 0.42, dampingFraction: 0.88)) {
                        featureIndex = (featureIndex + 1) % viewModel.featuredArticles.count
                    }
                }
                .preferredColorScheme(theme.colorScheme)
            }
        }
    }

    private var header: some View {
        HStack(alignment: .center) {
            Text("Layman")
                .font(.system(size: 28, weight: .bold))
                .foregroundStyle(LaymanTheme.text(colorScheme))

            Spacer(minLength: 16)

            Button {
                withAnimation {
                    isSearchVisible.toggle()
                }
            } label: {
                ZStack {
                    Circle()
                        .fill(colorScheme == .dark ? Color(.secondarySystemBackground) : Color.white.opacity(0.92))
                        .frame(width: 34, height: 34)

                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(LaymanTheme.text(colorScheme).opacity(0.75))
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var searchBar: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(LaymanTheme.text(colorScheme).opacity(0.45))

            TextField("Search stories", text: $viewModel.searchText)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .foregroundStyle(LaymanTheme.text(colorScheme))
                .tint(LaymanTheme.accent)
        }
        .font(.system(size: 16, weight: .medium, design: .rounded))
        .padding(.horizontal, 18)
        .padding(.vertical, 16)
        .background(LaymanTheme.card(colorScheme))
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(LaymanTheme.text(colorScheme).opacity(0.12), lineWidth: 1)
        }
        .shadow(color: LaymanTheme.text(colorScheme).opacity(0.08), radius: 16, y: 8)
        .transition(.move(edge: .top).combined(with: .opacity))
    }

    private var featuredCarousel: some View {
        VStack(spacing: 12) {
            if viewModel.featuredArticles.isEmpty {
                FeaturedPlaceholderCard()
                    .frame(height: 170)
            } else {
                GeometryReader { proxy in
                    TabView(selection: $featureIndex) {
                        ForEach(Array(viewModel.featuredArticles.enumerated()), id: \.offset) { index, article in
                            Button {
                                Haptics.selection()
                                selectedArticle = article
                            } label: {
                                FeaturedCard(article: article)
                            }
                            .buttonStyle(.plain)
                            .frame(width: proxy.size.width, height: 170)
                            .tag(index)
                        }
                    }
                    .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                }
                .frame(height: 170)
            }

            HStack(spacing: 8) {
                ForEach(0..<max(viewModel.featuredArticles.count, 1), id: \.self) { index in
                    Capsule()
                        .fill(index == featureIndex ? LaymanTheme.text(colorScheme) : LaymanTheme.text(colorScheme).opacity(0.16))
                        .frame(width: index == featureIndex ? 16 : 6, height: 6)
                        .animation(.easeInOut(duration: 0.2), value: featureIndex)
                }
            }
        }
    }

    private var picksSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Today's Picks")
                    .font(.system(size: 23, weight: .bold, design: .rounded))
                    .foregroundStyle(LaymanTheme.text(colorScheme))
                Spacer()
                Button("View All") {
                        isShowingAll = true
                    }
                    .buttonStyle(.plain)
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundStyle(LaymanTheme.accent)
            }

            if let error = viewModel.errorMessage {
                Text(error)
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundStyle(.red)
            }

            if viewModel.filteredPicks.isEmpty {
                EmptyPicksState(hasSearchText: !viewModel.searchText.isEmpty)
            } else {
                ForEach(viewModel.filteredPicks) { article in
                    Button {
                        selectedArticle = article
                    } label: {
                        ArticleRow(article: article, isSaved: viewModel.savedIDs.contains(article.id))
                    }
                    .buttonStyle(.plain)
                    .contextMenu {
                        Button(viewModel.savedIDs.contains(article.id) ? "Remove Bookmark" : "Save") {
                            Task {
                                Haptics.impact(.light)
                                await viewModel.toggleSave(article: article, session: appState.session)
                            }
                        }
                    }
                }
            }
        }
    }

    private var loadingState: some View {
        VStack(spacing: 18) {
            FeaturedPlaceholderCard()
                .frame(height: 170)

            ForEach(0..<4, id: \.self) { _ in
                ArticleRowPlaceholder()
            }
        }
    }
}

private struct FeaturedCard: View {
    let article: Article

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            RemoteImage(url: article.imageURL)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .clipped()

            LinearGradient(
                colors: [.clear, .black.opacity(0.75)],
                startPoint: .center,
                endPoint: .bottom
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            VStack(alignment: .leading, spacing: 5) {
                Text(article.category.uppercased())
                    .font(.system(size: 10, weight: .bold))
                    .tracking(0.8)
                    .foregroundColor(.white.opacity(0.82))

                Text(article.headline)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
                    .lineLimit(2)

                Text(article.source)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.white.opacity(0.82))
                    .lineLimit(1)
            }
            .padding(.horizontal, 14)
            .padding(.bottom, 12)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 170)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

struct ArticleRow: View {
    let article: Article
    let isSaved: Bool
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        HStack(spacing: 14) {
            RemoteImage(url: article.imageURL)
                .frame(width: 58, height: 58)
                .clipShape(RoundedRectangle(cornerRadius: 12))

            VStack(alignment: .leading, spacing: 4) {
                Text(article.headline)
                    .font(.system(size: 13, weight: .semibold))
                    .lineLimit(2)
                    .foregroundStyle(LaymanTheme.text(colorScheme))

                Text(article.source)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(LaymanTheme.text(colorScheme).opacity(0.58))
                    .lineLimit(1)
            }

            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(LaymanTheme.card(colorScheme))
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }
}

private struct FeaturedPlaceholderCard: View {
    var body: some View {
        ZStack(alignment: .bottomLeading) {
            LinearGradient(
                colors: [LaymanTheme.peach, LaymanTheme.orange.opacity(0.85)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            VStack(alignment: .leading, spacing: 10) {
                Spacer()
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(.white.opacity(0.26))
                    .frame(width: 120, height: 16)
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(.white.opacity(0.18))
                    .frame(width: 180, height: 18)
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(.white.opacity(0.22))
                    .frame(width: 84, height: 12)
            }
            .padding(14)
        }
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

struct ArticleRowPlaceholder: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        HStack(spacing: 14) {
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .fill(LaymanTheme.card(colorScheme))
                .frame(width: 94, height: 94)

            VStack(alignment: .leading, spacing: 10) {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(LaymanTheme.card(colorScheme))
                    .frame(height: 16)
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(LaymanTheme.card(colorScheme))
                    .frame(width: 180, height: 16)
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(LaymanTheme.card(colorScheme).opacity(0.8))
                    .frame(width: 120, height: 12)
            }
            Spacer()
        }
        .padding(14)
        .background(LaymanTheme.card(colorScheme))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}

private struct EmptyPicksState: View {
    let hasSearchText: Bool
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: hasSearchText ? "magnifyingglass.circle" : "newspaper")
                .font(.system(size: 28, weight: .semibold))
                .foregroundStyle(LaymanTheme.accent)

            Text(hasSearchText ? "No stories matched your search." : "No stories available right now.")
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundStyle(LaymanTheme.text(colorScheme))

            Text(hasSearchText ? "Try a broader keyword." : "Pull to refresh later or check your API key.")
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundStyle(LaymanTheme.text(colorScheme).opacity(0.58))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 28)
        .padding(.horizontal, 20)
        .background(LaymanTheme.card(colorScheme))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(LaymanTheme.text(colorScheme).opacity(0.12), lineWidth: 1)
        }
    }
}

private struct AllArticlesView: View {
    @ObservedObject var viewModel: HomeViewModel
    @Binding var selectedArticle: Article?
    let session: UserSession?
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ZStack {
            LaymanTheme.background(colorScheme).ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 16) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Hot News")
                            .font(.system(size: 30, weight: .bold, design: .rounded))
                            .foregroundStyle(LaymanTheme.text(colorScheme))

                        Text("More business, tech, and startup stories in plain English.")
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundStyle(LaymanTheme.text(colorScheme).opacity(0.58))
                    }

                    if !AppConfig.shared.hasNewsAPI {
                        Text("Showing demo stories. Add your NewsData API key in Secrets.plist to load more.")
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                            .foregroundStyle(LaymanTheme.text(colorScheme).opacity(0.6))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(LaymanTheme.card(colorScheme))
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    }

                    if viewModel.allArticles.isEmpty {
                        EmptyPicksState(hasSearchText: false)
                    } else {
                        ForEach(viewModel.allArticles) { article in
                            Button {
                                selectedArticle = article
                            } label: {
                                ArticleRow(article: article, isSaved: viewModel.savedIDs.contains(article.id))
                            }
                            .buttonStyle(.plain)
                            .contextMenu {
                                Button(viewModel.savedIDs.contains(article.id) ? "Remove Bookmark" : "Save") {
                                    Task {
                                        Haptics.impact(.light)
                                        await viewModel.toggleSave(article: article, session: session)
                                    }
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 24)
                .padding(.bottom, 28)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .refreshable {
            await viewModel.load(session: session, force: true, desiredCount: 50)
        }
        .task {
            if viewModel.allArticles.count < 35 {
                await viewModel.load(session: session, desiredCount: 50)
            }
        }
    }
}

private extension Date {
    var relativeLaymanTimestamp: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: self, relativeTo: .now)
    }
}
