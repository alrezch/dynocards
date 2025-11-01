//
//  NotificationService.swift
//  Dynocards
//
//  Created by User on 2024
//

import Foundation
import UserNotifications

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
        let content = UNMutableNotificationContent()
        content.title = "Time to Study!"
        content.body = "Don't forget to review your flashcards today 📚"
        content.sound = UNNotificationSound.default
        content.badge = 1
        
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
                print("Notification scheduling error: \(error)")
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
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        
        let request = UNNotificationRequest(
            identifier: "due_cards_\(Date().timeIntervalSince1970)",
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request)
    }
    
    func clearNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
    }
    
    func scheduleReviewReminder(for flashcard: Flashcard) {
        let content = UNMutableNotificationContent()
        content.title = "Time to Review!"
        content.body = "Ready to review '\(flashcard.word)'?"
        content.sound = UNNotificationSound.default
        
        let trigger = UNCalendarNotificationTrigger(
            dateMatching: Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: flashcard.nextReview),
            repeats: false
        )
        
        let request = UNNotificationRequest(
            identifier: "review_\(flashcard.id.uuidString)",
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request)
    }
} 