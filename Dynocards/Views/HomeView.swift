//
//  HomeView.swift
//  Dynocards
//
//  Created by User on 2024
//

import SwiftUI
import CoreData

struct HomeView: View {
    @StateObject private var coreDataManager = CoreDataManager.shared
    @State private var dueCards: [Flashcard] = []
    @State private var user: User?
    @State private var searchText = ""
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header Section
                    headerSection
                    
                    // Streak and Daily Goal Section
                    streakAndGoalSection
                    
                    // Collections Grid
                    collectionsSection
                }
                .padding(.horizontal, 20)
                .padding(.top, 10)
            }
            .navigationBarHidden(true)
            .background(
                LinearGradient(
                    colors: [
                        Color(.systemBackground),
                        Color.blue.opacity(0.03),
                        Color.purple.opacity(0.02)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .onAppear {
                loadData()
            }
        }
    }
    
    private var headerSection: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Home")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Text("Your learning dashboard")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                HStack(spacing: 12) {
                    Button(action: {}) {
                        Image(systemName: "magnifyingglass")
                            .font(.title2)
                            .foregroundColor(.secondary)
                    }
                    
                    NavigationLink(destination: AddWordView()) {
                        Image(systemName: "plus")
                            .font(.title2)
                            .foregroundColor(.white)
                            .frame(width: 36, height: 36)
                            .background(
                                LinearGradient(
                                    colors: [.blue, .purple],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .cornerRadius(10)
                    }
                }
            }
            
            // Search Bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                
                TextField("Search collections, words...", text: $searchText)
                    .textFieldStyle(PlainTextFieldStyle())
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
    }
    
    private var collectionsSection: some View {
        VStack(spacing: 16) {
            // Main Collections Grid - 3 columns
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 12),
                GridItem(.flexible(), spacing: 12),
                GridItem(.flexible(), spacing: 12)
            ], spacing: 12) {
                CollectionCard(
                    title: "Active Words",
                    count: coreDataManager.fetchFlashcards().filter { !$0.mastered }.count,
                    gradient: LinearGradient(
                        colors: [.mint.opacity(0.7), .cyan.opacity(0.5)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    destination: AnyView(AllCardsView())
                )
                
                Button(action: {
                    // Navigate to Study tab using NotificationCenter
                    NotificationCenter.default.post(name: NSNotification.Name("NavigateToStudy"), object: nil)
                }) {
                    CollectionCardButton(
                        title: "Due Today",
                        count: dueCards.count,
                        gradient: LinearGradient(
                            colors: [.orange.opacity(0.7), .red.opacity(0.5)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                }
                .buttonStyle(PlainButtonStyle())
                
                CollectionCard(
                    title: "All Words",
                    count: coreDataManager.fetchAllFlashcards().count,
                    gradient: LinearGradient(
                        colors: [.blue.opacity(0.7), .purple.opacity(0.5)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    destination: AnyView(AllWordsView())
                )
            }
        }
    }
    
    private var streakAndGoalSection: some View {
        HStack(spacing: 16) {
            // Streak Card
            VStack(spacing: 12) {
                HStack {
                    Image(systemName: "flame.fill")
                        .font(.title)
                        .foregroundColor(.orange)
                    
                    Spacer()
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(user?.streakCount ?? 0)")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Text("Day Streak")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            .padding(20)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.orange.opacity(0.1))
            )
            
            // Daily Goal Card
            VStack(spacing: 12) {
                HStack {
                    Image(systemName: "target")
                        .font(.title)
                        .foregroundColor(.blue)
                    
                    Spacer()
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(user?.dailyGoal ?? 10)")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Text("Daily Goal")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            .padding(20)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.blue.opacity(0.1))
            )
        }
    }
    
    
    private func loadData() {
        dueCards = coreDataManager.fetchDueCards()
        user = coreDataManager.getOrCreateUser()
    }
}

// MARK: - Supporting Views

struct CollectionCard: View {
    let title: String
    let count: Int
    let gradient: LinearGradient
    let destination: AnyView
    
    var body: some View {
        NavigationLink(destination: destination) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text(title)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                    
                    Spacer()
                }
                
                Spacer()
                
                Text("\(count)")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
            }
            .padding(20)
            .frame(height: 120)
            .background(gradient)
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct CollectionCardButton: View {
    let title: String
    let count: Int
    let gradient: LinearGradient
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                Spacer()
            }
            
            Spacer()
            
            Text("\(count)")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.white)
        }
        .padding(20)
        .frame(height: 120)
        .background(gradient)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
    }
}

struct ProgressCard: View {
    let title: String
    let count: Int
    let gradient: LinearGradient
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.white)
            
            Text("\(count)")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
        }
        .padding(16)
        .frame(height: 80)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(gradient)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}

struct GoalCard: View {
    let title: String
    let current: Int
    let target: Int
    let gradient: LinearGradient
    
    var progress: Double {
        guard target > 0 else { return 0 }
        return min(Double(current) / Double(target), 1.0)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                Spacer()
                
                Text("\(current)/\(target)")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.white.opacity(0.9))
            }
            
            ProgressView(value: progress)
                .progressViewStyle(LinearProgressViewStyle(tint: .white))
                .scaleEffect(y: 1.5)
        }
        .padding(20)
        .background(gradient)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 6, x: 0, y: 3)
    }
}

struct CategorySection: View {
    let title: String
    @State var isExpanded: Bool
    let content: AnyView
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Button(action: {
                withAnimation(.easeInOut(duration: 0.3)) {
                    isExpanded.toggle()
                }
            }) {
                HStack {
                    Text(title)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            .buttonStyle(PlainButtonStyle())
            
            if isExpanded {
                content
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
            }
        }
    }
}

struct FeaturedCard: View {
    let title: String
    let subtitle: String
    let icon: String
    let gradient: LinearGradient
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: icon)
                        .font(.title2)
                        .foregroundColor(.white)
                    
                    Spacer()
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.9))
                        .multilineTextAlignment(.leading)
                }
                
                Spacer()
            }
            .padding(16)
            .frame(width: 160, height: 120)
            .background(gradient)
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 4)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}

struct ActivityCard: View {
    let icon: String
    let title: String
    let subtitle: String
    let time: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            
            Spacer()
            
            Text(time)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(16)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.03), radius: 2, x: 0, y: 1)
    }
}

#Preview {
    HomeView()
} 