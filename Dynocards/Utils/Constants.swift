//
//  Constants.swift
//  Dynocards
//
//  Created by User on 2024
//

import Foundation
import SwiftUI

struct Constants {
    
    // MARK: - App Configuration
    struct App {
        static let name = "Dynocards"
        static let version = "1.0.0"
        static let buildNumber = "1"
        static let bundleIdentifier = "com.dynocards.app"
    }
    
    // MARK: - Leitner System
    struct LeitnerSystem {
        static let maxBox = 5
        static let initialBox = 1
        static let masteryThreshold = 0.8
        
        // Days to wait before next review for each box
        static let reviewIntervals: [Int16: Int] = [
            1: 1,    // 1 day
            2: 3,    // 3 days
            3: 7,    // 1 week
            4: 14,   // 2 weeks
            5: 30    // 1 month
        ]
    }
    
    // MARK: - Study Settings
    struct Study {
        static let defaultDailyGoal = 10
        static let minDailyGoal = 5
        static let maxDailyGoal = 50
        static let goalStepSize = 5
        
        static let pointsPerCorrectAnswer = 10
        static let pointsPerIncorrectAnswer = 5
        static let pointsPerEasyAnswer = 15
        static let masteryBonusPoints = 50
    }
    
    // MARK: - UI Constants
    struct UI {
        static let cornerRadius: CGFloat = 12
        static let shadowRadius: CGFloat = 4
        static let standardPadding: CGFloat = 16
        static let smallPadding: CGFloat = 8
        static let largePadding: CGFloat = 24
        
        struct Animation {
            static let defaultDuration = 0.3
            static let fastDuration = 0.15
            static let slowDuration = 0.5
        }
    }
    
    // MARK: - Languages
    struct Languages {
        static let supported = [
            "English", "Spanish", "French", "German", "Italian",
            "Portuguese", "Chinese", "Japanese", "Korean", "Arabic"
        ]
        
        static let languageCodes: [String: String] = [
            "English": "en-US",
            "Spanish": "es-ES",
            "French": "fr-FR",
            "German": "de-DE",
            "Italian": "it-IT",
            "Portuguese": "pt-PT",
            "Chinese": "zh-CN",
            "Japanese": "ja-JP",
            "Korean": "ko-KR",
            "Arabic": "ar-SA"
        ]
        
        static func getLanguageCode(for language: String) -> String {
            return languageCodes[language] ?? "en-US"
        }
    }
    
    // MARK: - Notifications
    struct Notifications {
        static let studyReminderIdentifier = "daily_study_reminder"
        static let dueCardReminderPrefix = "due_cards_"
        static let reviewReminderPrefix = "review_"
        
        struct Messages {
            static let studyReminderTitle = "Time to Study!"
            static let studyReminderBody = "Don't forget to review your flashcards today 📚"
            static let dueCardsTitle = "Cards Ready for Review"
            static let reviewTitle = "Time to Review!"
        }
    }
    
    // MARK: - Achievements
    struct Achievements {
        static let firstWord = Achievement(
            id: "first_word",
            title: "First Word",
            description: "Added your first word",
            icon: "plus.circle.fill",
            requirement: 1,
            type: .wordsAdded
        )
        
        static let wordCollector = Achievement(
            id: "word_collector",
            title: "Word Collector",
            description: "Added 50 words",
            icon: "books.vertical.fill",
            requirement: 50,
            type: .wordsAdded
        )
        
        static let masterLearner = Achievement(
            id: "master_learner",
            title: "Master Learner",
            description: "Mastered 10 words",
            icon: "star.fill",
            requirement: 10,
            type: .wordsMastered
        )
        
        static let streakMaster = Achievement(
            id: "streak_master",
            title: "Streak Master",
            description: "7 day streak",
            icon: "flame.fill",
            requirement: 7,
            type: .streakCount
        )
        
        static let all = [firstWord, wordCollector, masterLearner, streakMaster]
    }
    
    // MARK: - API Configuration
    struct API {
        static let timeout: TimeInterval = 30
        static let retryAttempts = 3
        
        // OpenAI Configuration
        static let openAIEndpoint = "https://api.openai.com/v1/chat/completions"
        static let openAIModel = "gpt-3.5-turbo"
        static let maxTokens = 500
        static let temperature = 0.7
        
        // Exam Question Configuration
        static let examMaxTokens = 400
        static let examTemperature = 0.8
    }
    
    // MARK: - Core Data
    struct CoreData {
        static let modelName = "Dynocards"
        static let containerName = "Dynocards"
    }
}

// MARK: - Achievement Model
struct Achievement {
    let id: String
    let title: String
    let description: String
    let icon: String
    let requirement: Int
    let type: AchievementType
    
    enum AchievementType {
        case wordsAdded
        case wordsMastered
        case streakCount
        case totalPoints
        case studySessions
    }
}

// MARK: - Error Types
enum DynocardsError: LocalizedError {
    case dataNotFound
    case invalidInput
    case networkError
    case coreDataError
    case authenticationError
    
    var errorDescription: String? {
        switch self {
        case .dataNotFound:
            return "Data not found"
        case .invalidInput:
            return "Invalid input provided"
        case .networkError:
            return "Network connection error"
        case .coreDataError:
            return "Database error occurred"
        case .authenticationError:
            return "Authentication failed"
        }
    }
} 