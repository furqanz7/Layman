import Foundation

@MainActor
final class ChatViewModel: ObservableObject {
    @Published var messages: [ChatMessage]
    @Published var draft = ""
    @Published var isSending = false
    let suggestions: [String]

    private let article: Article
    private let aiService = AIService()

    init(article: Article) {
        self.article = article
        self.suggestions = SummaryBuilder.suggestions(for: article)
        self.messages = [
            ChatMessage(role: .assistant, text: "Hi, I'm Layman! What can I answer for you?")
        ]
    }

    func send(_ question: String? = nil) async {
        let text = (question ?? draft).trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty, !isSending else { return }
        draft = ""
        isSending = true
        messages.append(ChatMessage(role: .user, text: text))

        do {
            let answer = try await aiService.answer(question: text, for: article)
            messages.append(ChatMessage(role: .assistant, text: answer))
        } catch {
            messages.append(ChatMessage(role: .assistant, text: error.localizedDescription))
        }

        isSending = false
    }
}
