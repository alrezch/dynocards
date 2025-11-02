//
//  SocialShareCardView.swift
//  Dynocards
//
//  Created by User on 2024
//

import SwiftUI

struct SocialShareCardView: View {
    @StateObject private var coreDataManager = CoreDataManager.shared
    @State private var user: User?
    @State private var totalWords: Int = 0
    @State private var masteredWords: Int = 0
    @State private var totalExams: Int = 0
    @State private var examSuccessRate: Double = 0.0
    @State private var showingShareSheet = false
    @State private var shareImage: UIImage?
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background Gradient
                LinearGradient(
                    colors: [
                        Color.blue.opacity(0.1),
                        Color.purple.opacity(0.05),
                        Color.pink.opacity(0.03)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Header
                        VStack(spacing: 8) {
                            Text("Share Your Progress")
                                .font(.largeTitle)
                                .fontWeight(.bold)
                            
                            Text("Show off your learning achievements!")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .padding(.top)
                        
                        // Social Card Preview
                        if let user = user {
                            socialCard(user: user)
                                .padding(.horizontal)
                                .shadow(color: .black.opacity(0.2), radius: 20, x: 0, y: 10)
                        }
                        
                        // Share Button
                        Button(action: {
                            generateAndShareImage()
                        }) {
                            HStack {
                                Image(systemName: "square.and.arrow.up")
                                    .font(.headline)
                                
                                Text("Share to Social Media")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                LinearGradient(
                                    colors: [.blue, .purple],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(16)
                            .shadow(color: .blue.opacity(0.3), radius: 10, x: 0, y: 5)
                        }
                        .padding(.horizontal)
                        .padding(.bottom)
                        
                        // Stats Breakdown
                        if let user = user {
                            statsBreakdown(user: user)
                                .padding(.horizontal)
                        }
                    }
                }
            }
            .navigationTitle("Share Progress")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                loadUserData()
            }
            .sheet(isPresented: $showingShareSheet) {
                if let shareImage = shareImage {
                    ShareSheet(activityItems: [shareImage])
                }
            }
        }
    }
    
    private func socialCard(user: User) -> some View {
        VStack(spacing: 20) {
            // App Logo/Header
            HStack {
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
                    
                    Image(systemName: "brain.head.profile")
                        .font(.system(size: 30))
                        .foregroundColor(.white)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Dynocards")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Text("AI-Powered Learning")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            
            Divider()
            
            // Profile Section
            HStack(spacing: 16) {
                // Profile Image or Initials
                if let profileImage = user.profileImage {
                    Image(uiImage: profileImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 80, height: 80)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color.blue.opacity(0.3), lineWidth: 3))
                } else {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [.blue, .purple],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 80, height: 80)
                        
                        Text((user.name?.prefix(1))?.uppercased() ?? "U")
                            .font(.system(size: 36, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
                
                VStack(alignment: .leading, spacing: 6) {
                    Text(user.name ?? "Dynocards User")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Text("Level \(calculateLevel(points: Int(user.totalPoints)))")
                        .font(.headline)
                        .foregroundColor(.blue)
                    
                    if let dateJoined = user.dateJoined {
                        Text("Learning since \(formattedMonthYear(dateJoined))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
            }
            
            Divider()
            
            // Achievements Grid
            VStack(spacing: 16) {
                HStack(spacing: 16) {
                    StatBox(
                        icon: "flame.fill",
                        value: "\(user.streakCount)",
                        label: "Day Streak",
                        color: .orange
                    )
                    
                    StatBox(
                        icon: "star.fill",
                        value: "\(user.totalPoints)",
                        label: "Points",
                        color: .yellow
                    )
                    
                    StatBox(
                        icon: "book.fill",
                        value: "\(totalWords)",
                        label: "Words",
                        color: .blue
                    )
                }
                
                HStack(spacing: 16) {
                    StatBox(
                        icon: "checkmark.circle.fill",
                        value: "\(masteredWords)",
                        label: "Mastered",
                        color: .green
                    )
                    
                    StatBox(
                        icon: "doc.text.fill",
                        value: "\(totalExams)",
                        label: "Exams",
                        color: .purple
                    )
                    
                    StatBox(
                        icon: "chart.bar.fill",
                        value: "\(Int(examSuccessRate))%",
                        label: "Success Rate",
                        color: .mint
                    )
                }
            }
            
            // Footer
            Text("Learning vocabulary with AI-powered flashcards")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.top, 8)
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color(.systemBackground))
        )
        .frame(width: UIScreen.main.bounds.width - 40)
    }
    
    private func statsBreakdown(user: User) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Your Learning Stats")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 12) {
                StatRow(
                    icon: "flame.fill",
                    label: "Current Streak",
                    value: "\(user.streakCount) days",
                    color: .orange
                )
                
                StatRow(
                    icon: "star.fill",
                    label: "Total Points",
                    value: "\(user.totalPoints)",
                    color: .yellow
                )
                
                StatRow(
                    icon: "book.fill",
                    label: "Total Words",
                    value: "\(totalWords)",
                    color: .blue
                )
                
                StatRow(
                    icon: "checkmark.circle.fill",
                    label: "Mastered Words",
                    value: "\(masteredWords)",
                    color: .green
                )
                
                StatRow(
                    icon: "doc.text.fill",
                    label: "Exams Completed",
                    value: "\(totalExams)",
                    color: .purple
                )
                
                StatRow(
                    icon: "chart.bar.fill",
                    label: "Exam Success Rate",
                    value: String(format: "%.1f%%", examSuccessRate),
                    color: .mint
                )
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
        )
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
    }
    
    private func loadUserData() {
        user = coreDataManager.getOrCreateUser()
        
        // Load statistics
        let allFlashcards = coreDataManager.fetchAllFlashcards()
        totalWords = allFlashcards.count
        masteredWords = allFlashcards.filter { $0.mastered }.count
        
        // Load exam statistics
        let examSessions = coreDataManager.fetchExamSessions()
        totalExams = examSessions.count
        
        if totalExams > 0 {
            let totalQuestions = examSessions.reduce(0) { $0 + Int($1.totalQuestions) }
            let correctAnswers = examSessions.reduce(0) { $0 + Int($1.correctAnswers) }
            examSuccessRate = totalQuestions > 0 ? (Double(correctAnswers) / Double(totalQuestions)) * 100 : 0
        }
    }
    
    private func calculateLevel(points: Int) -> Int {
        return max(1, points / 100)
    }
    
    private func formattedMonthYear(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: date)
    }
    
    private func generateAndShareImage() {
        guard let user = user else { return }
        
        // Create a snapshot of the social card
        // ImageRenderer requires iOS 16+
        if #available(iOS 16.0, *) {
            let cardView = socialCard(user: user)
                .frame(width: 1080, height: 1350) // Instagram story size (9:16 aspect ratio)
                .background(Color.white)
            
            let renderer = ImageRenderer(content: cardView)
            renderer.scale = 3.0 // High resolution for social media (retina @3x)
            renderer.proposedSize = .init(width: 1080, height: 1350)
            
            if let image = renderer.uiImage {
                shareImage = image
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    showingShareSheet = true
                }
            }
        } else {
            // For iOS < 16, we'll create a simpler version
            // Or prompt user to upgrade for sharing feature
            showingShareSheet = false
        }
    }
}

// MARK: - Supporting Views

struct StatBox: View {
    let icon: String
    let value: String
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(color.opacity(0.1))
        )
    }
}

struct StatRow: View {
    let icon: String
    let label: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
                .frame(width: 30)
            
            Text(label)
                .font(.subheadline)
                .foregroundColor(.primary)
            
            Spacer()
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
        }
        .padding(.vertical, 8)
    }
}

