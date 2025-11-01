//
//  DashboardView.swift
//  Dynocards
//
//  Created by User on 2024
//

import SwiftUI
import CoreData

struct DashboardView: View {
    @StateObject private var coreDataManager = CoreDataManager.shared
    
    @State private var flashcards: [Flashcard] = []
    @State private var user: User?
    @State private var selectedTimeframe: TimeFrame = .week
    @State private var showingAllCards = false
    @State private var animationOffset: CGFloat = 0
    
    enum TimeFrame: String, CaseIterable {
        case day = "Today"
        case week = "This Week"
        case month = "This Month"
        case all = "All Time"
        
        var icon: String {
            switch self {
            case .day: return "sun.max.fill"
            case .week: return "calendar.badge.clock"
            case .month: return "calendar"
            case .all: return "infinity"
            }
        }
        
        var color: Color {
            switch self {
            case .day: return .orange
            case .week: return .blue
            case .month: return .purple
            case .all: return .green
            }
        }
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header Section
                    headerSection
                    
                    // Key Metrics Row
                    keyMetricsRow
                    
                    // Progress Chart Card
                    progressChartCard
                    
                    // Learning Streak Card
                    learningStreakCard
                    
                    // Performance Breakdown
                    performanceBreakdownCard
                    
                    // CEFR Distribution
                    cefrDistributionCard
                    
                    // Exam Statistics
                    examStatisticsCard
                    
                    // Recent Activity
                    recentActivityCard
                }
                .padding(.horizontal, 20)
                .padding(.top, 10)
            }
            .navigationBarHidden(true)
            .background(
                LinearGradient(
                    colors: [
                        Color(.systemBackground),
                        Color.blue.opacity(0.02),
                        Color.purple.opacity(0.01)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .refreshable {
                loadData()
            }
        }
        .onAppear {
            // Add a small delay to ensure Core Data is fully initialized
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                loadData()
                startHeaderAnimation()
                
                // Update existing flashcards with CEFR levels in the background
                Task {
                    await coreDataManager.updateExistingFlashcardsWithCEFRLevels()
                    // Reload data after migration to show updated CEFR levels
                    await MainActor.run {
                        loadData()
                    }
                }
            }
        }
        .sheet(isPresented: $showingAllCards) {
            AllCardsView()
        }
    }
    
    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 8) {
                Text("Your Progress")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                if let user = user {
                    HStack(spacing: 16) {
                        // Level Badge
                        HStack(spacing: 6) {
                            Image(systemName: "star.fill")
                                .font(.caption)
                                .foregroundColor(.yellow)
                            
                            Text("Level \(calculateLevel(points: Int(user.totalPoints)))")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.primary)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.yellow.opacity(0.1))
                        .cornerRadius(12)
                        
                        // Streak Badge
                        HStack(spacing: 6) {
                            Image(systemName: "flame.fill")
                                .font(.caption)
                                .foregroundColor(.orange)
                            
                            Text("\(user.streakCount) day streak")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.primary)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.orange.opacity(0.1))
                        .cornerRadius(12)
                    }
                }
            }
            
            Spacer()
            
            // Profile Avatar
            Button(action: {
                // Profile action
            }) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [.blue, .purple],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 50, height: 50)
                    
                    Text((user?.name?.prefix(1))?.uppercased() ?? "U")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                }
                .offset(x: animationOffset)
                .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: animationOffset)
            }
        }
    }
    
    private var timeframeSelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(TimeFrame.allCases, id: \.self) { timeframe in
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            selectedTimeframe = timeframe
                        }
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: timeframe.icon)
                                .font(.subheadline)
                            
                            Text(timeframe.rawValue)
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }
                        .foregroundColor(selectedTimeframe == timeframe ? .white : timeframe.color)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(
                            Group {
                                if selectedTimeframe == timeframe {
                                    LinearGradient(
                                        colors: [timeframe.color, timeframe.color.opacity(0.8)],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                } else {
                                    timeframe.color.opacity(0.1)
                                }
                            }
                        )
                        .cornerRadius(20)
                    }
                }
            }
            .padding(.horizontal, 20)
        }
    }
    
    private var keyMetricsRow: some View {
        HStack(spacing: 16) {
            // Total Cards
            MetricCard(
                title: "Total Cards",
                value: "\(flashcards.count)",
                icon: "rectangle.stack.fill",
                color: .blue,
                subtitle: "in collection"
            )
            
            // Study Streak
            MetricCard(
                title: "Study Streak",
                value: "\(user?.streakCount ?? 0)",
                icon: "flame.fill",
                color: .orange,
                subtitle: "days"
            )
            
            // Total Points
            MetricCard(
                title: "Total Points",
                value: "\(user?.totalPoints ?? 0)",
                icon: "star.fill",
                color: .yellow,
                subtitle: "earned"
            )
        }
    }
    
    private var progressChartCard: some View {
        let chartData = getLast7DaysPracticeData()
        let maxValue = max(chartData.max { $0.count < $1.count }?.count ?? 10, 10)
        
        return VStack(alignment: .leading, spacing: 20) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Learning Progress")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Text("Words practiced over time")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.title2)
                    .foregroundColor(.green)
            }
            
            // Progress Chart Visualization
            VStack(spacing: 16) {
                // Chart with Y-axis labels
                HStack(alignment: .bottom, spacing: 12) {
                    // Y-axis labels
                    VStack(alignment: .trailing, spacing: 0) {
                        ForEach((0...4).reversed(), id: \.self) { tick in
                            let value = Int(Double(tick) / 4.0 * Double(maxValue))
                            Text("\(value)")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                                .frame(height: chartHeight / 5)
                        }
                    }
                    .frame(width: 30)
                    
                    // Bars
                    HStack(alignment: .bottom, spacing: 8) {
                        ForEach(Array(chartData.enumerated()), id: \.offset) { index, data in
                            VStack(spacing: 6) {
                                // Bar with actual height based on data
                                let barHeight = data.count > 0 ? CGFloat(data.count) / CGFloat(maxValue) * chartHeight : 0
                                
                                VStack(spacing: 0) {
                                    Spacer()
                                    
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(
                                            LinearGradient(
                                                colors: [.green, .mint],
                                                startPoint: .bottom,
                                                endPoint: .top
                                            )
                                        )
                                        .frame(width: 28, height: max(barHeight, 4))
                                }
                                .frame(height: chartHeight)
                                
                                // Day initial label
                                Text(data.dayInitial)
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.primary)
                            }
                        }
                    }
                    
                    Spacer()
                }
                
                // Legend
                HStack {
                    Text("Last 7 days")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    HStack(spacing: 4) {
                        Circle()
                            .fill(Color.green)
                            .frame(width: 8, height: 8)
                        
                        Text("Words practiced")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding(20)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
    }
    
    private let chartHeight: CGFloat = 120
    
    private struct DayPracticeData {
        let dayInitial: String
        let count: Int
    }
    
    private func getLast7DaysPracticeData() -> [DayPracticeData] {
        let calendar = Calendar.current
        let today = Date()
        var data: [DayPracticeData] = []
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "EEEE" // Full day name
        
        for i in 0..<7 {
            guard let date = calendar.date(byAdding: .day, value: -i, to: today) else { continue }
            let startOfDay = calendar.startOfDay(for: date)
            let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) ?? startOfDay
            
            // Count cards studied on this day
            let count = flashcards.filter { flashcard in
                if let lastStudied = flashcard.lastStudied {
                    return lastStudied >= startOfDay && lastStudied < endOfDay
                }
                return false
            }.count
            
            // Get first letter of day name
            let dayName = dateFormatter.string(from: date)
            let dayInitial = String(dayName.prefix(1)).uppercased()
            
            data.insert(DayPracticeData(dayInitial: dayInitial, count: count), at: 0)
        }
        
        return data
    }
    
    private var learningStreakCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Learning Streak")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Text("Keep your momentum going!")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "flame.fill")
                    .font(.title2)
                    .foregroundColor(.orange)
            }
            
            HStack(spacing: 20) {
                // Current Streak
                VStack(alignment: .leading, spacing: 8) {
                    Text("\(user?.streakCount ?? 0)")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundColor(.orange)
                    
                    Text("Current Streak")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Streak Calendar
                VStack(spacing: 4) {
                    HStack(spacing: 4) {
                        ForEach(0..<7, id: \.self) { day in
                            Circle()
                                .fill(day < (user?.streakCount ?? 0) ? Color.orange : Color.orange.opacity(0.2))
                                .frame(width: 12, height: 12)
                        }
                    }
                    
                    Text("This week")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            
            // Streak Goal Progress
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Goal: 30 days")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Text("\(Int(Double(user?.streakCount ?? 0) / 30.0 * 100))%")
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundColor(.orange)
                }
                
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.orange.opacity(0.2))
                            .frame(height: 8)
                        
                        RoundedRectangle(cornerRadius: 4)
                            .fill(
                                LinearGradient(
                                    colors: [.orange, .red],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: geometry.size.width * min(Double(user?.streakCount ?? 0) / 30.0, 1.0), height: 8)
                            .animation(.easeInOut(duration: 1), value: user?.streakCount)
                    }
                }
                .frame(height: 8)
            }
        }
        .padding(20)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
    }
    
    private var performanceBreakdownCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Performance Breakdown")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Text("Your learning distribution")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chart.pie.fill")
                    .font(.title2)
                    .foregroundColor(.purple)
            }
            
            VStack(spacing: 12) {
                // Leitner Box Distribution
                ForEach(1...5, id: \.self) { box in
                    let cardsInBox = flashcards.filter { $0.leitnerBox == box }.count
                    let percentage = flashcards.isEmpty ? 0.0 : Double(cardsInBox) / Double(flashcards.count)
                    let boxInfo = getBoxInfo(for: box)
                    
                    HStack(spacing: 12) {
                        // Box indicator
                        RoundedRectangle(cornerRadius: 4)
                            .fill(boxColor(for: box))
                            .frame(width: 12, height: 12)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            HStack(spacing: 4) {
                                Text("Box \(box)")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(.primary)
                                
                                Text("•")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                Text(boxInfo.title)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Text(boxInfo.interval)
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Text("\(cardsInBox)")
                            .font(.subheadline)
                            .fontWeight(.bold)
                            .foregroundColor(.secondary)
                        
                        // Progress bar
                        GeometryReader { geometry in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(Color(.systemGray5))
                                    .frame(height: 4)
                                
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(boxColor(for: box))
                                    .frame(width: geometry.size.width * percentage, height: 4)
                                    .animation(.easeInOut(duration: 0.8), value: percentage)
                            }
                        }
                        .frame(width: 60, height: 4)
                    }
                }
            }
        }
        .padding(20)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
    }
    
    private var cefrDistributionCard: some View {
        let distribution = getCEFRDistribution()
        
        return VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("CEFR Level Distribution")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Text("Vocabulary by proficiency level")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chart.bar.fill")
                    .font(.title2)
                    .foregroundColor(.indigo)
            }
            
            VStack(spacing: 12) {
                // CEFR Levels
                ForEach(["A1", "A2", "B1", "B2", "C1", "C2"], id: \.self) { level in
                    let count = distribution[level] ?? 0
                    let totalCards = flashcards.count
                    let percentage = totalCards > 0 ? Double(count) / Double(totalCards) : 0.0
                    
                    HStack(spacing: 12) {
                        // Level badge
                        Text(level)
                            .font(.subheadline)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .frame(width: 40, height: 32)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(cefrLevelColor(level))
                            )
                        
                        // Count
                        Text("\(count)")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                            .frame(width: 40, alignment: .leading)
                        
                        // Word label
                        Text(count == 1 ? "word" : "words")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .frame(width: 50, alignment: .leading)
                        
                        Spacer()
                        
                        // Progress bar
                        GeometryReader { geometry in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 3)
                                    .fill(Color(.systemGray5))
                                    .frame(height: 6)
                                
                                RoundedRectangle(cornerRadius: 3)
                                    .fill(cefrLevelColor(level))
                                    .frame(width: geometry.size.width * percentage, height: 6)
                                    .animation(.easeInOut(duration: 0.8), value: percentage)
                            }
                        }
                        .frame(height: 6)
                    }
                }
            }
        }
        .padding(20)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
    }
    
    private var recentActivityCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Recent Activity")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Text("Your latest learning sessions")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "clock.fill")
                    .font(.title2)
                    .foregroundColor(.mint)
            }
            
            VStack(spacing: 12) {
                // Recent study sessions (mock data)
                ForEach(0..<3, id: \.self) { index in
                    HStack(spacing: 12) {
                        // Activity icon
                        ZStack {
                            Circle()
                                .fill(activityColor(for: index).opacity(0.2))
                                .frame(width: 32, height: 32)
                            
                            Image(systemName: activityIcon(for: index))
                                .font(.caption)
                                .foregroundColor(activityColor(for: index))
                        }
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(activityTitle(for: index))
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.primary)
                            
                            Text(activitySubtitle(for: index))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Text(activityTime(for: index))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Button("View All Activity") {
                // Show full activity log
            }
            .font(.subheadline)
            .fontWeight(.medium)
            .foregroundColor(.blue)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(Color.blue.opacity(0.1))
            .cornerRadius(8)
        }
        .padding(20)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
    }
    
    private var quickActionsCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Quick Actions")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 2), spacing: 12) {
                // Study Now
                QuickActionButton(
                    title: "Study Now",
                    subtitle: "Review due cards",
                    icon: "brain.head.profile",
                    color: .green
                ) {
                    // Navigate to study
                }
                
                // Add Words
                QuickActionButton(
                    title: "Add Words",
                    subtitle: "Expand vocabulary",
                    icon: "plus.circle.fill",
                    color: .blue
                ) {
                    // Navigate to add words
                }
                
                // View All Cards
                QuickActionButton(
                    title: "All Cards",
                    subtitle: "Browse collection",
                    icon: "rectangle.stack.fill",
                    color: .purple
                ) {
                    showingAllCards = true
                }
                
                // Export Data
                QuickActionButton(
                    title: "Export Data",
                    subtitle: "Backup progress",
                    icon: "square.and.arrow.up.fill",
                    color: .orange
                ) {
                    // Show export options
                }
            }
        }
        .padding(20)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
    }
    
    // MARK: - Helper Methods
    
    private func loadData() {
        print("🔄 Loading dashboard data...")
        
        // Use the CoreDataManager's methods instead of direct fetch
        flashcards = coreDataManager.fetchFlashcards()
        user = coreDataManager.getOrCreateUser()
        
        print("✅ Dashboard data loaded successfully - \(flashcards.count) flashcards, user: \(user?.name ?? "nil")")
    }
    
    private func startHeaderAnimation() {
        animationOffset = 3
    }
    
    private func calculateLevel(points: Int) -> Int {
        return max(1, points / 100)
    }
    
    private func boxColor(for box: Int) -> Color {
        switch box {
        case 1: return .red
        case 2: return .orange
        case 3: return .yellow
        case 4: return .green
        case 5: return .blue
        default: return .gray
        }
    }
    
    private func getBoxInfo(for box: Int) -> (title: String, interval: String) {
        switch box {
        case 1: return ("New", "Daily")
        case 2: return ("Familiar", "Every 3 days")
        case 3: return ("Known", "Weekly")
        case 4: return ("Well-known", "Bi-weekly")
        case 5: return ("Mastered", "Monthly")
        default: return ("", "")
        }
    }
    
    private func activityColor(for index: Int) -> Color {
        let colors: [Color] = [.green, .blue, .purple]
        return colors[index % colors.count]
    }
    
    private func activityIcon(for index: Int) -> String {
        let icons = ["checkmark.circle.fill", "plus.circle.fill", "star.fill"]
        return icons[index % icons.count]
    }
    
    private func activityTitle(for index: Int) -> String {
        let titles = ["Completed study session", "Added new words", "Achieved milestone"]
        return titles[index % titles.count]
    }
    
    private func getCEFRDistribution() -> [String: Int] {
        var distribution: [String: Int] = ["A1": 0, "A2": 0, "B1": 0, "B2": 0, "C1": 0, "C2": 0]
        
        for flashcard in flashcards {
            if let cefrLevel = flashcard.cefrLevel, distribution.keys.contains(cefrLevel) {
                distribution[cefrLevel] = (distribution[cefrLevel] ?? 0) + 1
            }
        }
        
        return distribution
    }
    
    private func cefrLevelColor(_ level: String) -> Color {
        switch level {
        case "A1", "A2":
            return .green
        case "B1", "B2":
            return .blue
        case "C1", "C2":
            return .purple
        default:
            return .gray
        }
    }
    
    private var examStatisticsCard: some View {
        let stats = coreDataManager.getExamStatistics()
        let successRate = stats.totalQuestions > 0 ? Double(stats.correctAnswers) / Double(stats.totalQuestions) * 100 : 0.0
        
        return VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Exam Performance")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Text("Your exam results")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "doc.text.fill")
                    .font(.title2)
                    .foregroundColor(.purple)
            }
            
            // Summary Stats
            HStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(stats.totalExams)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.purple)
                    Text("Exams Taken")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(stats.totalQuestions)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.blue)
                    Text("Questions")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(Int(successRate))%")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.green)
                    Text("Success Rate")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.vertical, 8)
            
            // Correct/Incorrect Breakdown
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Circle()
                            .fill(Color.green)
                            .frame(width: 8, height: 8)
                        Text("Correct")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    Text("\(stats.correctAnswers)")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                }
                
                Spacer()
                
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Circle()
                            .fill(Color.red)
                            .frame(width: 8, height: 8)
                        Text("Incorrect")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    Text("\(stats.incorrectAnswers)")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                }
            }
            .padding(.top, 8)
        }
        .padding(20)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
    }
    
    private func activitySubtitle(for index: Int) -> String {
        let subtitles = ["Reviewed 15 cards", "Added 5 new words", "Reached 500 points"]
        return subtitles[index % subtitles.count]
    }
    
    private func activityTime(for index: Int) -> String {
        let times = ["2h ago", "1d ago", "3d ago"]
        return times[index % times.count]
    }
}

// MARK: - Supporting Views

struct MetricCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    let subtitle: String
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(value)
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                
                Text(subtitle)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(16)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}

struct QuickActionButton: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                HStack {
                    Image(systemName: icon)
                        .font(.title2)
                        .foregroundColor(color)
                    
                    Spacer()
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(16)
            .background(color.opacity(0.05))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(color.opacity(0.2), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    DashboardView()
} 