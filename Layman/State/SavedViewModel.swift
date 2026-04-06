import Foundation

@MainActor
final class SavedViewModel: ObservableObject {
    @Published var articles: [Article] = []
    @Published var searchText = ""
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let savedService = SavedArticlesService()

    var filteredArticles: [Article] {
        guard !searchText.isEmpty else { return articles }
        return articles.filter {
            $0.headline.localizedCaseInsensitiveContains(searchText) ||
            $0.source.localizedCaseInsensitiveContains(searchText)
        }
    }

    func load(session: UserSession?) async {
        guard let session else {
            articles = []
            return
        }

        guard !isLoading else { return }
        isLoading = true
        defer { isLoading = false }

        do {
            articles = try await savedService.fetchSavedArticles(session: session)
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func remove(article: Article, session: UserSession?) async {
        guard let session else { return }
        do {
            try await savedService.delete(article: article, session: session)
            articles.removeAll { $0.id == article.id }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
