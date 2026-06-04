import Foundation

enum AIError: Error, LocalizedError {
    case invalidURL
    case noAPIKey
    case networkError(String)
    case decodingError
    case emptyResponse
    
    var errorDescription: String? {
        switch self {
        case .invalidURL: return "Invalid Gemini API URL."
        case .noAPIKey: return "API Key is missing. Please configure it in Settings."
        case .networkError(let message): return "Network error: \(message)"
        case .decodingError: return "Failed to process the response from AI."
        case .emptyResponse: return "AI returned an empty response. Please try again."
        }
    }
}

struct GeminiRequest: Codable {
    struct Content: Codable {
        struct Part: Codable {
            let text: String
        }
        let role: String?
        let parts: [Part]
    }
    let contents: [Content]
    let generationConfig: GenerationConfig?
    
    struct GenerationConfig: Codable {
        let temperature: Double?
        let topP: Double?
        let maxOutputTokens: Int?
    }
}

struct GeminiResponse: Codable {
    struct Candidate: Codable {
        struct Content: Codable {
            struct Part: Codable {
                let text: String
            }
            let parts: [Part]
        }
        let content: Content?
    }
    let candidates: [Candidate]?
    
    struct ErrorDetail: Codable {
        let message: String?
        let status: String?
    }
    let error: ErrorDetail?
}

final class AIService {
    static let shared = AIService()
    
    static let defaultAPIKey = ""
    
    private init() {}
    
    private var apiKey: String {
        UserDefaults.standard.string(forKey: "gemini_api_key") ?? AIService.defaultAPIKey
    }
    
    private let systemPrompt = """
    You are StudyFlow AI, an intelligent study assistant embedded in a student productivity app. \
    Your role is to help students learn effectively through summaries, quizzes, flashcards, concept explanations, and study planning advice. \
    
    CRITICAL FORMATTING RULES:
    1. NEVER use LaTeX mathematical notation (do NOT use $, $$, \\text{}, \\vec{}, \\frac{}, etc.). Instead, write equations and units in plain text (e.g., use '5 kg' instead of '$5\\text{ kg}$', '15 N' instead of '$15\\text{ N}$', 'a = F/m' instead of '$a=\\vec{F}/m$', 'm/s²' or 'm/s^2' instead of '$m/s^2$').
    2. Do NOT use markdown headers (like #, ##, ###). Instead, use bold text on a new line (e.g. '**Quick Quiz**') to separate sections.
    3. Use standard bullet points ('•') or numbered lists instead of raw markdown asterisks ('*') for lists to ensure clean rendering.
    4. Keep responses well-structured, using bold (**text**) for emphasis, and make sure there are clean line breaks between paragraphs.
    
    Be concise, encouraging, and academically rigorous. \
    When generating quizzes, always include the correct answer with a brief explanation. \
    When summarizing notes, highlight key takeaways and suggest review strategies.
    """
    
    private func cleanLaTeX(_ text: String) -> String {
        var result = text
        
        // Match \text{content} and replace with content
        if let regex = try? NSRegularExpression(pattern: #"\\text\{([^}]+)\}"#, options: []) {
            let range = NSRange(result.startIndex..<result.endIndex, in: result)
            result = regex.stringByReplacingMatches(in: result, options: [], range: range, withTemplate: "$1")
        }
        
        // Match \vec{content} and replace with content
        if let regex = try? NSRegularExpression(pattern: #"\\vec\{([^}]+)\}"#, options: []) {
            let range = NSRange(result.startIndex..<result.endIndex, in: result)
            result = regex.stringByReplacingMatches(in: result, options: [], range: range, withTemplate: "$1")
        }
        
        // Remove all $ symbols
        result = result.replacingOccurrences(of: "$", with: "")
        
        return result
    }
    
    func generateContent(prompt: String) async throws -> String {
        let key = apiKey
        guard !key.isEmpty else {
            throw AIError.noAPIKey
        }
        
        guard let url = URL(string: "https://generativelanguage.googleapis.com/v1beta/models/gemini-3.5-flash:generateContent?key=\(key)") else {
            throw AIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 30
        
        let body = GeminiRequest(
            contents: [
                GeminiRequest.Content(
                    role: "user",
                    parts: [
                        GeminiRequest.Content.Part(text: "\(systemPrompt)\n\nUser request: \(prompt)")
                    ]
                )
            ],
            generationConfig: GeminiRequest.GenerationConfig(
                temperature: 0.7,
                topP: 0.95,
                maxOutputTokens: 2048
            )
        )
        
        request.httpBody = try JSONEncoder().encode(body)
        
        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch let urlError as URLError {
            switch urlError.code {
            case .notConnectedToInternet, .networkConnectionLost:
                throw AIError.networkError("No internet connection. Please check your network and try again.")
            case .timedOut:
                throw AIError.networkError("Request timed out. Please try again.")
            default:
                throw AIError.networkError(urlError.localizedDescription)
            }
        }
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AIError.networkError("Invalid server response.")
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            // Try to parse error message from API response
            if let geminiResponse = try? JSONDecoder().decode(GeminiResponse.self, from: data),
               let errorMsg = geminiResponse.error?.message {
                throw AIError.networkError("API Error: \(errorMsg)")
            }
            if let errorText = String(data: data, encoding: .utf8) {
                throw AIError.networkError("HTTP \(httpResponse.statusCode): \(errorText)")
            }
            throw AIError.networkError("HTTP Status \(httpResponse.statusCode)")
        }
        
        let geminiResponse = try JSONDecoder().decode(GeminiResponse.self, from: data)
        guard var text = geminiResponse.candidates?.first?.content?.parts.first?.text, !text.isEmpty else {
            throw AIError.emptyResponse
        }
        
        text = cleanLaTeX(text)
        return text
    }
    
    /// Generate content with study context for personalized responses
    func generateContentWithContext(prompt: String, taskCount: Int, habitStreak: Int, subjects: [String]) async throws -> String {
        let contextInfo = """
        [Student Context]
        - Active tasks: \(taskCount)
        - Best habit streak: \(habitStreak) days
        - Subjects: \(subjects.isEmpty ? "None registered yet" : subjects.joined(separator: ", "))
        """
        
        let enhancedPrompt = "\(contextInfo)\n\n\(prompt)"
        return try await generateContent(prompt: enhancedPrompt)
    }
}
