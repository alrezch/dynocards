//
//  CoreDataManager.swift
//  Dynocards
//
//  Created by User on 2024
//

import Foundation
import CoreData

class CoreDataManager: ObservableObject {
    static let shared = CoreDataManager()
    
    lazy var container: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "Dynocards")
        
        // Configure the store to handle model changes
        let storeDescription = container.persistentStoreDescriptions.first
        storeDescription?.shouldMigrateStoreAutomatically = true
        storeDescription?.shouldInferMappingModelAutomatically = true
        
        container.loadPersistentStores { storeDescription, error in
            if let error = error {
                print("❌ Core Data error: \(error.localizedDescription)")
                print("❌ Store description: \(storeDescription)")
                
                // Try to delete the store and recreate it
                if let storeURL = storeDescription.url {
                    do {
                        try FileManager.default.removeItem(at: storeURL)
                        print("🗑️ Deleted corrupted store, attempting to recreate...")
                        
                        // Try loading again
                        container.loadPersistentStores { _, recreateError in
                            if let recreateError = recreateError {
                                fatalError("Failed to recreate Core Data store: \(recreateError.localizedDescription)")
                            } else {
                                print("✅ Successfully recreated Core Data store")
                            }
                        }
                    } catch {
                        fatalError("Failed to delete corrupted store: \(error.localizedDescription)")
                    }
                } else {
                    fatalError("Core Data error: \(error.localizedDescription)")
                }
            } else {
                print("✅ Core Data store loaded successfully: \(storeDescription.url?.absoluteString ?? "unknown")")
            }
        }
        return container
    }()
    
    var context: NSManagedObjectContext {
        return container.viewContext
    }
    
    private init() {}
    
    func save() {
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                print("Save error: \(error)")
            }
        }
    }
    
    func createUser() -> User {
        let user = User(context: context)
        
        // Ensure all required fields are set
        if user.name == nil {
            user.name = "User"
        }
        if user.preferredLanguage == nil {
            user.preferredLanguage = "English"
        }
        if user.sourceLanguage == nil {
            user.sourceLanguage = "English"
        }
        
        save()
        print("✅ User created with name: \(user.name ?? "Unknown")")
        return user
    }
    
    func fetchUser() -> User? {
        let request: NSFetchRequest<User> = User.fetchRequest()
        do {
            let users = try context.fetch(request)
            print("📊 Found \(users.count) users in database")
            return users.first
        } catch {
            print("❌ Fetch user error: \(error)")
            print("❌ Error details: \(error.localizedDescription)")
            return nil
        }
    }
    
    func getOrCreateUser() -> User {
        print("🔄 Getting or creating user...")
        if let user = fetchUser() {
            print("✅ Found existing user: \(user.name ?? "Unknown")")
            return user
        } else {
            print("🆕 Creating new user...")
            let newUser = createUser()
            print("✅ Created new user: \(newUser.name ?? "Unknown")")
            return newUser
        }
    }
    
    func fetchFlashcards() -> [Flashcard] {
        let request: NSFetchRequest<Flashcard> = Flashcard.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Flashcard.dateCreated, ascending: false)]
        
        do {
            return try context.fetch(request)
        } catch {
            print("Fetch flashcards error: \(error)")
            return []
        }
    }
    
    func fetchDueCards() -> [Flashcard] {
        let calendar = Calendar.current
        let today = Date()
        let endOfToday = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: today)) ?? today
        
        let request: NSFetchRequest<Flashcard> = Flashcard.fetchRequest()
        request.predicate = NSPredicate(
            format: "nextReview >= %@ AND nextReview < %@ AND mastered == false",
            calendar.startOfDay(for: today) as NSDate,
            endOfToday as NSDate
        )
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Flashcard.nextReview, ascending: true)]
        
        do {
            let cards = try context.fetch(request)
            print("🔍 Fetched \(cards.count) due cards for today")
            return cards
        } catch {
            print("Fetch due cards error: \(error)")
            return []
        }
    }
    
    func fetchDueCardsForDate(_ date: Date) -> [Flashcard] {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) ?? startOfDay
        
        let request: NSFetchRequest<Flashcard> = Flashcard.fetchRequest()
        request.predicate = NSPredicate(
            format: "nextReview >= %@ AND nextReview < %@ AND mastered == false",
            startOfDay as NSDate,
            endOfDay as NSDate
        )
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Flashcard.nextReview, ascending: true)]
        
        do {
            return try context.fetch(request)
        } catch {
            print("Fetch due cards for date error: \(error)")
            return []
        }
    }
    
    func fetchDueCardsCountForDate(_ date: Date) -> Int {
        return fetchDueCardsForDate(date).count
    }
    
    func fetchAllFlashcards() -> [Flashcard] {
        let request: NSFetchRequest<Flashcard> = Flashcard.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Flashcard.dateCreated, ascending: false)]
        
        do {
            return try context.fetch(request)
        } catch {
            print("Fetch all flashcards error: \(error)")
            return []
        }
    }
    
    // MARK: - Test Data Methods
    func addSampleFlashcards() {
        let sampleWords = [
            ("hello", "A greeting used to say hi or welcome someone", "hi", "hola", "Hello, how are you today?", "həˈloʊ", "English", "Spanish"),
            ("goodbye", "A farewell expression used when parting", "bye", "adiós", "Goodbye, see you tomorrow!", "ˌɡʊdˈbaɪ", "English", "Spanish"),
            ("thank you", "An expression of gratitude", "thanks", "gracias", "Thank you for your help.", "ˈθæŋk ju", "English", "Spanish"),
            ("please", "A polite request or expression", "polite request", "por favor", "Please help me with this.", "pliz", "English", "Spanish"),
            ("sorry", "An expression of apology or regret", "apology", "lo siento", "I'm sorry for being late.", "ˈsɑri", "English", "Spanish")
        ]
        
        for (word, definition, shortDef, translation, example, phonetics, source, target) in sampleWords {
            let flashcard = Flashcard(context: context)
            flashcard.word = word
            flashcard.definition = definition
            flashcard.shortDefinition = shortDef
            flashcard.translation = translation
            flashcard.example = example
            flashcard.phonetics = phonetics
            flashcard.sourceLanguage = source
            flashcard.targetLanguage = target
            flashcard.dateCreated = Date()
            flashcard.nextReview = Date() // Due today
            flashcard.leitnerBox = 1
            flashcard.studyCount = 0
            flashcard.correctCount = 0
            flashcard.mastered = false
            flashcard.difficulty = 1
        }
        
        save()
        print("✅ Added \(sampleWords.count) sample flashcards")
    }
    
    func fetchMasteredCards() -> [Flashcard] {
        let request: NSFetchRequest<Flashcard> = Flashcard.fetchRequest()
        request.predicate = NSPredicate(format: "mastered == true")
        
        do {
            return try context.fetch(request)
        } catch {
            print("Fetch mastered cards error: \(error)")
            return []
        }
    }
    
    func deleteFlashcard(_ flashcard: Flashcard) {
        context.delete(flashcard)
        save()
    }
    
    func checkWordExists(word: String, sourceLanguage: String) -> Bool {
        let fetchRequest: NSFetchRequest<Flashcard> = Flashcard.fetchRequest()
        // Case-insensitive comparison - Core Data doesn't support ==[c] directly,
        // so we'll fetch all cards with matching sourceLanguage and compare in memory
        fetchRequest.predicate = NSPredicate(format: "sourceLanguage == %@", sourceLanguage)
        
        do {
            let existingCards = try context.fetch(fetchRequest)
            // Compare case-insensitively
            return existingCards.contains { $0.word.lowercased() == word.lowercased() }
        } catch {
            print("❌ Error checking for duplicate word: \(error)")
            return false
        }
    }
    
    func createFlashcard(
        word: String,
        definition: String,
        shortDefinition: String,
        translation: String,
        example: String,
        phonetics: String,
        sourceLanguage: String,
        targetLanguage: String,
        cefrLevel: String? = nil,
        tags: [String]? = nil
    ) -> Bool {
        print("🔄 Starting to save flashcard: \(word)")
        
        let flashcard = Flashcard(context: context)
        
        // Set all required fields explicitly
        flashcard.word = word
        flashcard.definition = definition
        flashcard.shortDefinition = shortDefinition
        flashcard.translation = translation
        flashcard.example = example
        flashcard.phonetics = phonetics
        flashcard.sourceLanguage = sourceLanguage
        flashcard.targetLanguage = targetLanguage
        flashcard.cefrLevel = cefrLevel
        
        // Store tags as comma-separated string, or "All words" if empty
        let tagsToStore = tags?.filter { $0.lowercased() != "all words" && !$0.isEmpty }
        if let tagsToStore = tagsToStore, !tagsToStore.isEmpty {
            flashcard.tags = tagsToStore.joined(separator: ",")
        } else {
            flashcard.tags = "All words" // Default hidden tag
        }
        
        // Let awakeFromInsert handle the default values, but verify they're set
        print("🔄 Flashcard created with ID: \(flashcard.id)")
        print("📝 Word: '\(flashcard.word)'")
        print("📝 Definition: '\(flashcard.definition)'")
        print("📝 Translation: '\(flashcard.translation)'")
        print("📝 Source Language: '\(flashcard.sourceLanguage)'")
        print("📝 Target Language: '\(flashcard.targetLanguage)'")
        
        do {
            try context.save()
            
            // Verify the save was successful
            let fetchRequest: NSFetchRequest<Flashcard> = Flashcard.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "word == %@", word)
            
            let savedCards = try context.fetch(fetchRequest)
            if !savedCards.isEmpty {
                print("✅ Flashcard saved and verified: \(word)")
                return true
            } else {
                print("❌ Flashcard was not saved properly")
                return false
            }
        } catch {
            print("❌ Error saving flashcard: \(error)")
            print("❌ Error details: \(error.localizedDescription)")
            return false
        }
    }
    
    // MARK: - CEFR Level Migration
    func updateExistingFlashcardsWithCEFRLevels() async {
        print("🔄 Starting CEFR level migration for existing flashcards...")
        
        let fetchRequest: NSFetchRequest<Flashcard> = Flashcard.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "cefrLevel == nil OR cefrLevel == ''")
        
        do {
            let flashcardsWithoutCEFR = try context.fetch(fetchRequest)
            let totalCount = flashcardsWithoutCEFR.count
            
            if totalCount == 0 {
                print("✅ All flashcards already have CEFR levels")
                return
            }
            
            print("📊 Found \(totalCount) flashcards without CEFR levels")
            
            let aiService = AIService.shared
            
            for (index, flashcard) in flashcardsWithoutCEFR.enumerated() {
                // Determine CEFR level
                let cefrLevel = await aiService.determineCEFRLevel(
                    word: flashcard.word,
                    sourceLanguage: flashcard.sourceLanguage
                )
                
                // Update the flashcard
                flashcard.cefrLevel = cefrLevel
                
                // Save periodically (every 10 cards or at the end)
                if (index + 1) % 10 == 0 || index == totalCount - 1 {
                    save()
                    print("✅ Updated CEFR levels: \(index + 1)/\(totalCount)")
                }
            }
            
            // Final save
            save()
            print("✅ CEFR level migration completed for \(totalCount) flashcards")
        } catch {
            print("❌ Error fetching flashcards for CEFR migration: \(error)")
        }
    }
    
    // MARK: - Debug Methods
    func clearAllData() {
        let flashcardRequest: NSFetchRequest<NSFetchRequestResult> = Flashcard.fetchRequest()
        let deleteFlashcardsRequest = NSBatchDeleteRequest(fetchRequest: flashcardRequest)
        
        let userRequest: NSFetchRequest<NSFetchRequestResult> = User.fetchRequest()
        let deleteUsersRequest = NSBatchDeleteRequest(fetchRequest: userRequest)
        
        do {
            try context.execute(deleteFlashcardsRequest)
            try context.execute(deleteUsersRequest)
            try context.save()
            print("✅ Cleared all Core Data")
        } catch {
            print("❌ Failed to clear data: \(error)")
        }
    }
    
    func deleteAllData() {
        clearAllData()
    }
    
    // MARK: - Sample Data
    func createSampleDataIfNeeded() {
        // Only create sample data if no flashcards exist
        let existingCards = fetchFlashcards()
        guard existingCards.isEmpty else { 
            print("ℹ️ Sample data already exists (\(existingCards.count) cards)")
            return 
        }
        
        print("🔄 Creating sample data...")
        
        let sampleWords = [
            ("Hello", "A greeting used when meeting someone", "greeting", "hola", "Hello, how are you today?", "/həˈloʊ/"),
            ("Book", "A written work consisting of pages bound together", "written work", "libro", "I'm reading an interesting book about history.", "/bʊk/"),
            ("Water", "A colorless, transparent liquid essential for life", "liquid", "agua", "Please drink more water to stay hydrated.", "/ˈwɔːtər/"),
            ("Beautiful", "Pleasing to the senses or mind aesthetically", "pleasing", "hermoso", "The sunset was absolutely beautiful tonight.", "/ˈbjuːtɪfəl/"),
            ("Friend", "A person with whom one has mutual affection", "companion", "amigo", "She is my best friend from college.", "/frɛnd/")
        ]
        
        for (word, definition, shortDef, translation, example, phonetics) in sampleWords {
            let flashcard = Flashcard(context: context)
            flashcard.word = word
            flashcard.definition = definition
            flashcard.shortDefinition = shortDef
            flashcard.translation = translation
            flashcard.example = example
            flashcard.phonetics = phonetics
            flashcard.sourceLanguage = "English"
            flashcard.targetLanguage = "Spanish"
            // Note: Other fields like id, dateCreated, etc. are set in awakeFromInsert
        }
        
        do {
            try context.save()
            print("✅ Created \(sampleWords.count) sample flashcards successfully")
        } catch {
            print("❌ Failed to create sample data: \(error)")
            print("❌ Error details: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Exam Session Management
    
    func saveExamSession(totalQuestions: Int, correctAnswers: Int, incorrectAnswers: Int, duration: Double) {
        let examSession = ExamSession(context: context)
        examSession.id = UUID()
        examSession.date = Date()
        examSession.totalQuestions = Int16(totalQuestions)
        examSession.correctAnswers = Int16(correctAnswers)
        examSession.incorrectAnswers = Int16(incorrectAnswers)
        examSession.duration = duration
        
        save()
        print("✅ Exam session saved: \(correctAnswers)/\(totalQuestions) correct")
    }
    
    func fetchExamSessions() -> [ExamSession] {
        let request: NSFetchRequest<ExamSession> = ExamSession.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \ExamSession.date, ascending: false)]
        
        do {
            let sessions = try context.fetch(request)
            return sessions
        } catch {
            print("❌ Fetch exam sessions error: \(error)")
            return []
        }
    }
    
    func getExamStatistics() -> (totalExams: Int, totalQuestions: Int, correctAnswers: Int, incorrectAnswers: Int) {
        let sessions = fetchExamSessions()
        let totalExams = sessions.count
        let totalQuestions = sessions.reduce(0) { $0 + Int($1.totalQuestions) }
        let correctAnswers = sessions.reduce(0) { $0 + Int($1.correctAnswers) }
        let incorrectAnswers = sessions.reduce(0) { $0 + Int($1.incorrectAnswers) }
        
        return (totalExams, totalQuestions, correctAnswers, incorrectAnswers)
    }
} 