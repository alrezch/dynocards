//
//  DynocardsApp.swift
//  Dynocards
//
//  Created by User on 2024
//

import SwiftUI
import UserNotifications

@main
struct DynocardsApp: App {
    let coreDataManager = CoreDataManager.shared
    let notificationService = NotificationService.shared
    
    init() {
        // Create sample data on first launch
        coreDataManager.createSampleDataIfNeeded()
        
        // Request notification permission on app launch
        requestNotificationPermission()
    }
    
    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            // Only request if permission hasn't been determined yet
            if settings.authorizationStatus == .notDetermined {
                DispatchQueue.main.async {
                    notificationService.requestPermission()
                }
            }
        }
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, coreDataManager.context)
                .environmentObject(coreDataManager)
                .onAppear {
                    // Update badge count on app launch
                    updateBadgeCount()
                    
                    // Restore notification schedule if user has them enabled
                    restoreNotificationSchedule()
                }
        }
    }
    
    private func updateBadgeCount() {
        let dueCards = coreDataManager.fetchDueCards()
        let badgeCount = dueCards.count
        
        DispatchQueue.main.async {
            UIApplication.shared.applicationIconBadgeNumber = badgeCount > 0 ? badgeCount : 0
        }
    }
    
    private func restoreNotificationSchedule() {
        let user = coreDataManager.getOrCreateUser()
        if user.notificationsEnabled, let reminderTime = user.studyReminderTime {
            notificationService.scheduleStudyReminder(at: reminderTime)
        }
    }
} 