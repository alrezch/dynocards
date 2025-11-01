//
//  StudySessionViewModel.swift
//  Dynocards
//
//  Created by User on 2024
//

import Foundation
import CoreData
import SwiftUI
import UserNotifications

class StudySessionViewModel: ObservableObject {
    @Published var currentCardIndex = 0
    @Published var showingAnswer = false
    @Published var studyComplete = false
    @Published var totalPoints = 0
    @Published var dueCards: [Flashcard] = []
    @Published var cardsToStudy: [Flashcard] = []
    @Published var sessionStats = StudySessionStats()
    @Published var correctAnswers = 0
    @Published var totalAnswered = 0
    @Published var isReviewMode = false // Track if we're in review/practice mode
    
    private let coreDataManager = CoreDataManager.shared
    private let notificationService = NotificationService.shared
    
    struct StudySessionStats {
        var totalCards = 0
        var correctAnswers = 0
        var incorrectAnswers = 0
        var easyAnswers = 0
        var startTime: Date?
        var endTime: Date?
        
        var accuracy: Double {
            let total = correctAnswers + incorrectAnswers + easyAnswers
            guard total > 0 else { return 0.0 }
            return Double(correctAnswers + easyAnswers) / Double(total)
        }
        
        var duration: TimeInterval {
            guard let start = startTime, let end = endTime else { return 0 }
            return end.timeIntervalSince(start)
        }
    }
    
    init() {
        loadDueCards()
    }
    
    // MARK: - Public Methods
    
    func loadDueCards() {
        dueCards = coreDataManager.fetchDueCards()
        cardsToStudy = dueCards
        sessionStats.totalCards = dueCards.count
        isReviewMode = false // Mark as spaced repetition mode
        
        print("📚 StudySessionViewModel: Loaded \(dueCards.count) due cards")
        print("📚 Cards to study: \(cardsToStudy.count)")
        
        if !dueCards.isEmpty && sessionStats.startTime == nil {
            sessionStats.startTime = Date()
        }
    }
    
    func loadAllCardsForReview() {
        dueCards = coreDataManager.fetchAllFlashcards()
        cardsToStudy = dueCards
        sessionStats.totalCards = dueCards.count
        isReviewMode = true // Mark as review mode
        
        if !dueCards.isEmpty && sessionStats.startTime == nil {
            sessionStats.startTime = Date()
        }
    }
    
    func loadDueCardsForDate(_ date: Date) {
        dueCards = coreDataManager.fetchDueCardsForDate(date)
        cardsToStudy = dueCards
        sessionStats.totalCards = dueCards.count
        
        if !dueCards.isEmpty && sessionStats.startTime == nil {
            sessionStats.startTime = Date()
        }
    }
    
    func startStudySession() {
        loadDueCards()
        currentCardIndex = 0
        showingAnswer = false
        studyComplete = false
        sessionStats.startTime = Date()
    }
    
    func showAnswer() {
        showingAnswer = true
        // HapticManager.selection()
    }
    
    func answerCard(difficulty: AnswerDifficulty) {
        guard currentCardIndex < cardsToStudy.count else { return }
        
        let card = cardsToStudy[currentCardIndex]
        
        // Update statistics (always update stats regardless of mode)
        totalAnswered += 1
        switch difficulty {
        case .hard:
            sessionStats.incorrectAnswers += 1
            totalPoints += Constants.Study.pointsPerIncorrectAnswer
        case .good:
            sessionStats.correctAnswers += 1
            correctAnswers += 1
            totalPoints += Constants.Study.pointsPerCorrectAnswer
        case .easy:
            sessionStats.easyAnswers += 1
            correctAnswers += 1
            totalPoints += Constants.Study.pointsPerEasyAnswer
        }
        
        // Only update Leitner system if NOT in review mode
        if !isReviewMode {
            updateCardProgress(card, difficulty: difficulty)
        }
        // In review mode, we still update lastStudied for tracking purposes but don't change boxes
        else {
            card.lastStudied = Date()
            coreDataManager.save()
        }
        
        // Move to next card
        moveToNextCard()
        
        // Provide haptic feedback (simplified)
        // HapticManager.impact(difficulty != .hard ? .light : .medium)
    }
    
    func resetSession() {
        currentCardIndex = 0
        showingAnswer = false
        studyComplete = false
        totalPoints = 0
        correctAnswers = 0
        totalAnswered = 0
        sessionStats = StudySessionStats()
        isReviewMode = false // Reset review mode flag
    }
    
    func resetSessionAndLoadDueCards() {
        resetSession()
        loadDueCards()
        // isReviewMode stays false (spaced repetition mode)
    }
    
    func skipCard() {
        moveToNextCard()
        // HapticManager.selection()
    }
    
    // MARK: - Private Methods
    
    private func updateCardProgress(_ card: Flashcard, difficulty: AnswerDifficulty) {
        switch difficulty {
        case .hard:
            card.updateLeitnerBox(correct: false)
        case .good:
            card.updateLeitnerBox(correct: true)
        case .easy:
            card.updateLeitnerBox(correct: true)
            // Give extra boost for easy answers
            if card.leitnerBox < Constants.LeitnerSystem.maxBox {
                card.leitnerBox += 1
            }
        }
        
        // Check for mastery
        if card.mastered {
            totalPoints += Constants.Study.masteryBonusPoints
            scheduleAchievementNotification(for: card)
        }
        
        coreDataManager.save()
    }
    
    private func moveToNextCard() {
        currentCardIndex += 1
        showingAnswer = false
        
        if currentCardIndex >= cardsToStudy.count {
            completeSession()
        }
    }
    
    private func completeSession() {
        studyComplete = true
        sessionStats.endTime = Date()
        
        updateUserProgress()
        
        // Only schedule review notifications if not in review mode
        // (review mode doesn't change nextReview dates, so notifications would be incorrect)
        if !isReviewMode {
            scheduleNextReviewNotifications()
        }
        
        // Achievement notifications
        // checkForAchievements()
        
        // HapticManager.notification(.success)
    }
    
    private func updateUserProgress() {
        let user = coreDataManager.getOrCreateUser()
        // Always update points (points are earned in both modes)
        user.totalPoints += Int32(totalPoints)
        
        // Only update streak if not in review mode (review mode shouldn't count toward streaks)
        if !isReviewMode {
            updateUserStreak(user)
        }
        coreDataManager.save()
    }
    
    private func updateUserStreak(_ user: User) {
        let calendar = Calendar.current
        
        guard let lastActiveDate = user.lastActiveDate else {
            // First time user, start streak
            user.streakCount = 1
            user.lastActiveDate = Date()
            return
        }
        
        if calendar.isDateInToday(lastActiveDate) {
            // Already active today, no streak change
            return
        } else if calendar.isDateInYesterday(lastActiveDate) {
            // Maintain streak
            user.streakCount += 1
        } else {
            // Reset streak
            user.streakCount = 1
        }
        
        user.lastActiveDate = Date()
    }
    
    private func scheduleNextReviewNotifications() {
        for card in dueCards {
            if !card.mastered {
                notificationService.scheduleReviewReminder(for: card)
            }
        }
    }
    
    private func scheduleAchievementNotification(for card: Flashcard) {
        let content = UNMutableNotificationContent()
        content.title = "Word Mastered! 🌟"
        content.body = "Congratulations! You've mastered '\(card.word)'"
        content.sound = UNNotificationSound.default
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 2, repeats: false)
        let request = UNNotificationRequest(
            identifier: "mastery_\(card.id.uuidString)",
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request)
    }
    
    /*
    private func checkForAchievements() {
        let user = coreDataManager.getOrCreateUser()
        let allCards = coreDataManager.fetchFlashcards()
        let masteredCards = coreDataManager.fetchMasteredCards()
        
        // Check each achievement
        for achievement in Constants.Achievements.all {
            if shouldUnlockAchievement(achievement, user: user, allCards: allCards, masteredCards: masteredCards) {
                scheduleAchievementUnlockedNotification(achievement)
            }
        }
    }
    
    private func shouldUnlockAchievement(_ achievement: Achievement, user: User, allCards: [Flashcard], masteredCards: [Flashcard]) -> Bool {
        switch achievement.type {
        case .wordsAdded:
            return allCards.count >= achievement.requirement
        case .wordsMastered:
            return masteredCards.count >= achievement.requirement
        case .streakCount:
            return user.streakCount >= achievement.requirement
        case .totalPoints:
            return user.totalPoints >= achievement.requirement
        case .studySessions:
            // Implement study session tracking if needed
            return false
        }
    }
    
    private func scheduleAchievementUnlockedNotification(_ achievement: Achievement) {
        let content = UNMutableNotificationContent()
        content.title = "Achievement Unlocked! 🏆"
        content.body = "\(achievement.title): \(achievement.description)"
        content.sound = UNNotificationSound.default
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 3, repeats: false)
        let request = UNNotificationRequest(
            identifier: "achievement_\(achievement.id)",
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request)
    }
    */
}

// MARK: - Answer Difficulty Enum
enum AnswerDifficulty {
    case hard    // Incorrect answer
    case good    // Correct answer
    case easy    // Very easy answer
    
    var color: Color {
        switch self {
        case .hard: return .red
        case .good: return .green
        case .easy: return .blue
        }
    }
    
    var title: String {
        switch self {
        case .hard: return "Hard"
        case .good: return "Good"
        case .easy: return "Easy"
        }
    }
} 