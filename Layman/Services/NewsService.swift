import Foundation

struct NewsService {
    private let config = AppConfig.shared

    func fetchArticles(
        forceRefresh: Bool = false,
        desiredCount: Int = 20,
        excludingIDs: Set<String> = []
    ) async throws -> [Article] {
        guard config.hasNewsAPI else {
            return Article.mocks
        }

        var collected: [Article] = []
        var unseen: [Article] = []
        var seenIDs = Set<String>()
        var nextPage: String?
        let basePages = Int(ceil(Double(desiredCount) / 10.0))
        let maxPages = max(1, min(excludingIDs.isEmpty ? 3 : 5, basePages + (excludingIDs.isEmpty ? 0 : 2)))

        for pageIndex in 0..<maxPages {
            var components = URLComponents(string: "https://newsdata.io/api/1/latest")
            var queryItems: [URLQueryItem] = [
                .init(name: "apikey", value: config.newsAPIKey),
                .init(name: "category", value: "business,technology"),
                .init(name: "language", value: "en"),
                .init(name: "q", value: "startup OR founder OR funding OR AI OR chips OR software"),
                .init(name: "prioritydomain", value: "top"),
                .init(name: "size", value: "10")
            ]

            if let nextPage {
                queryItems.append(.init(name: "page", value: nextPage))
            } else if forceRefresh && pageIndex == 0 {
                queryItems.append(.init(name: "removeduplicate", value: "1"))
            }

            components?.queryItems = queryItems

            guard let url = components?.url else { continue }

            var request = URLRequest(url: url)
            request.cachePolicy = forceRefresh ? .reloadIgnoringLocalCacheData : .useProtocolCachePolicy
            request.timeoutInterval = 30

            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
                if collected.isEmpty {
                    return Article.mocks
                }
                break
            }

            let payload = try JSONDecoder.supabase.decode(NewsResponse.self, from: data)
            let pageArticles = payload.results.compactMap { dto in
                dto.toArticle()
            }

            for article in pageArticles where !seenIDs.contains(article.id) {
                seenIDs.insert(article.id)
                collected.append(article)
                if !excludingIDs.contains(article.id) {
                    unseen.append(article)
                }
            }

            nextPage = payload.nextPage

            if (!excludingIDs.isEmpty && unseen.count >= desiredCount) ||
                (excludingIDs.isEmpty && collected.count >= desiredCount) ||
                nextPage == nil {
                break
            }
        }

        if !excludingIDs.isEmpty && !unseen.isEmpty {
            return Array(unseen.prefix(desiredCount))
        }

        return collected.isEmpty ? Article.mocks : Array(collected.prefix(desiredCount))
    }
}

private struct NewsResponse: Decodable {
    let results: [NewsArticleDTO]
    let nextPage: String?

    enum CodingKeys: String, CodingKey {
        case results
        case nextPage = "nextPage"
    }
}

private struct NewsArticleDTO: Decodable {
    let articleID: String?
    let title: String?
    let link: String?
    let description: String?
    let content: String?
    let imageURL: String?
    let sourceID: String?
    let sourceName: String?
    let pubDate: String?
    let category: [String]?

    enum CodingKeys: String, CodingKey {
        case articleID = "article_id"
        case title
        case link
        case description
        case content
        case imageURL = "image_url"
        case sourceID = "source_id"
        case sourceName = "source_name"
        case pubDate
        case category
    }

    func toArticle() -> Article? {
        guard let title, !title.isEmpty else { return nil }
        let cleanTitle = HeadlineFormatter.simplify(title)
        let source = sourceName ?? sourceID ?? "News Desk"
        let body = [description, content].compactMap { $0 }.joined(separator: " ")
        let cards = SummaryBuilder.makeCards(from: cleanTitle, source: source, text: body)
        let plain = cards.joined(separator: " ")
        let parsedDate = pubDate.flatMap(ISO8601DateFormatter().date(from:))

        return Article(
            id: articleID ?? UUID().uuidString,
            headline: cleanTitle,
            source: source,
            imageURL: imageURL.flatMap(URL.init(string:)),
            originalURL: link.flatMap(URL.init(string:)),
            publishedAt: parsedDate,
            summaryCards: cards,
            plainSummary: plain,
            rawDescription: description ?? "",
            rawContent: content ?? body,
            category: category?.first?.capitalized ?? "Business"
        )
    }
}

enum HeadlineFormatter {
    static func simplify(_ title: String) -> String {
        let cleaned = title
            .replacingOccurrences(of: ":", with: " ")
            .replacingOccurrences(of: "  ", with: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        let conversational = rewriteConversational(cleaned)
        let words = conversational.split(separator: " ")
        if words.count <= 9 && conversational.count <= 52 {
            return conversational
        }

        let shortened = words.prefix(9).joined(separator: " ")
        return String(shortened.prefix(52)).trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func rewriteConversational(_ title: String) -> String {
        let compact = title.replacingOccurrences(of: "\"", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
        let lower = compact.lowercased()

        if lower.contains(" raises ") || lower.contains(" raised ") {
            return swapPhrase(in: compact, matches: [" raises ", " raised "], replacement: " just raised ")
        }

        if lower.contains(" launches ") || lower.contains(" launched ") {
            return swapPhrase(in: compact, matches: [" launches ", " launched "], replacement: " just launched ")
        }

        if lower.contains(" unveils ") || lower.contains(" unveiled ") {
            return swapPhrase(in: compact, matches: [" unveils ", " unveiled "], replacement: " just showed off ")
        }

        if lower.contains(" rolls out ") {
            return swapPhrase(in: compact, matches: [" rolls out "], replacement: " is rolling out ")
        }

        if lower.contains(" expands ") || lower.contains(" expansion ") {
            return swapPhrase(in: compact, matches: [" expands ", " expansion "], replacement: " is pushing into ")
        }

        if compact.count <= 52 {
            return compact
        }

        let words = compact.split(separator: " ")
        if words.count >= 5 {
            let start = words.prefix(2).joined(separator: " ")
            let rest = words.dropFirst(2).joined(separator: " ")
            return "\(start) is making a big move with \(rest)"
        }

        return compact
    }

    private static func swapPhrase(in title: String, matches: [String], replacement: String) -> String {
        for match in matches {
            if let range = title.range(of: match, options: .caseInsensitive) {
                var updated = title.replacingCharacters(in: range, with: replacement)
                updated = updated.replacingOccurrences(of: "  ", with: " ")
                return updated.trimmingCharacters(in: .whitespacesAndNewlines)
            }
        }
        return title
    }
}

enum SummaryBuilder {
    static func makeCards(from headline: String, source: String, text: String) -> [String] {
        let sentences = splitIntoSentences(text)
        var cards: [String] = []
        var index = 0

        while cards.count < 3 {
            let seed = [
                sentences[safe: index],
                sentences[safe: index + 1]
            ]
            .compactMap { $0 }
            .joined(separator: " ")

            let fallback = fallbackSentence(headline: headline, source: source, index: cards.count)
            let raw = seed.isEmpty ? fallback : seed
            cards.append(normalizeCard(raw, fallback: fallback))
            index += 2
        }

        return cards
    }

    static func suggestions(for article: Article) -> [String] {
        let fragments = article.headline.split(separator: " ").prefix(3).joined(separator: " ")
        return [
            "Why does this story matter?",
            "What should I watch next with \(fragments)?",
            "Explain this like I'm new to it"
        ]
    }

    private static func splitIntoSentences(_ text: String) -> [String] {
        text
            .replacingOccurrences(of: "\n", with: " ")
            .split(whereSeparator: { ".!?".contains($0) })
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .map { "\($0)." }
    }

    private static func normalizeCard(_ raw: String, fallback: String) -> String {
        var words = raw.split(separator: " ").map(String.init)
        if words.count < 28 {
            words += fallback.split(separator: " ").map(String.init)
        }
        if words.count > 35 {
            words = Array(words.prefix(35))
        }
        let sentence = words.joined(separator: " ")
        if sentence.contains(".") {
            return sentence
        }
        return sentence + "."
    }

    private static func fallbackSentence(headline: String, source: String, index: Int) -> String {
        let variants = [
            "\(headline) is getting attention because it points to where money and momentum are moving right now. \(source) frames it as a bigger market signal, not just a one day headline.",
            "The simple version is that this story shows a company trying to grow faster in a crowded market. People are watching to see whether the plan actually turns into revenue, users, or leverage.",
            "For regular readers, the point is not every detail but the shift underneath it. This could affect prices, competition, hiring, or how quickly similar startups try the same move."
        ]
        return variants[index % variants.count]
    }
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        guard indices.contains(index) else { return nil }
        return self[index]
    }
}
