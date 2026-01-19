//
//  AIQuestionGeneratorService.swift
//  LTMS
//
//  AI-powered question generation service
//  Uses Google Gemini API (free tier available)

import Foundation
import Combine

/// Service for generating quiz questions using AI
@MainActor
class AIQuestionGeneratorService: ObservableObject {
    static let shared = AIQuestionGeneratorService()
    
    @Published var isGenerating = false
    @Published var generationProgress: String = ""
    
    private let apiKey: String
    // Groq API - Free tier: 30 requests/minute, 14,400 requests/day
    private let endpoint = "https://api.groq.com/openai/v1/chat/completions"
    private let model = "llama-3.3-70b-versatile" // Fast and powerful
    
    private init() {
        // Load API key from plist or use placeholder
        print("🔑 [AI Service] Initializing AI Question Generator Service...")
        
        if let path = Bundle.main.path(forResource: "AI-Config", ofType: "plist") {
            print("📄 [AI Service] Found AI-Config.plist at: \(path)")
            
            if let config = NSDictionary(contentsOfFile: path),
               let key = config["GROQ_API_KEY"] as? String {
                self.apiKey = key
                
                // Mask API key for security (show first 10 and last 4 chars)
                let maskedKey = key.count > 14 ? 
                    "\(key.prefix(10))...\(key.suffix(4))" : "***"
                print("✅ [AI Service] API key loaded successfully: \(maskedKey)")
                print("🔍 [AI Service] API key length: \(key.count) characters")
                print("🔍 [AI Service] API key starts with: \(key.prefix(6))")
            } else {
                self.apiKey = ""
                print("❌ [AI Service] Failed to read GROQ_API_KEY from plist")
            }
        } else {
            self.apiKey = ""
            print("❌ [AI Service] AI-Config.plist not found in bundle")
        }
    }
    
    // MARK: - Public Methods
    
    /// Generate quiz questions from lesson content
    func generateQuestions(
        from content: String,
        count: Int = 5,
        difficulty: QuestionDifficulty = .medium,
        quizId: String
    ) async throws -> [QuizQuestion] {
        print("\n🚀 [AI Service] Starting question generation...")
        print("📊 [AI Service] Parameters:")
        print("   - Question count: \(count)")
        print("   - Difficulty: \(difficulty.rawValue)")
        print("   - Quiz ID: \(quizId)")
        print("   - Content length: \(content.count) characters")
        
        guard !apiKey.isEmpty else {
            print("❌ [AI Service] API key is empty!")
            throw AIGeneratorError.apiKeyNotConfigured
        }
        print("✅ [AI Service] API key validation passed")
        
        isGenerating = true
        generationProgress = "Analyzing content..."
        defer { 
            isGenerating = false
            print("🏁 [AI Service] Generation process completed")
        }
        
        print("📝 [AI Service] Building prompt...")
        let prompt = buildPrompt(content: content, count: count, difficulty: difficulty)
        print("✅ [AI Service] Prompt built (\(prompt.count) characters)")
        
        generationProgress = "Generating questions with AI..."
        print("🌐 [AI Service] Calling Gemini API...")
        let response = try await callGeminiAPI(prompt: prompt)
        print("✅ [AI Service] Received response (\(response.count) characters)")
        
        generationProgress = "Processing results..."
        print("🔄 [AI Service] Parsing questions from response...")
        let questions = try parseQuestionsFromResponse(response, quizId: quizId)
        print("✅ [AI Service] Successfully parsed \(questions.count) questions")
        
        generationProgress = "Complete!"
        print("🎉 [AI Service] Question generation completed successfully!")
        return questions
    }
    
    /// Generate questions from lesson title and description (when no content available)
    func generateQuestionsFromTopic(
        topic: String,
        description: String?,
        count: Int = 5,
        difficulty: QuestionDifficulty = .medium,
        quizId: String
    ) async throws -> [QuizQuestion] {
        let content = """
        Topic: \(topic)
        \(description.map { "Description: \($0)" } ?? "")
        """
        return try await generateQuestions(from: content, count: count, difficulty: difficulty, quizId: quizId)
    }
    
    // MARK: - Private Methods
    
    private func buildPrompt(content: String, count: Int, difficulty: QuestionDifficulty) -> String {
        return """
        You are an expert educator creating quiz questions. Generate \(count) multiple-choice questions based on the following content.
        
        Difficulty Level: \(difficulty.rawValue)
        
        Content:
        \(content)
        
        Requirements:
        - Create \(count) multiple-choice questions
        - Each question should have exactly 4 options (A, B, C, D)
        - Only ONE option should be correct
        - Questions should be clear and unambiguous
        - Difficulty should be \(difficulty.rawValue)
        - Include a brief explanation for the correct answer
        
        Return ONLY a valid JSON array in this exact format (no markdown, no code blocks):
        [
          {
            "question": "Question text here?",
            "options": ["Option A", "Option B", "Option C", "Option D"],
            "correctAnswerIndex": 0,
            "explanation": "Brief explanation why this is correct",
            "points": 1
          }
        ]
        
        Important: Return ONLY the JSON array, nothing else. Do not wrap it in markdown code blocks.
        """
    }
    
    private func callGeminiAPI(prompt: String) async throws -> String {
        print("🔗 [AI Service] Preparing API request...")
        
        let maskedKey = apiKey.count > 14 ? 
            "\(apiKey.prefix(10))...\(apiKey.suffix(4))" : "***"
        print("🌐 [AI Service] Endpoint: \(endpoint)")
        print("🤖 [AI Service] Model: \(model)")
        print("🔑 [AI Service] Using API key: \(maskedKey)")
        
        guard let url = URL(string: endpoint) else {
            print("❌ [AI Service] Failed to create URL")
            throw AIGeneratorError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        print("✅ [AI Service] Request configured (POST)")
        
        // Groq uses OpenAI-compatible format
        let requestBody: [String: Any] = [
            "model": model,
            "messages": [
                [
                    "role": "user",
                    "content": prompt
                ]
            ],
            "temperature": 0.7,
            "max_tokens": 2048
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        print("📦 [AI Service] Request body size: \(request.httpBody?.count ?? 0) bytes")
        
        print("⏳ [AI Service] Sending request to Groq API...")
        let startTime = Date()
        let (data, response) = try await URLSession.shared.data(for: request)
        let duration = Date().timeIntervalSince(startTime)
        print("⏱️ [AI Service] Request completed in \(String(format: "%.2f", duration))s")
        
        guard let httpResponse = response as? HTTPURLResponse else {
            print("❌ [AI Service] Invalid response type")
            throw AIGeneratorError.invalidResponse
        }
        
        print("📡 [AI Service] HTTP Status Code: \(httpResponse.statusCode)")
        print("📊 [AI Service] Response size: \(data.count) bytes")
        
        guard httpResponse.statusCode == 200 else {
            let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
            print("❌ [AI Service] API Error (\(httpResponse.statusCode)):")
            print("📄 [AI Service] Error response: \(errorMessage)")
            throw AIGeneratorError.apiError(statusCode: httpResponse.statusCode, message: errorMessage)
        }
        
        print("✅ [AI Service] Successful response received")
        print("🔍 [AI Service] Parsing JSON response...")
        
        // Parse Groq/OpenAI-compatible response
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            print("❌ [AI Service] Failed to parse JSON")
            throw AIGeneratorError.invalidResponse
        }
        
        print("✅ [AI Service] JSON parsed successfully")
        print("🔍 [AI Service] Response keys: \(json.keys.joined(separator: ", "))")
        
        guard let choices = json["choices"] as? [[String: Any]] else {
            print("❌ [AI Service] No 'choices' field in response")
            throw AIGeneratorError.invalidResponse
        }
        print("✅ [AI Service] Found \(choices.count) choice(s)")
        
        guard let firstChoice = choices.first,
              let message = firstChoice["message"] as? [String: Any],
              let text = message["content"] as? String else {
            print("❌ [AI Service] Failed to extract text from response structure")
            throw AIGeneratorError.invalidResponse
        }
        
        print("✅ [AI Service] Extracted text (\(text.count) characters)")
        print("📝 [AI Service] Response preview: \(text.prefix(100))...")
        
        return text
    }
    
    private func parseQuestionsFromResponse(_ response: String, quizId: String) throws -> [QuizQuestion] {
        print("🔄 [AI Service] Starting response parsing...")
        print("📏 [AI Service] Raw response length: \(response.count) characters")
        
        // Clean the response - remove markdown code blocks if present
        var cleanedResponse = response.trimmingCharacters(in: .whitespacesAndNewlines)
        print("🧹 [AI Service] Trimmed whitespace")
        
        if cleanedResponse.hasPrefix("```json") {
            cleanedResponse = cleanedResponse.replacingOccurrences(of: "```json", with: "")
            print("🧹 [AI Service] Removed ```json wrapper")
        }
        if cleanedResponse.hasPrefix("```") {
            cleanedResponse = cleanedResponse.replacingOccurrences(of: "```", with: "")
            print("🧹 [AI Service] Removed ``` wrapper")
        }
        cleanedResponse = cleanedResponse.trimmingCharacters(in: .whitespacesAndNewlines)
        
        print("📏 [AI Service] Cleaned response length: \(cleanedResponse.count) characters")
        print("📝 [AI Service] Cleaned response preview: \(cleanedResponse.prefix(200))...")
        
        guard let data = cleanedResponse.data(using: .utf8) else {
            print("❌ [AI Service] Failed to convert response to data")
            throw AIGeneratorError.parsingFailed
        }
        
        struct AIQuestion: Codable {
            let question: String
            let options: [String]
            let correctAnswerIndex: Int
            let explanation: String?
            let points: Int?
        }
        
        print("🔍 [AI Service] Attempting to decode JSON...")
        do {
            let aiQuestions = try JSONDecoder().decode([AIQuestion].self, from: data)
            print("✅ [AI Service] Successfully decoded \(aiQuestions.count) questions")
            
            // Log each question
            for (index, q) in aiQuestions.enumerated() {
                print("   Question \(index + 1): \(q.question.prefix(50))...")
                print("      Options: \(q.options.count)")
                print("      Correct: \(q.correctAnswerIndex)")
            }
            
            // Convert to QuizQuestion models
            print("🔄 [AI Service] Converting to QuizQuestion models...")
            let questions = aiQuestions.enumerated().map { index, aiQ in
                QuizQuestion(
                    id: nil,
                    assessmentId: quizId,
                    questionText: aiQ.question,
                    questionType: "multiple_choice",
                    options: aiQ.options,
                    correctAnswer: aiQ.options[aiQ.correctAnswerIndex],
                    points: aiQ.points ?? 1,
                    orderIndex: index + 1,
                    createdAt: Date()
                )
            }
            
            print("✅ [AI Service] Conversion complete")
            return questions
        } catch {
            print("❌ [AI Service] JSON decoding failed: \(error)")
            print("📄 [AI Service] Failed to parse: \(cleanedResponse)")
            throw AIGeneratorError.parsingFailed
        }
    }
}

// MARK: - Supporting Types

enum QuestionDifficulty: String, CaseIterable {
    case easy = "Easy"
    case medium = "Medium"
    case hard = "Hard"
    
    var description: String {
        switch self {
        case .easy:
            return "Basic concepts and definitions"
        case .medium:
            return "Application and understanding"
        case .hard:
            return "Analysis and critical thinking"
        }
    }
}

enum AIGeneratorError: LocalizedError {
    case apiKeyNotConfigured
    case invalidURL
    case invalidResponse
    case apiError(statusCode: Int, message: String)
    case parsingFailed
    
    var errorDescription: String? {
        switch self {
        case .apiKeyNotConfigured:
            return "AI API key not configured. Please add your Gemini API key to AI-Config.plist"
        case .invalidURL:
            return "Invalid API URL"
        case .invalidResponse:
            return "Invalid response from AI service"
        case .apiError(let statusCode, let message):
            return "AI API Error (\(statusCode)): \(message)"
        case .parsingFailed:
            return "Failed to parse AI-generated questions"
        }
    }
}
