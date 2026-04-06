import Foundation

struct Article: Identifiable, Codable, Equatable {
    let id: String
    let headline: String
    let source: String
    let imageURL: URL?
    let originalURL: URL?
    let publishedAt: Date?
    let summaryCards: [String]
    let plainSummary: String
    let rawDescription: String
    let rawContent: String
    let category: String

    var chatContext: String {
        [
            "Headline: \(headline)",
            "Source: \(source)",
            "Category: \(category)",
            "Summary: \(plainSummary)",
            rawContent
        ]
        .filter { !$0.isEmpty }
        .joined(separator: "\n")
    }

    static let mocks: [Article] = [
        Article(
            id: "1",
            headline: "This chip startup wants AI to run cheaper",
            source: "Mock Wire",
            imageURL: URL(string: "https://images.unsplash.com/photo-1518770660439-4636190af475?auto=format&fit=crop&w=1200&q=80"),
            originalURL: URL(string: "https://example.com/article-1"),
            publishedAt: .now,
            summaryCards: [
                "A small chip company says it found a way to make AI servers use less power and spend less money. That matters because running big models is still painfully expensive for most teams.",
                "The startup is pitching its hardware to cloud providers that need more speed without buying endless new machines. If it works, smaller AI products could launch faster and at lower prices.",
                "Investors like the idea because demand for AI computing is still climbing every quarter. The bigger question is whether the company can build enough hardware before larger rivals copy the approach."
            ],
            plainSummary: "A chip startup is promising cheaper AI computing for cloud companies.",
            rawDescription: "A chip startup says it can make AI workloads much cheaper.",
            rawContent: "A chip startup says it can lower the cost of AI computing by redesigning how workloads move through servers. The pitch is simple: less wasted power, more efficient performance, and a lower bill for companies training or serving large AI models.",
            category: "Technology"
        ),
        Article(
            id: "2",
            headline: "A fintech app is turning invoices into cash",
            source: "Mock Ledger",
            imageURL: URL(string: "https://images.unsplash.com/photo-1554224155-6726b3ff858f?auto=format&fit=crop&w=1200&q=80"),
            originalURL: URL(string: "https://example.com/article-2"),
            publishedAt: .now.addingTimeInterval(-7200),
            summaryCards: [
                "This startup lets small businesses get paid sooner instead of waiting weeks for invoices to clear. It fronts the money now, then collects the payment later for a fee.",
                "That can help companies cover payroll, rent, and supplier bills without taking a traditional bank loan. It is basically invoice factoring, but packaged like a clean modern app.",
                "The upside is faster cash flow for businesses that are growing but still tight on money. The risk is that bad customers or late payments can quickly make the model much harder to run."
            ],
            plainSummary: "A fintech startup is helping small businesses unlock invoice cash faster.",
            rawDescription: "The company advances invoice payments for a fee.",
            rawContent: "The company advances money against unpaid invoices and then collects from the end customer later. That gives small businesses quick working capital without a standard loan application.",
            category: "Business"
        )
    ]
}
