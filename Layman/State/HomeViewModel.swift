import Foundation

@MainActor
final class HomeViewModel: ObservableObject {
    @Published var allArticles: [Article] = []
    @Published var featuredArticles: [Article] = []
    @Published var searchText = ""
    @Published var savedIDs = Set<String>()
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let newsService = NewsService()
    private let savedService = SavedArticlesService()

    var filteredPicks: [Article] {
        let base = Array(allArticles.dropFirst(min(3, allArticles.count)))
        return filter(base.isEmpty ? allArticles : base)
    }

    func load(session: UserSession?, force: Bool = false, desiredCount: Int = 20) async {
        if isLoading {
            guard force else { return }
            while isLoading {
                await Task.yield()
            }
        }

        isLoading = true
        defer { isLoading = false }

        do {
            let previousIDs = Set(allArticles.map(\.id))
            let articles = try await newsService.fetchArticles(
                forceRefresh: force,
                desiredCount: desiredCount,
                excludingIDs: force ? previousIDs : []
            )

            if force, !previousIDs.isEmpty {
                let incomingIDs = Set(articles.map(\.id))
                let retained = allArticles.filter { !incomingIDs.contains($0.id) }
                allArticles = Array((articles + retained).prefix(desiredCount))
            } else {
                allArticles = articles
            }

            featuredArticles = Array(allArticles.prefix(3))
 
            if let session {
                let saved = try await savedService.fetchSavedArticles(session: session)
                savedIDs = Set(saved.map(\.id))
            }
            errorMessage = nil
        } catch {
            if isCancellation(error) {
                errorMessage = nil
                return
            }

            errorMessage = error.localizedDescription
        }
    }

    private func isCancellation(_ error: Error) -> Bool {
        if error is CancellationError {
            return true
        }

        if let urlError = error as? URLError, urlError.code == .cancelled {
            errorMessage = nil
            return true
        }

        let nsError = error as NSError
        return nsError.domain == NSURLErrorDomain && nsError.code == NSURLErrorCancelled
    }

    func toggleSave(article: Article, session: UserSession?) async {
        guard let session else { return }
        do {
            if savedIDs.contains(article.id) {
                try await savedService.delete(article: article, session: session)
                savedIDs.remove(article.id)
            } else {
                try await savedService.save(article: article, session: session)
                savedIDs.insert(article.id)
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func filter(_ articles: [Article]) -> [Article] {
        guard !searchText.isEmpty else { return articles }
        return articles.filter {
            $0.headline.localizedCaseInsensitiveContains(searchText) ||
            $0.source.localizedCaseInsensitiveContains(searchText) ||
            $0.category.localizedCaseInsensitiveContains(searchText)
        }
    }
}
