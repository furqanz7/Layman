import Foundation

struct AIService {
    private let config = AppConfig.shared

    func answer(question: String, for article: Article) async throws -> String {
        guard config.hasAI else {
            return "Add an AI key in `Secrets.plist` to enable real answers. For now, this story is mainly about \(article.plainSummary.lowercased())."
        }

        switch config.aiProvider {
        case .gemini:
            return try await askGemini(question: question, article: article)
        case .openAICompatible:
            return try await askOpenAICompatible(question: question, article: article)
        }
    }

    private func askOpenAICompatible(question: String, article: Article) async throws -> String {
        guard let baseURL = config.aiBaseURL else {
            throw APIError.missingConfiguration("Missing AI base URL.")
        }

        let url = baseURL.appending(path: "/chat/completions")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(config.aiAPIKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let payload = OpenAIRequest(
            model: config.aiModel,
            messages: [
                .init(role: "system", content: "You are Layman, a casual news explainer. Answer using one or two short sentences. Use simple everyday language and stay grounded in the provided article context."),
                .init(role: "user", content: "Article context:\n\(article.chatContext)\n\nQuestion: \(question)")
            ]
        )

        request.httpBody = try JSONEncoder().encode(payload)
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw APIError.server("The AI service did not return a valid answer.")
        }

        guard (200...299).contains(http.statusCode) else {
            throw APIError.server(parseAIError(data: data, fallback: "The AI service did not return a valid answer."))
        }

        let decoded = try JSONDecoder().decode(OpenAIResponse.self, from: data)
        return decoded.choices.first?.message.content.trimmingCharacters(in: .whitespacesAndNewlines) ?? "I couldn't find a clear answer."
    }

    private func askGemini(question: String, article: Article) async throws -> String {
        guard let baseURL = config.aiBaseURL else {
            throw APIError.missingConfiguration("Missing Gemini base URL.")
        }

        let path = "/models/\(config.aiModel):generateContent?key=\(config.aiAPIKey)"
        let url = baseURL.appending(path: path)
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: [
            "contents": [[
                "parts": [[
                    "text": "You are Layman, a simple news explainer. Use one or two short sentences and everyday language.\n\nArticle context:\n\(article.chatContext)\n\nQuestion: \(question)"
                ]]
            ]]
        ])

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw APIError.server("The AI service did not return a valid answer.")
        }

        guard (200...299).contains(http.statusCode) else {
            throw APIError.server(parseGeminiError(data: data))
        }

        let decoded = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        let candidates = decoded?["candidates"] as? [[String: Any]]
        let content = candidates?.first?["content"] as? [String: Any]
        let parts = content?["parts"] as? [[String: Any]]
        let text = parts?.first?["text"] as? String
        return text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "I couldn't find a clear answer."
    }

    private func parseAIError(data: Data, fallback: String) -> String {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return fallback
        }
        return json["message"] as? String ?? fallback
    }

    private func parseGeminiError(data: Data) -> String {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let error = json["error"] as? [String: Any] else {
            return "The AI service did not return a valid answer."
        }

        let message = error["message"] as? String ?? "The AI service did not return a valid answer."
        if message.localizedCaseInsensitiveContains("quota") {
            return "The configured Gemini project has no available quota right now. Add quota or switch to another AI key to enable live answers."
        }
        return message
    }
}

private struct OpenAIRequest: Encodable {
    struct Message: Encodable {
        let role: String
        let content: String
    }

    let model: String
    let messages: [Message]
}

private struct OpenAIResponse: Decodable {
    struct Choice: Decodable {
        struct Message: Decodable {
            let content: String
        }

        let message: Message
    }

    let choices: [Choice]
}
