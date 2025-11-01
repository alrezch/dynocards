//
//  Extensions.swift
//  Dynocards
//
//  Created by User on 2024
//

import SwiftUI
import Foundation

// MARK: - Date Extensions
extension Date {
    var isToday: Bool {
        Calendar.current.isDateInToday(self)
    }
    
    var isYesterday: Bool {
        Calendar.current.isDateInYesterday(self)
    }
    
    func daysFromNow() -> Int {
        Calendar.current.dateComponents([.day], from: Date(), to: self).day ?? 0
    }
    
    func timeAgoDisplay() -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: self, relativeTo: Date())
    }
}

// MARK: - Color Extensions
extension Color {
    static let dynamicBackground = Color(.systemBackground)
    static let dynamicSecondaryBackground = Color(.secondarySystemBackground)
    static let dynamicTertiary = Color(.tertiarySystemBackground)
    
    static let leitnerBox1 = Color.red.opacity(0.7)
    static let leitnerBox2 = Color.orange.opacity(0.7)
    static let leitnerBox3 = Color.yellow.opacity(0.7)
    static let leitnerBox4 = Color.green.opacity(0.7)
    static let leitnerBox5 = Color.blue.opacity(0.7)
    
    static func leitnerBoxColor(for box: Int16) -> Color {
        switch box {
        case 1: return .leitnerBox1
        case 2: return .leitnerBox2
        case 3: return .leitnerBox3
        case 4: return .leitnerBox4
        case 5: return .leitnerBox5
        default: return .gray
        }
    }
}

// MARK: - String Extensions
extension String {
    func localizedCapitalized() -> String {
        return self.localizedCapitalized
    }
    
    var isValidWord: Bool {
        let trimmed = self.trimmingCharacters(in: .whitespacesAndNewlines)
        return !trimmed.isEmpty && trimmed.count >= 2
    }
    
    func truncated(to length: Int) -> String {
        if self.count <= length {
            return self
        }
        return String(self.prefix(length)) + "..."
    }
}

// MARK: - View Extensions
extension View {
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
    
    func cardStyle() -> some View {
        self
            .padding()
            .background(Color.dynamicBackground)
            .cornerRadius(12)
            .shadow(color: .gray.opacity(0.2), radius: 4, x: 0, y: 2)
    }
    
    func primaryButtonStyle() -> some View {
        self
            .font(.headline)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.blue)
            .cornerRadius(12)
    }
    
    func secondaryButtonStyle() -> some View {
        self
            .font(.headline)
            .foregroundColor(.blue)
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.blue.opacity(0.1))
            .cornerRadius(12)
    }
}

// MARK: - Haptic Feedback
struct HapticManager {
    static func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        let impactFeedback = UIImpactFeedbackGenerator(style: style)
        impactFeedback.impactOccurred()
    }
    
    static func notification(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        let notificationFeedback = UINotificationFeedbackGenerator()
        notificationFeedback.notificationOccurred(type)
    }
    
    static func selection() {
        let selectionFeedback = UISelectionFeedbackGenerator()
        selectionFeedback.selectionChanged()
    }
}

// MARK: - UserDefaults Extensions
extension UserDefaults {
    private enum Keys {
        static let hasSeenOnboarding = "hasSeenOnboarding"
        static let lastAppVersion = "lastAppVersion"
        static let dailyGoalReminder = "dailyGoalReminder"
    }
    
    var hasSeenOnboarding: Bool {
        get { bool(forKey: Keys.hasSeenOnboarding) }
        set { set(newValue, forKey: Keys.hasSeenOnboarding) }
    }
    
    var lastAppVersion: String {
        get { string(forKey: Keys.lastAppVersion) ?? "1.0.0" }
        set { set(newValue, forKey: Keys.lastAppVersion) }
    }
    
    var dailyGoalReminder: Bool {
        get { bool(forKey: Keys.dailyGoalReminder) }
        set { set(newValue, forKey: Keys.dailyGoalReminder) }
    }
} 