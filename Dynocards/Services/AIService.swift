//
//  AIService.swift
//  Dynocards
//
//  Created by User on 2024
//

import Foundation

struct WordDefinition: Equatable {
    let word: String
    let definition: String
    let shortDefinition: String
    let translation: String
    let example: String
    let phonetics: String
    let audioURL: String?
    let cefrLevel: String?
    let tags: [String]?
    
    static func == (lhs: WordDefinition, rhs: WordDefinition) -> Bool {
        return lhs.word == rhs.word &&
               lhs.definition == rhs.definition &&
               lhs.shortDefinition == rhs.shortDefinition &&
               lhs.translation == rhs.translation &&
               lhs.example == rhs.example &&
               lhs.phonetics == rhs.phonetics &&
               lhs.audioURL == rhs.audioURL &&
               lhs.cefrLevel == rhs.cefrLevel &&
               lhs.tags == rhs.tags
    }
}

enum ExamQuestionType {
    case definition
    case wordDifferent
    case wordSimilar
    case contextBased
    case fillInBlank
}

struct ExamQuestion {
    let question: String
    let options: [String]
    let correctAnswerIndex: Int
    let flashcard: Flashcard
    let questionType: ExamQuestionType
    let tip: String?
}

class AIService: ObservableObject {
    static let shared = AIService()
    
    private init() {}
    
    func generateFlashcard(word: String, sourceLanguage: String, targetLanguage: String) async throws -> WordDefinition {
        // Determine CEFR level first (async, can run in parallel)
        let cefrLevel = await determineCEFRLevel(word: word, sourceLanguage: sourceLanguage)
        
        // Try AI generation first, fall back to enhanced mock data
        do {
            print("🤖 Generating flashcard for '\(word)' using OpenAI API...")
            var definition = try await generateWithAI(word: word, sourceLanguage: sourceLanguage, targetLanguage: targetLanguage)
            // Suggest tags based on generated content
            let suggestedTags = await suggestTags(word: definition.word, definition: definition.definition, example: definition.example)
            // Update with determined CEFR level and tags
            return WordDefinition(
                word: definition.word,
                definition: definition.definition,
                shortDefinition: definition.shortDefinition,
                translation: definition.translation,
                example: definition.example,
                phonetics: definition.phonetics,
                audioURL: definition.audioURL,
                cefrLevel: cefrLevel,
                tags: suggestedTags
            )
        } catch {
            print("⚠️ OpenAI generation failed, using enhanced mock data: \(error)")
            var definition = try await generateEnhancedMockData(word: word, sourceLanguage: sourceLanguage, targetLanguage: targetLanguage)
            // Suggest tags based on generated content
            let suggestedTags = await suggestTags(word: definition.word, definition: definition.definition, example: definition.example)
            // Update with determined CEFR level and tags
            return WordDefinition(
                word: definition.word,
                definition: definition.definition,
                shortDefinition: definition.shortDefinition,
                translation: definition.translation,
                example: definition.example,
                phonetics: definition.phonetics,
                audioURL: definition.audioURL,
                cefrLevel: cefrLevel,
                tags: suggestedTags
            )
        }
    }
    
    private func generateWithAI(word: String, sourceLanguage: String, targetLanguage: String) async throws -> WordDefinition {
        // Use OpenAI API directly
        return try await callOpenAIAPI(word: word, sourceLanguage: sourceLanguage, targetLanguage: targetLanguage)
    }
    
    private func generateEnhancedMockData(word: String, sourceLanguage: String, targetLanguage: String) async throws -> WordDefinition {
        // Simulate AI processing time
        try await Task.sleep(nanoseconds: UInt64.random(in: 1_000_000_000...3_000_000_000))
        
        // Generate more realistic, contextual content
        let definition = generateContextualDefinition(for: word, language: sourceLanguage)
        let shortDef = generateContextualShortDefinition(for: word)
        let translation = generateContextualTranslation(for: word, to: targetLanguage)
        let example = generateContextualExample(for: word, language: sourceLanguage)
        let phonetics = generatePhonetics(for: word)
        
        return WordDefinition(
            word: word.capitalized,
            definition: definition,
            shortDefinition: shortDef,
            translation: translation,
            example: example,
            phonetics: phonetics,
            audioURL: nil,
            cefrLevel: nil,
            tags: nil
        )
    }
    
    private func getDefinition(for word: String, language: String) -> String {
        let definitions: [String: String] = [
            "hello": "A greeting used when meeting someone or starting a conversation",
            "book": "A written or printed work consisting of pages glued or sewn together along one side and bound in covers",
            "water": "A colorless, transparent, odorless liquid that forms the seas, lakes, rivers, and rain",
            "house": "A building for human habitation, especially one that consists of a ground floor and one or more upper storeys",
            "beautiful": "Pleasing the senses or mind aesthetically; having qualities that give great pleasure to see",
            "learn": "To acquire knowledge of or skill in something by study, experience, or being taught",
            "friend": "A person whom one knows and with whom one has a bond of mutual affection",
            "family": "A group consisting of parents and children living together in a household",
            "food": "Any nutritious substance that people or animals eat or drink to maintain life and growth",
            "love": "An intense feeling of deep affection or care for someone or something"
        ]
        
        return definitions[word.lowercased()] ?? "A \(language.lowercased()) word with specific meaning and usage in everyday communication"
    }
    
    private func getShortDefinition(for word: String) -> String {
        let shortDefs: [String: String] = [
            "hello": "greeting",
            "book": "written work",
            "water": "liquid",
            "house": "dwelling",
            "beautiful": "pleasing",
            "learn": "acquire knowledge",
            "friend": "companion",
            "family": "relatives",
            "food": "nourishment",
            "love": "affection"
        ]
        
        return shortDefs[word.lowercased()] ?? "concept"
    }
    
    private func getExample(for word: String, language: String) -> String {
        let examples: [String: String] = [
            "hello": "Hello, how are you today?",
            "book": "I'm reading an interesting book about history.",
            "water": "Please drink more water to stay hydrated.",
            "house": "Their house has a beautiful garden in the front.",
            "beautiful": "The sunset was absolutely beautiful tonight.",
            "learn": "Children learn new things every day at school.",
            "friend": "She is my best friend from college.",
            "family": "My family likes to have dinner together every Sunday.",
            "food": "The restaurant serves delicious Italian food.",
            "love": "I love spending time with my pets."
        ]
        
        return examples[word.lowercased()] ?? "The word '\(word)' is commonly used in \(language.lowercased()) sentences."
    }
    
    private func getTranslation(for word: String, to language: String) -> String {
        // Enhanced mock translations
        let mockTranslations: [String: [String: String]] = [
            "hello": [
                "Spanish": "hola", "French": "bonjour", "German": "hallo", 
                "Italian": "ciao", "Portuguese": "olá", "Chinese": "你好", 
                "Japanese": "こんにちは", "Korean": "안녕하세요", "Arabic": "مرحبا"
            ],
            "book": [
                "Spanish": "libro", "French": "livre", "German": "buch", 
                "Italian": "libro", "Portuguese": "livro", "Chinese": "书", 
                "Japanese": "本", "Korean": "책", "Arabic": "كتاب"
            ],
            "water": [
                "Spanish": "agua", "French": "eau", "German": "wasser", 
                "Italian": "acqua", "Portuguese": "água", "Chinese": "水", 
                "Japanese": "水", "Korean": "물", "Arabic": "ماء"
            ],
            "house": [
                "Spanish": "casa", "French": "maison", "German": "haus", 
                "Italian": "casa", "Portuguese": "casa", "Chinese": "房子", 
                "Japanese": "家", "Korean": "집", "Arabic": "منزل"
            ],
            "beautiful": [
                "Spanish": "hermoso", "French": "beau", "German": "schön", 
                "Italian": "bello", "Portuguese": "bonito", "Chinese": "美丽", 
                "Japanese": "美しい", "Korean": "아름다운", "Arabic": "جميل"
            ],
            "efficiency": [
                "Spanish": "eficiencia", "French": "efficacité", "German": "effizienz",
                "Italian": "efficienza", "Portuguese": "eficiência", "Chinese": "效率",
                "Japanese": "効率", "Korean": "효율성", "Arabic": "كفاءة"
            ],
            "learn": [
                "Spanish": "aprender", "French": "apprendre", "German": "lernen",
                "Italian": "imparare", "Portuguese": "aprender", "Chinese": "学习",
                "Japanese": "学ぶ", "Korean": "배우다", "Arabic": "يتعلم"
            ],
            "study": [
                "Spanish": "estudiar", "French": "étudier", "German": "studieren",
                "Italian": "studiare", "Portuguese": "estudar", "Chinese": "学习",
                "Japanese": "勉強する", "Korean": "공부하다", "Arabic": "يدرس"
            ]
        ]
        
        // Return actual translation or a simple fallback
        if let translation = mockTranslations[word.lowercased()]?[language] {
            return translation
        } else {
            // Simple fallback for unmapped words
            let fallbacks: [String: String] = [
                "Spanish": word.lowercased() + "a",
                "French": word.lowercased() + "e", 
                "German": word.lowercased(),
                "Italian": word.lowercased() + "o"
            ]
            return fallbacks[language] ?? word.lowercased()
        }
    }
    
    private func getPhonetics(for word: String) -> String {
        // Mock phonetics - in real app, use phonetics API
        let mockPhonetics: [String: String] = [
            "hello": "/həˈloʊ/",
            "book": "/bʊk/",
            "water": "/ˈwɔːtər/",
            "house": "/haʊs/",
            "beautiful": "/ˈbjuːtɪfəl/"
        ]
        
        return mockPhonetics[word.lowercased()] ?? "/ˈfəʊnɪks/"
    }
    
    // Bridge methods for new smart generation
    private func generateContextualDefinition(for word: String, language: String) -> String {
        let wordType = analyzeWordType(word)
        return generateSmartDefinition(word: word, type: wordType, language: language)
    }
    
    private func generateContextualShortDefinition(for word: String) -> String {
        let wordType = analyzeWordType(word)
        return generateSmartShortDefinition(word: word, type: wordType)
    }
    
    private func generateContextualTranslation(for word: String, to language: String) -> String {
        return getTranslation(for: word, to: language)
    }
    
    private func generateContextualExample(for word: String, language: String) -> String {
        let wordType = analyzeWordType(word)
        return generateSmartExample(word: word, type: wordType, language: language)
    }
    
    private func generatePhonetics(for word: String) -> String {
        return generateSmartPhonetics(word: word)
    }
    
    // MARK: - Subscription & Authentication
    
    private func hasActiveSubscription() async -> Bool {
        // For development, return true to allow all features
        // In production, uncomment the actual subscription check below
        return true
        
        /*
        // Check local subscription status first
        if let subscriptionStatus = UserDefaults.standard.object(forKey: "subscription_status") as? [String: Any],
           let expiryDate = subscriptionStatus["expiryDate"] as? Date,
           expiryDate > Date() {
            return true
        }
        
        // Verify with your backend
        do {
            return try await verifySubscriptionWithBackend()
        } catch {
            print("⚠️ Failed to verify subscription: \(error)")
            return false
        }
        */
    }
    
    private func verifySubscriptionWithBackend() async throws -> Bool {
        guard let url = URL(string: "https://api.dynocards.com/v1/subscription/verify") else {
            throw APIError.invalidURL
        }
        
        guard let authToken = getUserAuthToken() else {
            throw APIError.authenticationRequired
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")
        request.setValue("iOS", forHTTPHeaderField: "X-Platform")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200,
              let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let hasActiveSubscription = json["hasActiveSubscription"] as? Bool else {
            return false
        }
        
        // Cache the result locally
        if hasActiveSubscription,
           let subscriptionData = json["subscription"] as? [String: Any],
           let expiryDateString = subscriptionData["expiryDate"] as? String {
            let formatter = ISO8601DateFormatter()
            if let expiryDate = formatter.date(from: expiryDateString) {
                UserDefaults.standard.set([
                    "expiryDate": expiryDate,
                    "plan": subscriptionData["plan"] ?? "premium"
                ], forKey: "subscription_status")
            }
        }
        
        return hasActiveSubscription
    }
    
    private func getUserAuthToken() -> String? {
        // Get stored authentication token
        return UserDefaults.standard.string(forKey: "auth_token")
    }
    
    private func getCurrentUserId() -> String? {
        // Get current user ID
        return UserDefaults.standard.string(forKey: "user_id")
    }
    

    
    private func callOpenAIAPI(word: String, sourceLanguage: String, targetLanguage: String) async throws -> WordDefinition {
        // Load configuration from Config.plist
        guard let configPath = Bundle.main.path(forResource: "Config", ofType: "plist"),
              let config = NSDictionary(contentsOfFile: configPath) else {
            throw APIError.invalidURL
        }
        
        guard let apiKey = config["OpenAI_API_Key"] as? String,
              let baseURL = config["OpenAI_Base_URL"] as? String,
              let model = config["OpenAI_Model"] as? String else {
            throw APIError.authenticationRequired
        }
        
        guard let url = URL(string: "\(baseURL)/chat/completions") else {
            throw APIError.invalidURL
        }
        
        // Create the prompt for OpenAI
        let prompt = createFlashcardPrompt(word: word, sourceLanguage: sourceLanguage, targetLanguage: targetLanguage)
        
        let requestBody: [String: Any] = [
            "model": model,
            "messages": [
                [
                    "role": "system",
                    "content": "You are an expert language tutor and vocabulary assistant. Generate comprehensive flashcard content for language learning."
                ],
                [
                    "role": "user",
                    "content": prompt
                ]
            ],
            "max_tokens": 500,
            "temperature": 0.7
        ]
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.networkError
        }
        
        print("🔗 OpenAI API Response Status: \(httpResponse.statusCode)")
        
        switch httpResponse.statusCode {
        case 200:
            break
        case 401:
            throw APIError.authenticationRequired
        case 429:
            throw APIError.rateLimited
        case 500...599:
            throw APIError.serverError
        default:
            throw APIError.invalidResponse
        }
        
        // Parse OpenAI response
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let choices = json["choices"] as? [[String: Any]],
              let firstChoice = choices.first,
              let message = firstChoice["message"] as? [String: Any],
              let content = message["content"] as? String else {
            throw APIError.decodingError
        }
        
        let result = try parseOpenAIResponse(content: content, word: word)
        print("✅ Successfully generated flashcard for '\(word)' using OpenAI")
        return result
    }
    
    private func createFlashcardPrompt(word: String, sourceLanguage: String, targetLanguage: String) -> String {
        return """
        Generate a comprehensive flashcard for the word "\(word)" in \(sourceLanguage) with translation to \(targetLanguage).
        
        Please provide the response in the following JSON format:
        {
            "word": "\(word)",
            "definition": "A clear, detailed definition in \(sourceLanguage)",
            "shortDefinition": "A brief, one-word or short phrase definition",
            "translation": "Translation to \(targetLanguage)",
            "example": "A natural example sentence using the word in context",
            "phonetics": "IPA phonetic transcription in /phonetics/ format"
        }
        
        Make sure the content is:
        - Educational and appropriate for language learning
        - Contextually relevant and natural
        - Accurate for the specified languages
        - Suitable for a flashcard format
        """
    }
    
    private func parseOpenAIResponse(content: String, word: String) throws -> WordDefinition {
        // Try to extract JSON from the response
        let jsonStart = content.range(of: "{")
        let jsonEnd = content.range(of: "}", options: .backwards)
        
        guard let start = jsonStart?.lowerBound,
              let end = jsonEnd?.upperBound else {
            throw APIError.decodingError
        }
        
        let jsonString = String(content[start..<end])
        
        guard let jsonData = jsonString.data(using: .utf8),
              let json = try JSONSerialization.jsonObject(with: jsonData) as? [String: Any] else {
            throw APIError.decodingError
        }
        
        // Parse tags from JSON if available
        let tags: [String]?
        if let tagsString = json["tags"] as? String {
            tags = tagsString.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespaces).lowercased() }.filter { !$0.isEmpty }
        } else if let tagsArray = json["tags"] as? [String] {
            tags = tagsArray.map { $0.lowercased() }
        } else {
            tags = nil
        }
        
        return WordDefinition(
            word: json["word"] as? String ?? word.capitalized,
            definition: json["definition"] as? String ?? "AI-generated definition",
            shortDefinition: json["shortDefinition"] as? String ?? "concept",
            translation: json["translation"] as? String ?? "translation",
            example: json["example"] as? String ?? "Example sentence",
            phonetics: json["phonetics"] as? String ?? "/phonetics/",
            audioURL: nil,
            cefrLevel: json["cefrLevel"] as? String,
            tags: tags
        )
    }

    private func callDynocardsAPI(word: String, sourceLanguage: String, targetLanguage: String) async throws -> WordDefinition {
        // Your backend API endpoint
        guard let url = URL(string: "https://api.dynocards.com/v1/generate-flashcard") else {
            throw APIError.invalidURL
        }
        
        // Get user's authentication token
        guard let authToken = getUserAuthToken() else {
            throw APIError.authenticationRequired
        }
        
        let requestBody: [String: Any] = [
            "word": word,
            "sourceLanguage": sourceLanguage,
            "targetLanguage": targetLanguage,
            "userId": getCurrentUserId() ?? "",
            "appVersion": Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        ]
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")
        request.setValue("iOS", forHTTPHeaderField: "X-Platform")
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.networkError
        }
        
        switch httpResponse.statusCode {
        case 200:
            // Success - parse the response
            break
        case 401:
            throw APIError.authenticationRequired
        case 402:
            throw APIError.subscriptionRequired
        case 429:
            throw APIError.rateLimited
        case 500...599:
            throw APIError.serverError
        default:
            throw APIError.invalidResponse
        }
        
        // Parse your backend response
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let success = json["success"] as? Bool,
              success,
              let flashcardData = json["data"] as? [String: Any] else {
            throw APIError.decodingError
        }
        
        // Parse tags from response if available
        let tags: [String]? = if let tagsString = flashcardData["tags"] as? String {
            tagsString.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespaces).lowercased() }.filter { !$0.isEmpty }
        } else if let tagsArray = flashcardData["tags"] as? [String] {
            tagsArray.map { $0.lowercased() }
        } else {
            nil
        }
        
        return WordDefinition(
            word: flashcardData["word"] as? String ?? word,
            definition: flashcardData["definition"] as? String ?? "AI-generated definition",
            shortDefinition: flashcardData["shortDefinition"] as? String ?? "concept",
            translation: flashcardData["translation"] as? String ?? "translation",
            example: flashcardData["example"] as? String ?? "Example sentence",
            phonetics: flashcardData["phonetics"] as? String ?? "/phonetics/",
            audioURL: flashcardData["audioURL"] as? String,
            cefrLevel: flashcardData["cefrLevel"] as? String,
            tags: tags
        )
    }
    
    // MARK: - Premium Features Check
    
    func isPremiumFeatureAvailable() async -> Bool {
        return await hasActiveSubscription()
    }
    
    func getSubscriptionStatus() -> (isActive: Bool, plan: String?, expiryDate: Date?) {
        guard let subscriptionStatus = UserDefaults.standard.object(forKey: "subscription_status") as? [String: Any] else {
            return (false, nil, nil)
        }
        
        let expiryDate = subscriptionStatus["expiryDate"] as? Date
        let plan = subscriptionStatus["plan"] as? String
        let isActive = expiryDate?.timeIntervalSinceNow ?? 0 > 0
        
        return (isActive, plan, expiryDate)
    }
    
    // MARK: - Exam Question Generation
    
    func generateExamQuestion(for flashcard: Flashcard, allFlashcards: [Flashcard]) async throws -> ExamQuestion {
        // Randomly select a question type
        let questionTypes: [ExamQuestionType] = [.definition, .wordDifferent, .wordSimilar, .contextBased, .fillInBlank]
        let selectedType = questionTypes.randomElement() ?? .definition
        
        // Try OpenAI API first, fall back to mock data
        do {
            return try await generateQuestionOfType(selectedType, for: flashcard, allFlashcards: allFlashcards)
        } catch {
            print("⚠️ OpenAI exam generation failed, using fallback: \(error)")
            return try await generateFallbackQuestion(for: flashcard, type: selectedType, allFlashcards: allFlashcards)
        }
    }
    
    private func generateQuestionOfType(_ type: ExamQuestionType, for flashcard: Flashcard, allFlashcards: [Flashcard]) async throws -> ExamQuestion {
        switch type {
        case .definition:
            return try await generateDefinitionQuestion(for: flashcard)
        case .wordDifferent:
            return try await generateWordDifferentQuestion(for: flashcard, allFlashcards: allFlashcards)
        case .wordSimilar:
            return try await generateWordSimilarQuestion(for: flashcard, allFlashcards: allFlashcards)
        case .contextBased:
            return try await generateContextBasedQuestion(for: flashcard)
        case .fillInBlank:
            return try await generateFillInBlankQuestion(for: flashcard)
        }
    }
    
    
    // MARK: - Question Type Generators
    
    private func generateDefinitionQuestion(for flashcard: Flashcard) async throws -> ExamQuestion {
        // Try OpenAI API first
        do {
            return try await generateDefinitionQuestionWithOpenAI(for: flashcard)
        } catch {
            print("⚠️ OpenAI definition question failed, using fallback: \(error)")
            return try await generateDefinitionFallback(for: flashcard)
        }
    }
    
    private func generateDefinitionQuestionWithOpenAI(for flashcard: Flashcard) async throws -> ExamQuestion {
        guard let configPath = Bundle.main.path(forResource: "Config", ofType: "plist"),
              let config = NSDictionary(contentsOfFile: configPath),
              let apiKey = config["OpenAI_API_Key"] as? String,
              let baseURL = config["OpenAI_Base_URL"] as? String,
              let model = config["OpenAI_Model"] as? String,
              let url = URL(string: "\(baseURL)/chat/completions") else {
            throw APIError.invalidURL
        }
        
        let prompt = """
        Create a multiple choice question asking for the meaning of the word "\(flashcard.word)".
        Definition: "\(flashcard.definition)"
        Example: "\(flashcard.example)"
        
        Response format (JSON only):
        {
            "question": "What is the meaning of '\(flashcard.word)'?",
            "options": ["correct definition", "wrong1", "wrong2", "wrong3"],
            "correctAnswerIndex": 0,
            "tip": "Short, concise tip (max 40 words) explaining the correct answer"
        }
        
        Requirements:
        - Exactly 4 options (no more, no less)
        - Tip must be under 40 words and concise
        """
        
        let requestBody: [String: Any] = [
            "model": model,
            "messages": [
                ["role": "system", "content": "You are an expert language tutor. Generate educational exam questions."],
                ["role": "user", "content": prompt]
            ],
            "max_tokens": 300,
            "temperature": 0.7
        ]
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        let (data, _) = try await URLSession.shared.data(for: request)
        
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let choices = json["choices"] as? [[String: Any]],
              let content = choices.first?["message"] as? [String: Any],
              let contentText = content["content"] as? String else {
            throw APIError.decodingError
        }
        
        return try parseQuestionResponse(content: contentText, flashcard: flashcard, type: .definition)
    }
    
    private func generateDefinitionFallback(for flashcard: Flashcard) async throws -> ExamQuestion {
        try await Task.sleep(nanoseconds: 500_000_000)
        
        let question = "What is the meaning of '\(flashcard.word)'?"
        let correctAnswer = flashcard.definition
        let wrongAnswers = generateWrongAnswers(for: flashcard)
        
        // Ensure exactly 4 options
        let wrongAnswersToUse = Array(wrongAnswers.prefix(3))
        var options = [correctAnswer] + wrongAnswersToUse
        if options.count < 4 {
            // Add more wrong answers if needed
            let additionalWrong = generateWrongAnswers(for: flashcard).filter { !options.contains($0) }
            options += additionalWrong.prefix(4 - options.count)
        }
        
        options.shuffle()
        let correctIndex = options.firstIndex(of: correctAnswer) ?? 0
        
        return ExamQuestion(
            question: question,
            options: options,
            correctAnswerIndex: correctIndex,
            flashcard: flashcard,
            questionType: .definition,
            tip: "'\(flashcard.word)' means: \(flashcard.shortDefinition)."
        )
    }
    
    private func generateWordDifferentQuestion(for flashcard: Flashcard, allFlashcards: [Flashcard]) async throws -> ExamQuestion {
        // Try AI first for better quality questions
        do {
            return try await generateWordDifferentWithAI(for: flashcard, allFlashcards: allFlashcards)
        } catch {
            // Fallback: Use definition-based questions instead of poor quality "different" questions
            return try await generateDefinitionFallback(for: flashcard)
        }
    }
    
    private func generateWordDifferentWithAI(for flashcard: Flashcard, allFlashcards: [Flashcard]) async throws -> ExamQuestion {
        guard let configPath = Bundle.main.path(forResource: "Config", ofType: "plist"),
              let config = NSDictionary(contentsOfFile: configPath),
              let apiKey = config["OpenAI_API_Key"] as? String,
              let baseURL = config["OpenAI_Base_URL"] as? String,
              let model = config["OpenAI_Model"] as? String,
              let url = URL(string: "\(baseURL)/chat/completions") else {
            throw APIError.invalidURL
        }
        
        // Get sample words for context
        let sampleWords = allFlashcards.prefix(10).map { "\($0.word): \($0.definition)" }.joined(separator: "; ")
        
        let prompt = """
        Create a "which word is different" question where '\(flashcard.word)' (meaning: \(flashcard.definition)) is the different word.
        
        Find 3 words from the user's collection that are similar to each other but different from '\(flashcard.word)':
        Available words: \(sampleWords)
        
        Response format (JSON only):
        {
            "question": "Which word is different from the rest?",
            "similarWords": ["word1", "word2", "word3"],
            "differentWord": "\(flashcard.word)",
            "options": ["\(flashcard.word)", "word1", "word2", "word3"],
            "correctAnswerIndex": 0,
            "tip": "Short, concise tip explaining why \(flashcard.word) is different (max 50 words)"
        }
        
        Requirements:
        - Exactly 4 options total
        - The 3 similar words should share a common theme/category
        - Tip must be under 50 words and concise
        """
        
        let requestBody: [String: Any] = [
            "model": model,
            "messages": [
                ["role": "system", "content": "You are a language expert creating educational exam questions. Generate high-quality 'word different' questions with clear, logical groupings."],
                ["role": "user", "content": prompt]
            ],
            "max_tokens": 400,
            "temperature": 0.7
        ]
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        let (data, _) = try await URLSession.shared.data(for: request)
        
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let choices = json["choices"] as? [[String: Any]],
              let content = choices.first?["message"] as? [String: Any],
              let contentText = content["content"] as? String else {
            throw APIError.decodingError
        }
        
        return try parseQuestionResponse(content: contentText, flashcard: flashcard, type: .wordDifferent)
    }
    
    private func generateWordSimilarQuestion(for flashcard: Flashcard, allFlashcards: [Flashcard]) async throws -> ExamQuestion {
        // Try AI first, then fallback
        do {
            return try await generateWordSimilarWithAI(for: flashcard, allFlashcards: allFlashcards)
        } catch {
            return try await generateWordSimilarFallback(for: flashcard, allFlashcards: allFlashcards)
        }
    }
    
    private func generateWordSimilarWithAI(for flashcard: Flashcard, allFlashcards: [Flashcard]) async throws -> ExamQuestion {
        guard let configPath = Bundle.main.path(forResource: "Config", ofType: "plist"),
              let config = NSDictionary(contentsOfFile: configPath),
              let apiKey = config["OpenAI_API_Key"] as? String,
              let baseURL = config["OpenAI_Base_URL"] as? String,
              let model = config["OpenAI_Model"] as? String,
              let url = URL(string: "\(baseURL)/chat/completions") else {
            throw APIError.invalidURL
        }
        
        // Get sample words for context
        let sampleWords = allFlashcards.prefix(5).map { "\($0.word): \($0.definition)" }.joined(separator: "; ")
        
        let prompt = """
        Find a word that is most similar (synonym or closely related) to "\(flashcard.word)" (meaning: \(flashcard.definition)).
        Available words: \(sampleWords)
        
        If no good synonym exists in the list, suggest one.
        Response format (JSON only):
        {
            "question": "Which word is most similar to '\(flashcard.word)'?",
            "similarWord": "synonym or similar word",
            "options": ["similar word", "unrelated1", "unrelated2", "unrelated3"],
            "correctAnswerIndex": 0,
            "tip": "Short, concise tip (max 40 words)"
        }
        
        Requirements:
        - Exactly 4 options (no more, no less)
        - Tip must be under 40 words
        """
        
        let requestBody: [String: Any] = [
            "model": model,
            "messages": [
                ["role": "system", "content": "You are a language expert. Find synonyms and related words."],
                ["role": "user", "content": prompt]
            ],
            "max_tokens": 300,
            "temperature": 0.7
        ]
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        let (data, _) = try await URLSession.shared.data(for: request)
        
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let choices = json["choices"] as? [[String: Any]],
              let content = choices.first?["message"] as? [String: Any],
              let contentText = content["content"] as? String else {
            throw APIError.decodingError
        }
        
        return try parseQuestionResponse(content: contentText, flashcard: flashcard, type: .wordSimilar)
    }
    
    private func generateWordSimilarFallback(for flashcard: Flashcard, allFlashcards: [Flashcard]) async throws -> ExamQuestion {
        let otherCards = allFlashcards.filter { $0.objectID != flashcard.objectID }
        let unrelatedWords = Array(otherCards.shuffled().prefix(3).map { $0.word })
        
        // Ensure exactly 4 options
        var options = [flashcard.word] + unrelatedWords
        if options.count < 4 && otherCards.count > 3 {
            let additionalWord = otherCards.dropFirst(3).first?.word ?? "word"
            options.append(additionalWord)
        }
        // Trim if more than 4
        options = Array(options.prefix(4))
        options.shuffle()
        let correctIndex = options.firstIndex(of: flashcard.word) ?? 0
        
        return ExamQuestion(
            question: "Which word is most similar to '\(flashcard.word)'?",
            options: options,
            correctAnswerIndex: correctIndex,
            flashcard: flashcard,
            questionType: .wordSimilar,
            tip: "Look for synonyms of '\(flashcard.word)' which means '\(flashcard.shortDefinition)'."
        )
    }
    
    private func generateContextBasedQuestion(for flashcard: Flashcard) async throws -> ExamQuestion {
        do {
            return try await generateContextBasedWithAI(for: flashcard)
        } catch {
            return try await generateContextBasedFallback(for: flashcard)
        }
    }
    
    private func generateContextBasedWithAI(for flashcard: Flashcard) async throws -> ExamQuestion {
        guard let configPath = Bundle.main.path(forResource: "Config", ofType: "plist"),
              let config = NSDictionary(contentsOfFile: configPath),
              let apiKey = config["OpenAI_API_Key"] as? String,
              let baseURL = config["OpenAI_Base_URL"] as? String,
              let model = config["OpenAI_Model"] as? String,
              let url = URL(string: "\(baseURL)/chat/completions") else {
            throw APIError.invalidURL
        }
        
        let prompt = """
        Create a context-based question for the word "\(flashcard.word)" (definition: "\(flashcard.definition)").
        
        Generate a scenario or situation where this word would be used.
        Response format (JSON only):
        {
            "question": "Which word would be used to say '[scenario]'?",
            "scenario": "short scenario description",
            "options": ["\(flashcard.word)", "wrong1", "wrong2", "wrong3"],
            "correctAnswerIndex": 0,
            "tip": "Short tip (max 40 words) explaining why this word fits"
        }
        
        Requirements:
        - Exactly 4 options (no more, no less)
        - Tip must be under 40 words and concise
        """
        
        let requestBody: [String: Any] = [
            "model": model,
            "messages": [
                ["role": "system", "content": "You create engaging context-based language questions."],
                ["role": "user", "content": prompt]
            ],
            "max_tokens": 350,
            "temperature": 0.8
        ]
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        let (data, _) = try await URLSession.shared.data(for: request)
        
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let choices = json["choices"] as? [[String: Any]],
              let content = choices.first?["message"] as? [String: Any],
              let contentText = content["content"] as? String else {
            throw APIError.decodingError
        }
        
        return try parseQuestionResponse(content: contentText, flashcard: flashcard, type: .contextBased)
    }
    
    private func generateContextBasedFallback(for flashcard: Flashcard) async throws -> ExamQuestion {
        let scenario = flashcard.example.isEmpty ? "In a situation where you need to express '\(flashcard.shortDefinition)'" : flashcard.example
        let question = "Which word would be used to say '\(scenario)'?"
        let wrongAnswers = ["alternative", "different", "another"]
        // Ensure exactly 4 options
        var options = [flashcard.word] + Array(wrongAnswers.prefix(3))
        options.shuffle()
        let correctIndex = options.firstIndex(of: flashcard.word) ?? 0
        
        return ExamQuestion(
            question: question,
            options: options,
            correctAnswerIndex: correctIndex,
            flashcard: flashcard,
            questionType: .contextBased,
            tip: "Use '\(flashcard.word)' (\(flashcard.shortDefinition)) in this scenario."
        )
    }
    
    private func generateFillInBlankQuestion(for flashcard: Flashcard) async throws -> ExamQuestion {
        do {
            return try await generateFillInBlankWithAI(for: flashcard)
        } catch {
            return try await generateFillInBlankFallback(for: flashcard)
        }
    }
    
    private func generateFillInBlankWithAI(for flashcard: Flashcard) async throws -> ExamQuestion {
        guard let configPath = Bundle.main.path(forResource: "Config", ofType: "plist"),
              let config = NSDictionary(contentsOfFile: configPath),
              let apiKey = config["OpenAI_API_Key"] as? String,
              let baseURL = config["OpenAI_Base_URL"] as? String,
              let model = config["OpenAI_Model"] as? String,
              let url = URL(string: "\(baseURL)/chat/completions") else {
            throw APIError.invalidURL
        }
        
        let prompt = """
        Create a fill-in-the-blank question for the word "\(flashcard.word)" (definition: "\(flashcard.definition)").
        Example: "\(flashcard.example)"
        
        Create a sentence where the word is replaced with "______" (underscore).
        Response format (JSON only):
        {
            "question": "Complete the sentence: '[sentence with ______]'",
            "sentence": "sentence with blank",
            "options": ["\(flashcard.word)", "wrong1", "wrong2", "wrong3"],
            "correctAnswerIndex": 0,
            "tip": "Short tip (max 40 words) explaining the correct word"
        }
        
        Requirements:
        - Exactly 4 options (no more, no less)
        - Tip must be under 40 words and concise
        """
        
        let requestBody: [String: Any] = [
            "model": model,
            "messages": [
                ["role": "system", "content": "You create fill-in-the-blank language exercises."],
                ["role": "user", "content": prompt]
            ],
            "max_tokens": 350,
            "temperature": 0.8
        ]
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        let (data, _) = try await URLSession.shared.data(for: request)
        
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let choices = json["choices"] as? [[String: Any]],
              let content = choices.first?["message"] as? [String: Any],
              let contentText = content["content"] as? String else {
            throw APIError.decodingError
        }
        
        return try parseQuestionResponse(content: contentText, flashcard: flashcard, type: .fillInBlank)
    }
    
    private func generateFillInBlankFallback(for flashcard: Flashcard) async throws -> ExamQuestion {
        let sentence: String
        if !flashcard.example.isEmpty {
            sentence = flashcard.example.replacingOccurrences(of: flashcard.word, with: "______")
        } else {
            sentence = "I need to ______ this task."
        }
        let question = "Complete the sentence: '\(sentence)'"
        let wrongAnswers = ["different", "other", "another"]
        // Ensure exactly 4 options
        var options = [flashcard.word] + Array(wrongAnswers.prefix(3))
        options.shuffle()
        let correctIndex = options.firstIndex(of: flashcard.word) ?? 0
        
        return ExamQuestion(
            question: question,
            options: options,
            correctAnswerIndex: correctIndex,
            flashcard: flashcard,
            questionType: .fillInBlank,
            tip: "Fill the blank with '\(flashcard.word)' (\(flashcard.shortDefinition))."
        )
    }
    
    private func generateFallbackQuestion(for flashcard: Flashcard, type: ExamQuestionType, allFlashcards: [Flashcard]) async throws -> ExamQuestion {
        switch type {
        case .definition:
            return try await generateDefinitionFallback(for: flashcard)
        case .wordDifferent:
            return try await generateWordDifferentQuestion(for: flashcard, allFlashcards: allFlashcards)
        case .wordSimilar:
            return try await generateWordSimilarFallback(for: flashcard, allFlashcards: allFlashcards)
        case .contextBased:
            return try await generateContextBasedFallback(for: flashcard)
        case .fillInBlank:
            return try await generateFillInBlankFallback(for: flashcard)
        }
    }
    
    private func parseQuestionResponse(content: String, flashcard: Flashcard, type: ExamQuestionType) throws -> ExamQuestion {
        let jsonStart = content.range(of: "{")
        let jsonEnd = content.range(of: "}", options: .backwards)
        
        guard let start = jsonStart?.lowerBound,
              let end = jsonEnd?.upperBound else {
            throw APIError.decodingError
        }
        
        let jsonString = String(content[start..<end])
        
        guard let jsonData = jsonString.data(using: .utf8),
              let json = try JSONSerialization.jsonObject(with: jsonData) as? [String: Any] else {
            throw APIError.decodingError
        }
        
        guard let question = json["question"] as? String,
              let optionsArray = json["options"] as? [String],
              let correctIndex = json["correctAnswerIndex"] as? Int else {
            throw APIError.decodingError
        }
        
        // Ensure exactly 4 options
        var options = optionsArray
        if options.count < 4 {
            // Add placeholder options if needed (shouldn't happen with AI)
            while options.count < 4 {
                options.append("Additional option")
            }
        } else if options.count > 4 {
            // Trim to 4 options if AI generated more
            options = Array(options.prefix(4))
        }
        
        // Limit tip length to ensure it displays fully (max 150 characters)
        var tip = json["tip"] as? String
        if let tipText = tip, tipText.count > 150 {
            // Truncate tip if too long
            tip = String(tipText.prefix(147)) + "..."
        }
        
        return ExamQuestion(
            question: question,
            options: options,
            correctAnswerIndex: min(correctIndex, options.count - 1), // Ensure valid index
            flashcard: flashcard,
            questionType: type,
            tip: tip
        )
    }
    
    
    private func generateWrongAnswers(for flashcard: Flashcard) -> [String] {
        // Generate plausible wrong answers based on the word
        let word = flashcard.word.lowercased()
        
        // Common wrong answers based on word patterns
        let wrongAnswers: [String] = [
            "A completely different concept",
            "The opposite meaning",
            "A related but incorrect definition",
            "A similar sounding word's meaning"
        ]
        
        // Add some contextual wrong answers
        var contextualWrong = wrongAnswers
        
        if word.contains("tech") || word.contains("digital") {
            contextualWrong.append("A traditional manual process")
            contextualWrong.append("A physical object")
        } else if word.contains("eco") || word.contains("green") {
            contextualWrong.append("A harmful environmental practice")
            contextualWrong.append("A man-made chemical")
        } else if word.contains("health") || word.contains("medical") {
            contextualWrong.append("A harmful medical condition")
            contextualWrong.append("A recreational activity")
        } else {
            contextualWrong.append("An unrelated concept")
            contextualWrong.append("A technical term")
        }
        
        // Return 3 random wrong answers
        return Array(contextualWrong.shuffled().prefix(3))
    }
    
    private func callLocalAI(prompt: String, word: String, sourceLanguage: String, targetLanguage: String) async throws -> WordDefinition {
        // Implement local AI or use alternative services like:
        // - Hugging Face Inference API
        // - Anthropic Claude
        // - Google Gemini
        // - Local LLM via Ollama
        
        // For now, use enhanced mock data that simulates AI responses
        return try await generateIntelligentMockData(word: word, sourceLanguage: sourceLanguage, targetLanguage: targetLanguage)
    }
    
    private func parseAIResponse(content: String, fallbackWord: String) throws -> WordDefinition {
        // Try to parse JSON response from AI
        guard let jsonData = content.data(using: .utf8),
              let json = try JSONSerialization.jsonObject(with: jsonData) as? [String: Any] else {
            throw APIError.decodingError
        }
        
        // Parse tags from JSON if available
        let tags: [String]?
        if let tagsString = json["tags"] as? String {
            tags = tagsString.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespaces).lowercased() }.filter { !$0.isEmpty }
        } else if let tagsArray = json["tags"] as? [String] {
            tags = tagsArray.map { $0.lowercased() }
        } else {
            tags = nil
        }
        
        return WordDefinition(
            word: json["word"] as? String ?? fallbackWord,
            definition: json["definition"] as? String ?? "AI-generated definition",
            shortDefinition: json["shortDefinition"] as? String ?? "concept",
            translation: json["translation"] as? String ?? "translation",
            example: json["example"] as? String ?? "Example sentence",
            phonetics: json["phonetics"] as? String ?? "/phonetics/",
            audioURL: nil,
            cefrLevel: json["cefrLevel"] as? String,
            tags: tags
        )
    }
    
    private func generateIntelligentMockData(word: String, sourceLanguage: String, targetLanguage: String) async throws -> WordDefinition {
        // Simulate AI processing
        try await Task.sleep(nanoseconds: UInt64.random(in: 1_500_000_000...3_000_000_000))
        
        // Generate more intelligent, context-aware content
        let wordType = analyzeWordType(word)
        let definition = generateSmartDefinition(word: word, type: wordType, language: sourceLanguage)
        let shortDef = generateSmartShortDefinition(word: word, type: wordType)
        let translation = generateSmartTranslation(word: word, to: targetLanguage, type: wordType)
        let example = generateSmartExample(word: word, type: wordType, language: sourceLanguage)
        let phonetics = generateSmartPhonetics(word: word)
        
        return WordDefinition(
            word: word.capitalized,
            definition: definition,
            shortDefinition: shortDef,
            translation: translation,
            example: example,
            phonetics: phonetics,
            audioURL: nil,
            cefrLevel: nil,
            tags: nil
        )
    }
}

enum APIError: Error {
    case invalidURL
    case noData
    case decodingError
    case invalidResponse
    case rateLimited
    case networkError
    case subscriptionRequired
    case authenticationRequired
    case serverError
    
    var localizedDescription: String {
        switch self {
        case .invalidURL:
            return "Invalid API URL"
        case .noData:
            return "No data received"
        case .decodingError:
            return "Failed to decode response"
        case .invalidResponse:
            return "Invalid server response"
        case .rateLimited:
            return "Too many requests. Please try again later."
        case .networkError:
            return "Network connection error"
        case .subscriptionRequired:
            return "Premium subscription required for AI features"
        case .authenticationRequired:
            return "Please sign in to use AI features"
        case .serverError:
            return "Server error. Please try again later."
        }
    }
}

enum WordType {
    case noun, verb, adjective, adverb, other
}

// MARK: - Tag Suggestion
extension AIService {
    func suggestTags(word: String, definition: String, example: String) async -> [String] {
        var suggestedTags: [String] = []
        
        let wordLower = word.lowercased()
        let definitionLower = definition.lowercased()
        let exampleLower = example.lowercased()
        let combinedText = "\(wordLower) \(definitionLower) \(exampleLower)"
        
        // Try AI-based tag suggestion first
        do {
            if let aiTags = try await suggestTagsWithAI(word: word, definition: definition, example: example) {
                suggestedTags = aiTags
                if !suggestedTags.isEmpty {
                    return Array(suggestedTags.prefix(5)) // Max 5 tags
                }
            }
        } catch {
            print("⚠️ AI tag suggestion failed: \(error)")
        }
        
        // Fallback to pattern-based tag detection
        suggestedTags = detectTagsFromPatterns(text: combinedText, word: wordLower)
        
        // Return max 5 tags, or default to empty (will use "All words" tag)
        return Array(suggestedTags.prefix(5))
    }
    
    private func suggestTagsWithAI(word: String, definition: String, example: String) async throws -> [String]? {
        // Check if OpenAI API key is available
        guard let apiKey = UserDefaults.standard.string(forKey: "openai_api_key"), !apiKey.isEmpty else {
            return nil
        }
        
        let prompt = """
        Analyze the following word and suggest 2-4 relevant tags (categories) for vocabulary learning.
        Word: "\(word)"
        Definition: "\(definition)"
        Example: "\(example)"
        
        Suggest tags like: business, academic, travel, food, technology, health, daily, formal, casual, etc.
        Return ONLY a comma-separated list of tags (e.g., "business, academic, formal"). No other text.
        """
        
        guard let url = URL(string: "https://api.openai.com/v1/chat/completions") else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let requestBody: [String: Any] = [
            "model": "gpt-3.5-turbo",
            "messages": [
                ["role": "system", "content": "You are a vocabulary learning assistant. Suggest relevant category tags for words. Return only comma-separated tags, nothing else."],
                ["role": "user", "content": prompt]
            ],
            "max_tokens": 50,
            "temperature": 0.5
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw APIError.invalidResponse
        }
        
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let choices = json["choices"] as? [[String: Any]],
              let firstChoice = choices.first,
              let message = firstChoice["message"] as? [String: Any],
              let content = message["content"] as? String else {
            throw APIError.decodingError
        }
        
        // Parse comma-separated tags
        let tags = content.trimmingCharacters(in: .whitespacesAndNewlines)
            .components(separatedBy: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() }
            .filter { !$0.isEmpty }
        
        return tags.isEmpty ? nil : tags
    }
    
    private func detectTagsFromPatterns(text: String, word: String) -> [String] {
        var tags: [String] = []
        
        // Business/Professional tags
        let businessKeywords = ["business", "company", "client", "revenue", "profit", "meeting", "strategy", "market", "corporate", "professional", "office", "workplace", "management"]
        if businessKeywords.contains(where: { text.contains($0) }) {
            tags.append("business")
        }
        
        // Academic tags
        let academicKeywords = ["research", "thesis", "hypothesis", "analysis", "study", "paper", "academic", "scholarly", "university", "education", "learning"]
        if academicKeywords.contains(where: { text.contains($0) }) {
            tags.append("academic")
        }
        
        // Travel tags
        let travelKeywords = ["airport", "hotel", "destination", "ticket", "flight", "journey", "travel", "trip", "vacation", "tourist", "luggage"]
        if travelKeywords.contains(where: { text.contains($0) }) {
            tags.append("travel")
        }
        
        // Food tags
        let foodKeywords = ["restaurant", "recipe", "ingredient", "cuisine", "meal", "cooking", "food", "dish", "kitchen", "dining"]
        if foodKeywords.contains(where: { text.contains($0) }) {
            tags.append("food")
        }
        
        // Technology tags
        let techKeywords = ["software", "application", "digital", "platform", "system", "technology", "computer", "internet", "device", "tech"]
        if techKeywords.contains(where: { text.contains($0) }) {
            tags.append("technology")
        }
        
        // Health tags
        let healthKeywords = ["medical", "health", "doctor", "treatment", "medicine", "hospital", "patient", "therapy", "disease"]
        if healthKeywords.contains(where: { text.contains($0) }) {
            tags.append("health")
        }
        
        // Formal tags (from CEFR or word complexity)
        if word.count > 8 || text.contains("formal") || text.contains("official") {
            tags.append("formal")
        }
        
        // Daily/Basic tags (simple common words)
        if word.count <= 5 && tags.isEmpty {
            tags.append("daily")
        }
        
        return tags
    }
}

// MARK: - CEFR Level Detection
extension AIService {
    func determineCEFRLevel(word: String, sourceLanguage: String) async -> String {
        // Try AI-based detection first
        do {
            let aiLevel = try await determineCEFRWithAI(word: word, sourceLanguage: sourceLanguage)
            if let level = aiLevel {
                return level
            }
        } catch {
            print("⚠️ AI CEFR determination failed: \(error)")
        }
        
        // Fallback to frequency-based estimation
        if let estimatedLevel = estimateCEFRByFrequency(word: word, language: sourceLanguage) {
            return estimatedLevel
        }
        
        // Fallback to common word lookup
        if let commonLevel = getCommonWordCEFRLevel(word: word, language: sourceLanguage) {
            return commonLevel
        }
        
        // Default to A1
        return "A1"
    }
    
    private func determineCEFRWithAI(word: String, sourceLanguage: String) async throws -> String? {
        // Check if OpenAI API key is available
        guard let apiKey = UserDefaults.standard.string(forKey: "openai_api_key"), !apiKey.isEmpty else {
            return nil
        }
        
        let prompt = """
        Determine the CEFR (Common European Framework of Reference) level for the word "\(word)" in \(sourceLanguage).
        Return ONLY one of the following levels: A1, A2, B1, B2, C1, C2
        Respond with just the level (e.g., "A1" or "B2"), nothing else.
        """
        
        guard let url = URL(string: "https://api.openai.com/v1/chat/completions") else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let requestBody: [String: Any] = [
            "model": "gpt-3.5-turbo",
            "messages": [
                ["role": "system", "content": "You are a language learning expert that classifies words by CEFR level. Respond with only the level (A1, A2, B1, B2, C1, or C2)."],
                ["role": "user", "content": prompt]
            ],
            "max_tokens": 10,
            "temperature": 0.3
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw APIError.invalidResponse
        }
        
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let choices = json["choices"] as? [[String: Any]],
              let firstChoice = choices.first,
              let message = firstChoice["message"] as? [String: Any],
              let content = message["content"] as? String else {
            throw APIError.decodingError
        }
        
        let level = content.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        
        // Validate the level
        let validLevels = ["A1", "A2", "B1", "B2", "C1", "C2"]
        if validLevels.contains(level) {
            return level
        }
        
        return nil
    }
    
    private func estimateCEFRByFrequency(word: String, language: String) -> String? {
        let wordLower = word.lowercased()
        let wordLength = wordLower.count
        let hasComplexSuffix = wordLower.hasSuffix("tion") || wordLower.hasSuffix("sion") || 
                               wordLower.hasSuffix("ment") || wordLower.hasSuffix("ness") ||
                               wordLower.hasSuffix("ity") || wordLower.hasSuffix("ous")
        
        // Simple heuristics based on word characteristics
        // Short, simple words are typically A1-A2
        if wordLength <= 4 {
            return wordLength <= 3 ? "A1" : "A2"
        }
        
        // Medium length words with common patterns: A2-B1
        if wordLength <= 6 && !hasComplexSuffix {
            return "A2"
        }
        
        // Longer words or words with complex suffixes: B1-B2
        if wordLength <= 8 {
            return hasComplexSuffix ? "B2" : "B1"
        }
        
        // Very long words or technical terms: C1-C2
        if wordLength <= 12 {
            return "C1"
        }
        
        return "C2"
    }
    
    private func getCommonWordCEFRLevel(word: String, language: String) -> String? {
        // Common English words by CEFR level
        // This is a simplified lookup - in production, use a comprehensive dictionary
        let commonWords: [String: [String]] = [
            "A1": ["hello", "goodbye", "yes", "no", "please", "thank", "sorry", "book", "water", "food", "house", "car", "friend", "family", "day", "night", "time", "year", "week", "month"],
            "A2": ["beautiful", "different", "important", "difficult", "easy", "happy", "sad", "tired", "hungry", "thirsty", "study", "learn", "understand", "remember", "forget"],
            "B1": ["achieve", "agree", "arrive", "believe", "compare", "complain", "describe", "discuss", "explain", "suggest", "appreciate", "consider", "decide", "develop", "discover"],
            "B2": ["analyze", "approach", "assume", "challenge", "characterize", "clarify", "comprehend", "conclude", "demonstrate", "establish", "evaluate", "examine", "illustrate", "indicate", "interpret"],
            "C1": ["accomplish", "acknowledge", "acquisition", "ambiguous", "analytical", "articulate", "comprehensive", "consolidate", "contemporary", "distinguished", "elaborate", "fundamental", "hypothesis", "methodology", "philosophical"],
            "C2": ["aberration", "abstruse", "ambivalent", "circumvent", "conundrum", "dichotomy", "ephemeral", "esoteric", "paradigm", "quintessential", "ubiquitous", "voracious"]
        ]
        
        let wordLower = word.lowercased()
        
        for (level, words) in commonWords.sorted(by: { $0.key < $1.key }) {
            if words.contains(wordLower) {
                return level
            }
        }
        
        return nil
    }
}

// MARK: - Smart Content Generation
extension AIService {
    private func analyzeWordType(_ word: String) -> WordType {
        let word = word.lowercased()
        
        // Common suffixes that indicate word types
        if word.hasSuffix("ing") || word.hasSuffix("ed") || word.hasSuffix("ate") || word.hasSuffix("ize") {
            return .verb
        } else if word.hasSuffix("ly") {
            return .adverb
        } else if word.hasSuffix("ful") || word.hasSuffix("ous") || word.hasSuffix("ive") || word.hasSuffix("able") {
            return .adjective
        } else if word.hasSuffix("tion") || word.hasSuffix("ness") || word.hasSuffix("ment") || word.hasSuffix("ity") {
            return .noun
        }
        
        // Common verbs
        let commonVerbs = ["run", "walk", "think", "learn", "study", "work", "play", "eat", "drink", "sleep"]
        if commonVerbs.contains(word) { return .verb }
        
        // Common adjectives
        let commonAdjectives = ["beautiful", "smart", "quick", "slow", "big", "small", "good", "bad", "happy", "sad"]
        if commonAdjectives.contains(word) { return .adjective }
        
        return .noun // Default to noun
    }
    
    private func generateSmartDefinition(word: String, type: WordType, language: String) -> String {
        let word = word.lowercased()
        
        // First check if we have a curated definition
        if let definition = getCuratedDefinition(for: word) {
            return definition
        }
        
        // Otherwise generate based on word type
        switch type {
        case .noun:
            return generateNounDefinition(word)
        case .verb:
            return generateVerbDefinition(word)
        case .adjective:
            return generateAdjectiveDefinition(word)
        case .adverb:
            return generateAdverbDefinition(word)
        case .other:
            return generateGenericDefinition(word)
        }
    }
    
    private func getCuratedDefinition(for word: String) -> String? {
        let definitions: [String: String] = [
            // Common vocabulary
            "efficiency": "The ability to accomplish a task with minimum wasted effort, time, or resources. It measures how well something converts inputs into useful outputs, often expressed as a ratio or percentage.",
            "innovation": "The process of creating new ideas, methods, or products that bring positive change or improvement. It involves turning creative concepts into practical solutions that add value.",
            "sustainability": "The practice of meeting present needs without compromising the ability of future generations to meet their own needs. It involves responsible use of resources and environmental protection.",
            "leadership": "The ability to guide, influence, and inspire others toward achieving common goals. It involves making decisions, taking responsibility, and motivating teams to perform effectively.",
            "creativity": "The use of imagination and original thinking to generate new ideas, solutions, or artistic expressions. It involves combining existing concepts in novel ways to produce something unique.",
            "technology": "The application of scientific knowledge and tools to solve practical problems and improve human life. It encompasses devices, systems, and methods used in various fields.",
            "communication": "The process of exchanging information, ideas, or feelings between individuals or groups through various means such as speech, writing, or body language.",
            "education": "The systematic process of acquiring knowledge, skills, values, and competencies through teaching, training, or research in formal or informal settings.",
            "environment": "The natural world and surroundings in which organisms live and interact, including air, water, soil, plants, animals, and their interconnected ecosystems.",
            "opportunity": "A favorable circumstance or chance that allows for advancement, progress, or achievement of goals. It represents a moment when conditions are right for action.",
            "challenge": "A difficult task or situation that requires effort, skill, and determination to overcome. It tests one's abilities and often leads to growth and learning.",
            "success": "The achievement of desired goals, objectives, or outcomes through effort, skill, and perseverance. It represents the favorable result of an endeavor or undertaking.",
            "knowledge": "Information, understanding, and skills acquired through experience, education, or investigation. It represents the accumulation of facts, concepts, and practical wisdom.",
            "experience": "The practical knowledge and skill gained through direct participation in events or activities over time. It encompasses both positive and negative encounters that shape understanding.",
            "development": "The process of growth, improvement, or advancement in skills, capabilities, or conditions. It involves progressive change toward a more advanced or mature state."
        ]
        
        return definitions[word]
    }
    
    private func generateNounDefinition(_ word: String) -> String {
        let contexts = getWordContext(word)
        
        if word.hasSuffix("ness") {
            let root = String(word.dropLast(4))
            return "The quality or state of being \(root). This noun describes the condition or characteristic that defines something as having the properties associated with \(contexts)."
        } else if word.hasSuffix("ment") {
            let root = String(word.dropLast(4))
            return "The action, process, or result of \(root)ing. This term refers to the outcome or state that results from activities related to \(contexts)."
        } else if word.hasSuffix("tion") || word.hasSuffix("sion") {
            return "The action, process, or state of doing something related to \(contexts). This noun represents a specific procedure or method used in various applications."
        } else if word.hasSuffix("ity") || word.hasSuffix("ty") {
            return "The quality, condition, or degree of something related to \(contexts). This characteristic defines the essential nature or properties of the subject."
        } else {
            return "A concept, object, or entity that relates to \(contexts). This term represents something tangible or abstract that plays a role in various situations and applications."
        }
    }
    
    private func generateVerbDefinition(_ word: String) -> String {
        let contexts = getWordContext(word)
        
        if word.hasSuffix("ize") || word.hasSuffix("ise") {
            let root = String(word.dropLast(3))
            return "To make something become \(root) or to cause a transformation related to \(contexts). This action involves implementing changes or improvements in specific areas."
        } else if word.hasSuffix("ate") {
            let root = String(word.dropLast(3))
            return "To perform an action that results in \(root) outcomes or effects related to \(contexts). This process involves systematic steps to achieve desired results."
        } else if word.hasSuffix("ing") {
            let root = String(word.dropLast(3))
            return "The ongoing action of \(root). This continuous process involves activities related to \(contexts) and can be performed over extended periods."
        } else {
            return "To perform an action or engage in an activity related to \(contexts). This verb describes a process that can be carried out to achieve specific goals or outcomes."
        }
    }
    
    private func generateAdjectiveDefinition(_ word: String) -> String {
        let templates = [
            "Describing something that has the quality of being",
            "An adjective used to characterize something as",
            "Having the characteristic or property of",
            "Used to describe the state or condition of being"
        ]
        
        let contexts = getWordContext(word)
        let template = templates.randomElement() ?? templates[0]
        return "\(template) \(contexts). This descriptive word helps provide more detail about nouns."
    }
    
    private func generateAdverbDefinition(_ word: String) -> String {
        return "An adverb that modifies verbs, adjectives, or other adverbs to describe how, when, where, or to what extent something is done. It adds detail and precision to the meaning of other words in a sentence."
    }
    
    private func generateGenericDefinition(_ word: String) -> String {
        let contexts = getWordContext(word)
        return "A word that relates to \(contexts) and is used in various contexts to convey specific meaning. This term has particular significance in communication and expression."
    }
    
    private func getWordContext(_ word: String) -> String {
        // Generate contextual meaning based on word patterns
        let word = word.lowercased()
        
        if word.contains("tech") || word.contains("digital") || word.contains("cyber") {
            return "technology and digital innovation"
        } else if word.contains("eco") || word.contains("green") || word.contains("sustain") {
            return "environmental sustainability and nature"
        } else if word.contains("health") || word.contains("medical") || word.contains("bio") {
            return "health, medicine, and biological processes"
        } else if word.contains("social") || word.contains("community") || word.contains("public") {
            return "social interaction and community engagement"
        } else if word.contains("business") || word.contains("market") || word.contains("economic") {
            return "business, economics, and professional activities"
        } else if word.contains("art") || word.contains("creative") || word.contains("design") {
            return "creativity, artistic expression, and design"
        } else {
            return "human experience and daily activities"
        }
    }
    
    private func generateSmartShortDefinition(word: String, type: WordType) -> String {
        let word = word.lowercased()
        
        // Curated short definitions
        let shortDefs: [String: String] = [
            "efficiency": "effectiveness",
            "innovation": "new ideas",
            "sustainability": "eco-friendly",
            "leadership": "guidance",
            "creativity": "imagination",
            "technology": "tools/systems",
            "communication": "exchange info",
            "education": "learning",
            "environment": "surroundings",
            "opportunity": "chance",
            "challenge": "difficulty",
            "success": "achievement",
            "knowledge": "understanding",
            "experience": "practice",
            "development": "growth",
            "beautiful": "attractive",
            "important": "significant",
            "different": "unlike",
            "possible": "achievable",
            "available": "accessible",
            "necessary": "required",
            "interesting": "engaging",
            "difficult": "hard",
            "similar": "alike",
            "special": "unique",
            "learn": "acquire skill",
            "create": "make new",
            "develop": "improve",
            "understand": "comprehend",
            "communicate": "share info",
            "achieve": "accomplish",
            "improve": "enhance",
            "discover": "find out",
            "explore": "investigate",
            "analyze": "examine"
        ]
        
        if let shortDef = shortDefs[word] {
            return shortDef
        }
        
        // Fallback based on word type
        switch type {
        case .noun:
            return "concept"
        case .verb:
            return "action"
        case .adjective:
            return "quality"
        case .adverb:
            return "manner"
        case .other:
            return "term"
        }
    }
    
    private func generateSmartTranslation(word: String, to language: String, type: WordType) -> String {
        // Use the existing enhanced translation logic
        return getTranslation(for: word, to: language)
    }
    
    private func generateSmartExample(word: String, type: WordType, language: String) -> String {
        let word = word.lowercased()
        
        // Curated examples for common words
        let examples: [String: String] = [
            "efficiency": "The new software improved our team's efficiency by 40%, allowing us to complete projects faster.",
            "innovation": "The company's innovation in renewable energy technology revolutionized the industry.",
            "sustainability": "Our commitment to sustainability includes recycling programs and renewable energy sources.",
            "leadership": "Her strong leadership during the crisis helped the team navigate through difficult challenges.",
            "creativity": "The artist's creativity shines through in every brushstroke of this magnificent painting.",
            "technology": "Modern technology has transformed how we communicate and work remotely.",
            "communication": "Effective communication between departments is essential for project success.",
            "education": "Quality education provides students with the skills needed for future careers.",
            "environment": "Protecting our environment requires collective action from individuals and governments.",
            "opportunity": "This internship presents a valuable opportunity to gain real-world experience.",
            "challenge": "Learning a new language can be a challenge, but it's incredibly rewarding.",
            "success": "His success in business came from years of hard work and dedication.",
            "knowledge": "She shared her extensive knowledge of marine biology with the research team.",
            "experience": "My experience working abroad taught me to adapt to different cultures.",
            "development": "The software development process requires careful planning and testing.",
            "beautiful": "The sunset over the mountains was absolutely beautiful and breathtaking.",
            "important": "It's important to maintain a healthy work-life balance.",
            "different": "Each culture has different traditions and customs to celebrate.",
            "possible": "With determination and effort, anything is possible to achieve.",
            "available": "The new course will be available to all students starting next semester.",
            "learn": "Children learn best when they're engaged and having fun.",
            "create": "Artists create masterpieces that inspire and move people emotionally.",
            "develop": "We need to develop new strategies to reach our sales goals.",
            "understand": "It takes time to understand complex scientific concepts fully.",
            "communicate": "We communicate with our international clients via video conferences.",
            "achieve": "With hard work and persistence, you can achieve your dreams.",
            "improve": "Regular practice will help you improve your language skills significantly.",
            "discover": "Scientists discover new species in remote rainforest regions every year.",
            "explore": "Let's explore the ancient ruins and learn about their history.",
            "analyze": "Data scientists analyze large datasets to identify meaningful patterns."
        ]
        
        if let example = examples[word] {
            return example
        }
        
        // Generate contextual examples based on word type
        switch type {
        case .noun:
            return "The \(word) played a crucial role in achieving our objectives."
        case .verb:
            return "We need to \(word) more effectively to reach our goals."
        case .adjective:
            return "The solution was remarkably \(word) and exceeded all expectations."
        case .adverb:
            return "She handled the situation \(word) and professionally."
        case .other:
            return "Understanding \(word) is essential for success in this field."
        }
    }
    
    private func generateSmartPhonetics(word: String) -> String {
        let word = word.lowercased()
        
        // Curated phonetics for common words
        let phonetics: [String: String] = [
            "efficiency": "/ɪˈfɪʃənsi/",
            "innovation": "/ˌɪnəˈveɪʃən/",
            "sustainability": "/səˌsteɪnəˈbɪləti/",
            "leadership": "/ˈliːdərʃɪp/",
            "creativity": "/ˌkriːeɪˈtɪvəti/",
            "technology": "/tɛkˈnɒlədʒi/",
            "communication": "/kəˌmjuːnɪˈkeɪʃən/",
            "education": "/ˌɛdʒuˈkeɪʃən/",
            "environment": "/ɪnˈvaɪrənmənt/",
            "opportunity": "/ˌɒpərˈtuːnəti/",
            "challenge": "/ˈtʃælɪndʒ/",
            "success": "/səkˈsɛs/",
            "knowledge": "/ˈnɒlɪdʒ/",
            "experience": "/ɪkˈspɪriəns/",
            "development": "/dɪˈvɛləpmənt/",
            "beautiful": "/ˈbjuːtɪfəl/",
            "important": "/ɪmˈpɔːrtənt/",
            "different": "/ˈdɪfərənt/",
            "possible": "/ˈpɒsəbəl/",
            "available": "/əˈveɪləbəl/",
            "necessary": "/ˈnɛsəsɛri/",
            "interesting": "/ˈɪntrəstɪŋ/",
            "difficult": "/ˈdɪfɪkəlt/",
            "similar": "/ˈsɪmələr/",
            "special": "/ˈspɛʃəl/",
            "learn": "/lɜːrn/",
            "create": "/kriˈeɪt/",
            "develop": "/dɪˈvɛləp/",
            "understand": "/ˌʌndərˈstænd/",
            "communicate": "/kəˈmjuːnɪkeɪt/",
            "achieve": "/əˈtʃiːv/",
            "improve": "/ɪmˈpruːv/",
            "discover": "/dɪˈskʌvər/",
            "explore": "/ɪkˈsplɔːr/",
            "analyze": "/ˈænəlaɪz/",
            "hello": "/həˈloʊ/",
            "book": "/bʊk/",
            "water": "/ˈwɔːtər/",
            "house": "/haʊs/",
            "friend": "/frɛnd/",
            "family": "/ˈfæməli/",
            "food": "/fuːd/",
            "love": "/lʌv/",
            "work": "/wɜːrk/",
            "time": "/taɪm/",
            "life": "/laɪf/",
            "world": "/wɜːrld/"
        ]
        
        if let phonetic = phonetics[word] {
            return phonetic
        }
        
        // Generate approximate phonetics for unknown words
        return generateApproximatePhonetics(word)
    }
    
    private func generateApproximatePhonetics(_ word: String) -> String {
        var phonetic = word
        
        // Common English phonetic patterns
        let patterns: [(String, String)] = [
            ("tion", "ʃən"),
            ("sion", "ʒən"),
            ("ough", "ʌf"),
            ("augh", "ɔːf"),
            ("ight", "aɪt"),
            ("eigh", "eɪ"),
            ("ph", "f"),
            ("gh", ""),
            ("kn", "n"),
            ("wr", "r"),
            ("th", "θ"),
            ("ch", "tʃ"),
            ("sh", "ʃ"),
            ("ng", "ŋ"),
            ("ck", "k"),
            ("qu", "kw"),
            ("x", "ks"),
            ("y", "i"),
            ("ee", "iː"),
            ("oo", "uː"),
            ("ou", "aʊ"),
            ("oi", "ɔɪ"),
            ("ay", "eɪ"),
            ("ai", "eɪ"),
            ("ey", "eɪ")
        ]
        
        for (pattern, replacement) in patterns {
            phonetic = phonetic.replacingOccurrences(of: pattern, with: replacement)
        }
        
        return "/\(phonetic)/"
    }
} 