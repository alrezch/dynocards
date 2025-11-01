//
//  SettingsView.swift
//  Dynocards
//
//  Created by User on 2024
//

import SwiftUI
import CoreData

struct SettingsView: View {
    @StateObject private var coreDataManager = CoreDataManager.shared
    @StateObject private var notificationService = NotificationService.shared
    @StateObject private var aiService = AIService.shared
    
    @State private var user: User?
    @State private var showingWelcome = false
    @State private var showingSubscription = false
    @State private var showingDataExport = false
    @State private var showingDeleteConfirmation = false
    @State private var showingAbout = false
    
    // Settings
    @State private var notificationsEnabled = false
    @State private var dailyReminderTime = Date()
    @State private var studyGoal = 10
    @State private var soundEnabled = true
    @State private var hapticEnabled = true
    @State private var autoPlayAudio = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header Section
                    headerSection
                    
                    // Profile Card
                    profileCard
                    
                    // Subscription Card
                    subscriptionCard
                    
                    // Study Settings
                    studySettingsCard
                    
                    // Notifications Card
                    notificationsCard
                    
                    // Audio & Haptics Card
                    audioHapticsCard
                    
                    // Data & Privacy Card
                    dataPrivacyCard
                    
                    // Support & Info Card
                    supportInfoCard
                    
                    // Danger Zone
                    dangerZoneCard
                }
                .padding(.horizontal, 20)
                .padding(.top, 10)
            }
            .navigationBarHidden(true)
            .background(
                LinearGradient(
                    colors: [
                        Color(.systemBackground),
                        Color.gray.opacity(0.02),
                        Color.blue.opacity(0.01)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
        }
        .onAppear {
            loadUserData()
            loadSettings()
        }
        .sheet(isPresented: $showingSubscription) {
            SubscriptionView()
        }
        .sheet(isPresented: $showingDataExport) {
            ExportDataView()
        }
        .sheet(isPresented: $showingAbout) {
            AboutView()
        }
        .fullScreenCover(isPresented: $showingWelcome) {
            ContentView()
        }
        .alert("Delete All Data", isPresented: $showingDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                deleteAllData()
            }
        } message: {
            Text("This will permanently delete all your flashcards, progress, and settings. This cannot be undone.")
        }
    }
    
    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Settings")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Text("Customize your learning experience")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Settings Icon
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.gray.opacity(0.1), .blue.opacity(0.05)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 50, height: 50)
                
                Image(systemName: "gearshape.fill")
                    .font(.title2)
                    .foregroundColor(.blue)
            }
        }
    }
    
    private var profileCard: some View {
        VStack(spacing: 16) {
            HStack {
                // Profile Avatar
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [.blue, .purple],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 60, height: 60)
                    
                    Text((user?.name?.prefix(1))?.uppercased() ?? "U")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(user?.name ?? "Dynocards User")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Text("Level \(calculateLevel(points: Int(user?.totalPoints ?? 0)))")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    HStack(spacing: 12) {
                        HStack(spacing: 4) {
                            Image(systemName: "star.fill")
                                .font(.caption)
                                .foregroundColor(.yellow)
                            
                            Text("\(user?.totalPoints ?? 0) points")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        HStack(spacing: 4) {
                            Image(systemName: "flame.fill")
                                .font(.caption)
                                .foregroundColor(.orange)
                            
                            Text("\(user?.streakCount ?? 0) day streak")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                Spacer()
                
                Button("Edit") {
                    // Edit profile
                }
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.blue)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.blue.opacity(0.1))
                .cornerRadius(8)
            }
        }
        .padding(20)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
    }
    
    private var subscriptionCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Subscription")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    let status = aiService.getSubscriptionStatus()
                    Text(status.isActive ? "Premium Active" : "Basic Plan")
                        .font(.caption)
                        .foregroundColor(status.isActive ? .green : .secondary)
                }
                
                Spacer()
                
                Image(systemName: status.isActive ? "crown.fill" : "crown")
                    .font(.title2)
                    .foregroundColor(status.isActive ? .yellow : .gray)
            }
            
            if status.isActive {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("✅ AI-powered flashcard generation")
                            .font(.subheadline)
                            .foregroundColor(.primary)
                        
                        Spacer()
                    }
                    
                    HStack {
                        Text("✅ Unlimited cards")
                            .font(.subheadline)
                            .foregroundColor(.primary)
                        
                        Spacer()
                    }
                    
                    HStack {
                        Text("✅ Advanced analytics")
                            .font(.subheadline)
                            .foregroundColor(.primary)
                        
                        Spacer()
                    }
                    
                    if let expiryDate = status.expiryDate {
                        Text("Renews on \(formattedDate(expiryDate))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.top, 4)
                    }
                }
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Upgrade to Premium for:")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("• AI-powered content generation")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text("• Unlimited flashcards")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text("• Advanced progress tracking")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Button(status.isActive ? "Manage Subscription" : "Upgrade to Premium") {
                showingSubscription = true
            }
            .font(.subheadline)
            .fontWeight(.medium)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                LinearGradient(
                    colors: status.isActive ? [.blue, .purple] : [.green, .mint],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(12)
        }
        .padding(20)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
    }
    
    private var studySettingsCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Study Settings")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Text("Customize your learning goals")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "target")
                    .font(.title2)
                    .foregroundColor(.green)
            }
            
            VStack(spacing: 16) {
                // Daily Goal
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Daily Study Goal")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        Text("\(studyGoal) cards")
                            .font(.subheadline)
                            .fontWeight(.bold)
                            .foregroundColor(.green)
                    }
                    
                    Slider(value: Binding(
                        get: { Double(studyGoal) },
                        set: { studyGoal = Int($0) }
                    ), in: 5...50, step: 5)
                    .accentColor(.green)
                }
                
                Divider()
                
                // Auto-advance
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Auto-advance Cards")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                        
                        Text("Automatically move to next card after answering")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Toggle("", isOn: .constant(true))
                        .labelsHidden()
                }
            }
        }
        .padding(20)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
    }
    
    private var notificationsCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Notifications")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Text("Stay on track with reminders")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "bell.fill")
                    .font(.title2)
                    .foregroundColor(.orange)
            }
            
            VStack(spacing: 16) {
                // Enable Notifications
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Daily Reminders")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                        
                        Text("Get reminded to study every day")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Toggle("", isOn: $notificationsEnabled)
                        .labelsHidden()
                        .onChange(of: notificationsEnabled) { _ in
                            updateNotificationSettings()
                        }
                }
                
                if notificationsEnabled {
                    Divider()
                    
                    // Reminder Time
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Reminder Time")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.primary)
                            
                            Text("When to send daily reminders")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        DatePicker("", selection: $dailyReminderTime, displayedComponents: .hourAndMinute)
                            .labelsHidden()
                            .onChange(of: dailyReminderTime) { _ in
                                updateNotificationSettings()
                            }
                    }
                }
            }
        }
        .padding(20)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
    }
    
    private var audioHapticsCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Audio & Haptics")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Text("Sound and vibration settings")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "speaker.wave.2.fill")
                    .font(.title2)
                    .foregroundColor(.blue)
            }
            
            VStack(spacing: 16) {
                // Sound Effects
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Sound Effects")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                        
                        Text("Play sounds for interactions")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Toggle("", isOn: $soundEnabled)
                        .labelsHidden()
                }
                
                Divider()
                
                // Haptic Feedback
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Haptic Feedback")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                        
                        Text("Vibration for feedback")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Toggle("", isOn: $hapticEnabled)
                        .labelsHidden()
                }
                
                Divider()
                
                // Auto-play Audio
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Auto-play Pronunciation")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                        
                        Text("Automatically play word pronunciation")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Toggle("", isOn: $autoPlayAudio)
                        .labelsHidden()
                }
            }
        }
        .padding(20)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
    }
    
    private var dataPrivacyCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Data & Privacy")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Text("Manage your data and privacy")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "shield.fill")
                    .font(.title2)
                    .foregroundColor(.mint)
            }
            
            VStack(spacing: 12) {
                // Export Data
                Button(action: {
                    showingDataExport = true
                }) {
                    HStack {
                        Image(systemName: "square.and.arrow.up")
                            .font(.subheadline)
                            .foregroundColor(.blue)
                        
                        Text("Export My Data")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 8)
                }
                
                Divider()
                
                // Privacy Policy
                Button(action: {
                    // Open privacy policy
                }) {
                    HStack {
                        Image(systemName: "doc.text")
                            .font(.subheadline)
                            .foregroundColor(.purple)
                        
                        Text("Privacy Policy")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 8)
                }
                
                Divider()
                
                // Terms of Service
                Button(action: {
                    // Open terms of service
                }) {
                    HStack {
                        Image(systemName: "doc.plaintext")
                            .font(.subheadline)
                            .foregroundColor(.orange)
                        
                        Text("Terms of Service")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 8)
                }
            }
        }
        .padding(20)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
    }
    
    private var supportInfoCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Support & Info")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Text("Get help and learn more")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "questionmark.circle.fill")
                    .font(.title2)
                    .foregroundColor(.indigo)
            }
            
            VStack(spacing: 12) {
                // Help & FAQ
                Button(action: {
                    // Open help
                }) {
                    HStack {
                        Image(systemName: "questionmark.circle")
                            .font(.subheadline)
                            .foregroundColor(.blue)
                        
                        Text("Help & FAQ")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 8)
                }
                
                Divider()
                
                // Contact Support
                Button(action: {
                    // Contact support
                }) {
                    HStack {
                        Image(systemName: "envelope")
                            .font(.subheadline)
                            .foregroundColor(.green)
                        
                        Text("Contact Support")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 8)
                }
                
                Divider()
                
                // Rate App
                Button(action: {
                    // Rate app
                }) {
                    HStack {
                        Image(systemName: "star")
                            .font(.subheadline)
                            .foregroundColor(.yellow)
                        
                        Text("Rate Dynocards")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 8)
                }
                
                Divider()
                
                // About
                Button(action: {
                    showingAbout = true
                }) {
                    HStack {
                        Image(systemName: "info.circle")
                            .font(.subheadline)
                            .foregroundColor(.purple)
                        
                        Text("About Dynocards")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 8)
                }
            }
        }
        .padding(20)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
    }
    
    private var dangerZoneCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Danger Zone")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.red)
                    
                    Text("Irreversible actions")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.title2)
                    .foregroundColor(.red)
            }
            
            VStack(spacing: 12) {
                // Reset to Welcome
                Button(action: {
                    showingWelcome = true
                }) {
                    HStack {
                        Image(systemName: "arrow.counterclockwise")
                            .font(.subheadline)
                            .foregroundColor(.orange)
                        
                        Text("Reset to Welcome Screen")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 8)
                }
                
                Divider()
                
                // Delete All Data
                Button(action: {
                    showingDeleteConfirmation = true
                }) {
                    HStack {
                        Image(systemName: "trash")
                            .font(.subheadline)
                            .foregroundColor(.red)
                        
                        Text("Delete All Data")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.red)
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 8)
                }
            }
        }
        .padding(20)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.red.opacity(0.2), lineWidth: 1)
        )
    }
    
    // MARK: - Helper Methods
    
    private func loadUserData() {
        user = coreDataManager.getOrCreateUser()
    }
    
    private func loadSettings() {
        // Load notification settings
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                notificationsEnabled = settings.authorizationStatus == .authorized
            }
        }
        
        // Load other settings from UserDefaults
        studyGoal = UserDefaults.standard.integer(forKey: "studyGoal") != 0 ? UserDefaults.standard.integer(forKey: "studyGoal") : 10
        soundEnabled = UserDefaults.standard.bool(forKey: "soundEnabled")
        hapticEnabled = UserDefaults.standard.bool(forKey: "hapticEnabled")
        autoPlayAudio = UserDefaults.standard.bool(forKey: "autoPlayAudio")
        
        if let reminderTimeData = UserDefaults.standard.data(forKey: "dailyReminderTime") {
            dailyReminderTime = try! JSONDecoder().decode(Date.self, from: reminderTimeData)
        }
    }
    
    private func updateNotificationSettings() {
        if notificationsEnabled {
            notificationService.scheduleStudyReminder(at: dailyReminderTime)
        } else {
            notificationService.clearNotifications()
        }
        
        // Save settings
        UserDefaults.standard.set(studyGoal, forKey: "studyGoal")
        UserDefaults.standard.set(soundEnabled, forKey: "soundEnabled")
        UserDefaults.standard.set(hapticEnabled, forKey: "hapticEnabled")
        UserDefaults.standard.set(autoPlayAudio, forKey: "autoPlayAudio")
        
        if let reminderTimeData = try? JSONEncoder().encode(dailyReminderTime) {
            UserDefaults.standard.set(reminderTimeData, forKey: "dailyReminderTime")
        }
    }
    
    private func deleteAllData() {
        coreDataManager.deleteAllData()
        
        // Reset user defaults
        UserDefaults.standard.removeObject(forKey: "studyGoal")
        UserDefaults.standard.removeObject(forKey: "soundEnabled")
        UserDefaults.standard.removeObject(forKey: "hapticEnabled")
        UserDefaults.standard.removeObject(forKey: "autoPlayAudio")
        UserDefaults.standard.removeObject(forKey: "dailyReminderTime")
        
        // Cancel notifications
        notificationService.clearNotifications()
        
        // Show welcome screen
        showingWelcome = true
    }
    
    private func calculateLevel(points: Int) -> Int {
        return max(1, points / 100)
    }
    
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
    
    private var status: (isActive: Bool, expiryDate: Date?) {
        let fullStatus = aiService.getSubscriptionStatus()
        return (isActive: fullStatus.isActive, expiryDate: fullStatus.expiryDate)
    }
}

// MARK: - Supporting Views

struct AboutView: View {
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // App Icon and Info
                    VStack(spacing: 16) {
                        Image(systemName: "brain.head.profile")
                            .font(.system(size: 80))
                            .foregroundColor(.blue)
                        
                        Text("Dynocards")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        Text("Version 1.0.0")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Text("AI-Powered Flashcard Learning")
                            .font(.headline)
                            .foregroundColor(.blue)
                    }
                    
                    // Description
                    VStack(alignment: .leading, spacing: 12) {
                        Text("About")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        Text("Dynocards is an intelligent flashcard app that uses AI to help you learn vocabulary more effectively. With spaced repetition, personalized content, and beautiful design, learning has never been more engaging.")
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(20)
                    .background(Color(.systemBackground))
                    .cornerRadius(16)
                    .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
                    
                    // Credits
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Credits")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        Text("Developed with ❤️ using SwiftUI, Core Data, and OpenAI's ChatGPT API.")
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(20)
                    .background(Color(.systemBackground))
                    .cornerRadius(16)
                    .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
                }
                .padding(.horizontal, 20)
            }
            .navigationTitle("About")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

#Preview {
    SettingsView()
} 