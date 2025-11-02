//
//  NotificationService.swift
//  Dynocards
//
//  Created by User on 2024
//

import Foundation
import UserNotifications
import UIKit

class NotificationService: ObservableObject {
    static let shared = NotificationService()
    @Published var permissionGranted = false
    
    private init() {}
    
    func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            DispatchQueue.main.async {
                self.permissionGranted = granted
            }
        }
    }
    
    func scheduleStudyReminder(at time: Date) {
        // Remove existing daily reminder to prevent duplicates
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["daily_study_reminder"])
        
        let content = UNMutableNotificationContent()
        content.title = "Time to Study!"
        content.body = "Don't forget to review your flashcards today 📚"
        content.sound = UNNotificationSound.default
        content.categoryIdentifier = "STUDY_REMINDER"
        
        // Update badge with current due card count
        let coreDataManager = CoreDataManager.shared
        let dueCards = coreDataManager.fetchDueCards()
        content.badge = NSNumber(value: dueCards.count)
        
        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute], from: time)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        
        let request = UNNotificationRequest(
            identifier: "daily_study_reminder",
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("❌ Notification scheduling error: \(error)")
            } else {
                print("✅ Daily study reminder scheduled for \(components.hour ?? 0):\(String(format: "%02d", components.minute ?? 0))")
            }
        }
    }
    
    func scheduleDueCardReminder(cardCount: Int) {
        guard cardCount > 0 else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "Cards Ready for Review"
        content.body = "You have \(cardCount) card\(cardCount > 1 ? "s" : "") ready to review!"
        content.sound = UNNotificationSound.default
        content.badge = NSNumber(value: cardCount)
        content.categoryIdentifier = "DUE_CARDS"
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        
        let request = UNNotificationRequest(
            identifier: "due_cards_\(Date().timeIntervalSince1970)",
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("❌ Due card reminder scheduling error: \(error)")
            } else {
                print("✅ Due card reminder scheduled for \(cardCount) cards")
            }
        }
    }
    
    func clearNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
        
        // Clear badge count
        DispatchQueue.main.async {
            UIApplication.shared.applicationIconBadgeNumber = 0
        }
        
        print("✅ All notifications cleared")
    }
    
    // MARK: - Badge Management
    
    /// Updates the app badge count based on due cards
    func updateBadgeCount() {
        let coreDataManager = CoreDataManager.shared
        let dueCards = coreDataManager.fetchDueCards()
        let badgeCount = dueCards.count
        
        DispatchQueue.main.async {
            UIApplication.shared.applicationIconBadgeNumber = badgeCount > 0 ? badgeCount : 0
        }
        
        print("📱 Badge count updated: \(badgeCount)")
    }
    
    // MARK: - Cleanup
    
    /// Removes old/past-due review notifications and cleans up
    func cleanupOldNotifications() {
        let center = UNUserNotificationCenter.current()
        
        center.getPendingNotificationRequests { requests in
            var identifiersToRemove: [String] = []
            let now = Date()
            
            for request in requests {
                // Check if it's a review reminder
                if request.identifier.hasPrefix("review_") {
                    if let trigger = request.trigger as? UNCalendarNotificationTrigger,
                       let nextTriggerDate = trigger.nextTriggerDate(),
                       nextTriggerDate < now {
                        // Notification is past due, remove it
                        identifiersToRemove.append(request.identifier)
                    }
                }
            }
            
            if !identifiersToRemove.isEmpty {
                center.removePendingNotificationRequests(withIdentifiers: identifiersToRemove)
                print("🧹 Cleaned up \(identifiersToRemove.count) old review notifications")
            }
            
            // Also remove delivered notifications that are old
            center.getDeliveredNotifications { delivered in
                var deliveredToRemove: [String] = []
                let now = Date()
                for notification in delivered {
                    // Remove delivered notifications older than 1 day
                    // notification.date is a non-optional Date
                    if notification.date.timeIntervalSince(now) < -86400 {
                        deliveredToRemove.append(notification.request.identifier)
                    }
                }
                
                if !deliveredToRemove.isEmpty {
                    center.removeDeliveredNotifications(withIdentifiers: deliveredToRemove)
                    print("🧹 Cleaned up \(deliveredToRemove.count) old delivered notifications")
                }
            }
        }
    }
    
    /// Schedules review reminders for all due cards (used after study session)
    func scheduleReviewRemindersForDueCards() {
        let coreDataManager = CoreDataManager.shared
        let dueCards = coreDataManager.fetchDueCards()
        
        // Clean up old notifications first
        cleanupOldNotifications()
        
        // Limit to 64 notifications (iOS limit is 64 pending)
        let cardsToSchedule = Array(dueCards.prefix(64))
        
        for card in cardsToSchedule {
            scheduleReviewReminder(for: card)
        }
        
        // Update badge count
        updateBadgeCount()
        
        print("📅 Scheduled review reminders for \(cardsToSchedule.count) cards")
    }
    
    func scheduleReviewReminder(for flashcard: Flashcard) {
        // Only schedule if nextReview is in the future
        guard flashcard.nextReview > Date() else {
            return
        }
        
        let content = UNMutableNotificationContent()
        content.title = "Time to Review!"
        content.body = "Ready to review '\(flashcard.word)'?"
        content.sound = UNNotificationSound.default
        content.categoryIdentifier = "REVIEW_REMINDER"
        content.userInfo = ["flashcardId": flashcard.id.uuidString]
        
        // Update badge count
        let coreDataManager = CoreDataManager.shared
        let dueCards = coreDataManager.fetchDueCards()
        content.badge = NSNumber(value: dueCards.count)
        
        let trigger = UNCalendarNotificationTrigger(
            dateMatching: Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: flashcard.nextReview),
            repeats: false
        )
        
        let request = UNNotificationRequest(
            identifier: "review_\(flashcard.id.uuidString)",
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("❌ Review reminder scheduling error for \(flashcard.word): \(error)")
            }
        }
    }
} 