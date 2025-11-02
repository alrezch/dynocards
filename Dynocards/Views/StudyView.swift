//
//  StudyView.swift
//  Dynocards
//
//  Created by User on 2024
//

import SwiftUI
import CoreData

struct StudyView: View {
    @StateObject private var studyViewModel = StudySessionViewModel()
    @StateObject private var audioService = AudioService.shared
    @StateObject private var aiService = AIService.shared
    private let coreDataManager = CoreDataManager.shared
    
    @State private var showingAnswer = false
    @State private var cardOffset = CGSize.zero
    @State private var cardRotation: Double = 0
    @State private var calendarData: [CalendarDay] = []
    @State private var selectedMode: StudyMode = .spacedRepetition
    @State private var isInStudyMode = false
    @State private var isInExamMode = false
    @State private var isInReviewMode = false // Track if we're in review mode
    @State private var examQuestions: [ExamQuestion] = []
    @State private var currentExamQuestionIndex = 0
    @State private var examResults: [ExamResult] = []
    @State private var showingExamResults = false
    @State private var isGeneratingExam = false
    @State private var selectedExamWordCount: Int = 10
    @State private var showingAnswerFeedback = false
    @State private var selectedAnswerIndex: Int? = nil
    @State private var correctAnswerShown = false
    @State private var examStartTime: Date? = nil
    @State private var selectedReviewTags: Set<String> = [] // For tag-based review (multiple tags)
    
    // Simple encouraging messages
    private let encouragingMessages = [
        "🎉 Amazing work!",
        "🌟 Fantastic job!",
        "🚀 Outstanding!",
        "💪 Brilliant!",
        "✨ Excellent!"
    ]
    
    struct CalendarDay: Identifiable {
        let id = UUID()
        let date: Date
        let dueCards: Int
        let practicedCards: Int
        let isToday: Bool
        let isPast: Bool
    }
    
    enum StudyMode: String, CaseIterable {
        case spacedRepetition = "Spaced Repetition"
        case review = "Review Mode"
        case exam = "Exam Mode"
        
        var icon: String {
            switch self {
            case .spacedRepetition: return "brain.head.profile"
            case .review: return "book.fill"
            case .exam: return "doc.text.fill"
            }
        }
        
        var color: Color {
            switch self {
            case .spacedRepetition: return .blue
            case .review: return .green
            case .exam: return .purple
            }
        }
    }
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                if isInStudyMode {
                    if isInExamMode {
                        examView(geometry: geometry)
                    } else {
                        focusedStudyView(geometry: geometry)
                    }
                } else {
                    // Show different views based on selected mode
                    if selectedMode == .spacedRepetition {
                        spacedRepetitionView(geometry: geometry)
                    } else if selectedMode == .review {
                        reviewModeView(geometry: geometry)
                    } else {
                        examModeView(geometry: geometry)
                    }
                }
            }
        }
        .navigationBarHidden(true)
        .background(
            LinearGradient(
                colors: [
                    Color(.systemBackground),
                    Color.blue.opacity(0.03),
                    Color.mint.opacity(0.02)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .onAppear {
            loadCalendarData()
            studyViewModel.loadDueCards()
        }
        .overlay(
            // Exam Generation Loading Popup
            Group {
                if isGeneratingExam {
                    examGenerationLoadingView
                }
            }
        )
    }
    
    // MARK: - Spaced Repetition View
    private func spacedRepetitionView(geometry: GeometryProxy) -> some View {
        ScrollView {
            VStack(spacing: 0) {
                // Study Mode Selector (moved to top, no header)
                studyModeSelector
                    .padding(.top, 10)
                    .padding(.bottom, 20)
                
                // Calendar Section with embedded buttons
                calendarSectionWithButtons
                    .padding(.bottom, 20)
                
                // Mastery Progress Card
                masteryProgressCard
                    .padding(.bottom, 20)
                
                // Upcoming Days (scrollable)
                upcomingDaysSection
                    .padding(.bottom, 100) // Safe area for tab bar
            }
            .padding(.horizontal, 20)
        }
        .scrollIndicators(.hidden)
    }
    
    // MARK: - Review Mode View
    private func reviewModeView(geometry: GeometryProxy) -> some View {
        ScrollView {
            VStack(spacing: 0) {
                // Study Mode Selector (moved to top, no header)
                studyModeSelector
                    .padding(.top, 10)
                    .padding(.bottom, 20)
                
                // Tag Selector Section
                tagSelectorSection
                    .padding(.bottom, 20)
                
                // Review Statistics with embedded button
                reviewStatisticsSectionWithButton
                    .padding(.bottom, 20)
                
                // Additional content can scroll if needed
                Spacer(minLength: 100) // Safe area for tab bar
            }
            .padding(.horizontal, 20)
        }
        .scrollIndicators(.hidden)
    }
    
    // MARK: - Exam Mode View
    private func examModeView(geometry: GeometryProxy) -> some View {
        ScrollView {
            VStack(spacing: 0) {
                // Study Mode Selector (moved to top, no header)
                studyModeSelector
                    .padding(.top, 10)
                    .padding(.bottom, 20)
                
                // Exam Configuration
                examConfigurationSection
                    .padding(.bottom, 20)
                
                // Additional content can scroll if needed
                Spacer(minLength: 100) // Safe area for tab bar
            }
            .padding(.horizontal, 20)
        }
        .scrollIndicators(.hidden)
    }
    
    private var examModeHeaderView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Exam Mode")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Text("Test your knowledge with multiple choice questions")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding(.top, 10)
    }
    
    private var examConfigurationSection: some View {
        VStack(spacing: 20) {
            // Word Count Selection
            VStack(alignment: .leading, spacing: 12) {
                Text("Number of Questions")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                HStack {
                    Text("\(selectedExamWordCount)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.purple)
                        .frame(minWidth: 50)
                    
                    Stepper("", value: $selectedExamWordCount, in: 1...min(50, coreDataManager.fetchAllFlashcards().count))
                        .labelsHidden()
                    
                    Spacer()
                    
                    Text("max \(min(50, coreDataManager.fetchAllFlashcards().count))")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.systemGray6))
                )
                
                Text("Select how many words you want to be tested on. The exam will include various question types.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            // Start Exam Button
            Button(action: {
                startExamMode()
            }) {
                HStack {
                    Image(systemName: "play.fill")
                    Text("Start Exam")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(selectedExamWordCount > 0 && coreDataManager.fetchAllFlashcards().count > 0 ? Color.purple : Color.gray)
                )
                .foregroundColor(.white)
            }
            .disabled(selectedExamWordCount <= 0 || coreDataManager.fetchAllFlashcards().count == 0)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 2)
        )
    }
    
    private var spacedRepetitionHeaderView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Spaced Repetition")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Text("Master your vocabulary with science")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding(.top, 10)
        .padding(.bottom, 20)
    }
    
    private var tagSelectorSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Filter by Tag")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Spacer()
                
                if !selectedReviewTags.isEmpty {
                    Button(action: {
                        selectedReviewTags = []
                    }) {
                        Text("Clear All")
                            .font(.subheadline)
                            .foregroundColor(.blue)
                    }
                }
            }
            
            Text("Review all words or select one or more tags to review")
                .font(.caption)
                .foregroundColor(.secondary)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    // "All Words" option
                    Button(action: {
                        selectedReviewTags = []
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: selectedReviewTags.isEmpty ? "checkmark.circle.fill" : "circle")
                                .font(.caption)
                            Text("All Words")
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }
                        .foregroundColor(selectedReviewTags.isEmpty ? .white : .primary)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(selectedReviewTags.isEmpty ? Color.green : Color(.systemGray6))
                        )
                    }
                    
                    // Tag options
                    ForEach(getAllTags(), id: \.self) { tag in
                        Button(action: {
                            if selectedReviewTags.contains(tag) {
                                selectedReviewTags.remove(tag)
                            } else {
                                selectedReviewTags.insert(tag)
                            }
                        }) {
                            HStack(spacing: 6) {
                                Image(systemName: selectedReviewTags.contains(tag) ? "checkmark.circle.fill" : "tag.fill")
                                    .font(.caption)
                                Text(tag)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                            }
                            .foregroundColor(selectedReviewTags.contains(tag) ? .white : .primary)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(selectedReviewTags.contains(tag) ? Color.green : Color(.systemGray6))
                            )
                        }
                    }
                }
                .padding(.vertical, 4)
            }
            
            // Show count of words with selected tags
            if !selectedReviewTags.isEmpty {
                let count = getWordsCountForTags(selectedReviewTags)
                HStack(spacing: 4) {
                    Image(systemName: "info.circle.fill")
                        .font(.caption)
                        .foregroundColor(.green)
                    if selectedReviewTags.count == 1 {
                        Text("\(count) word\(count == 1 ? "" : "s") in \"\(selectedReviewTags.first!)\" tag")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else {
                        Text("\(count) word\(count == 1 ? "" : "s") across \(selectedReviewTags.count) tag\(selectedReviewTags.count == 1 ? "" : "s")")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.top, 4)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
        )
    }
    
    private var reviewModeHeaderView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Review Mode")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Text("Review all your words")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding(.top, 10)
        .padding(.bottom, 20)
    }
    
    private var studyModeSelector: some View {
        // Modern segmented control style - matches width of other containers
        ZStack {
            // Background container - matches other cards
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemGray6))
            
            // Animated selection indicator (sliding background)
            GeometryReader { geometry in
                let tabWidth = geometry.size.width / CGFloat(StudyMode.allCases.count)
                let selectedIndex = CGFloat(StudyMode.allCases.firstIndex(of: selectedMode) ?? 0)
                
                RoundedRectangle(cornerRadius: 14)
                    .fill(selectedMode.color)
                    .frame(width: tabWidth - 4, height: 66)
                    .offset(x: selectedIndex * tabWidth + 2, y: 2)
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: selectedMode)
            }
            .padding(.horizontal, 2)
            .padding(.vertical, 2)
            
            // Buttons on top
            HStack(spacing: 0) {
                ForEach(StudyMode.allCases, id: \.self) { mode in
                    Button(action: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            selectedMode = mode
                        }
                    }) {
                        // Content with white text when selected
                        VStack(spacing: 6) {
                            Image(systemName: mode.icon)
                                .font(.system(size: 18, weight: .semibold))
                            
                            Text(mode.rawValue)
                                .font(.system(size: 11, weight: .medium))
                                .lineLimit(1)
                                .minimumScaleFactor(0.8)
                        }
                        .foregroundColor(selectedMode == mode ? .white : mode.color)
                        .frame(maxWidth: .infinity)
                        .frame(height: 70)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
        .frame(height: 70)
    }
    
    private var calendarSection: some View {
        VStack(spacing: 12) {
            // Today's Summary
            todaySummaryCard
            
            // Upcoming Days
            upcomingDaysSection
        }
    }
    
    private var calendarSectionWithButtons: some View {
        VStack(spacing: 12) {
            // Today's Summary with embedded buttons
            todaySummaryCardWithButtons
        }
    }
    
    private var todaySummaryCard: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Today")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Text(Date().formatted(date: .abbreviated, time: .omitted))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Today's count with progress
                VStack(spacing: 4) {
                    if let todayData = calendarData.first {
                        if todayData.practicedCards > 0 {
                            // Show progress after starting
                            HStack(spacing: 4) {
                                Text("\(todayData.practicedCards)")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.green)
                                
                                Text("/")
                                    .font(.title2)
                                    .fontWeight(.medium)
                                    .foregroundColor(.secondary)
                                
                                Text("\(todayData.dueCards)")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.blue)
                            }
                            
                            Text("words practiced")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        } else {
                            // Show only total initially
                            Text("\(todayData.dueCards)")
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundColor(.blue)
                            
                            Text("words to practice")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            
            // Progress indicator
            if let todayData = calendarData.first, todayData.dueCards > 0 {
                let remaining = todayData.dueCards - todayData.practicedCards
                if remaining > 0 {
                    HStack {
                        Text("\(remaining) words remaining")
                            .font(.subheadline)
                            .foregroundColor(.orange)
                        
                        Spacer()
                        
                        if todayData.practicedCards > 0 {
                            let progress = Double(todayData.practicedCards) / Double(todayData.dueCards)
                            Text("\(Int(progress * 100))%")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.secondary)
                        }
                    }
                } else {
                    // Celebration when completed
                    HStack {
                        Text("All caught up!")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.green)
                        
                        Spacer()
                        
                        HStack(spacing: 4) {
                            Image(systemName: "star.fill")
                                .foregroundColor(.yellow)
                                .scaleEffect(1.2)
                                .animation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true), value: todayData.practicedCards)
                            
                            Image(systemName: "trophy.fill")
                                .foregroundColor(.orange)
                                .scaleEffect(1.2)
                                .animation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true).delay(0.2), value: todayData.practicedCards)
                        }
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.green.opacity(0.1))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.green.opacity(0.3), lineWidth: 1)
                            )
                    )
                }
            } else {
                HStack {
                    Text("No words due today")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
        )
    }
    
    private var todaySummaryCardWithButtons: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Today")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Text(Date().formatted(date: .abbreviated, time: .omitted))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Today's count with progress
                VStack(spacing: 4) {
                    if let todayData = calendarData.first {
                        if todayData.practicedCards > 0 {
                            // Show progress after starting
                            HStack(spacing: 4) {
                                Text("\(todayData.practicedCards)")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.green)
                                
                                Text("/")
                                    .font(.title2)
                                    .fontWeight(.medium)
                                    .foregroundColor(.secondary)
                                
                                Text("\(todayData.dueCards)")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.blue)
                            }
                            
                            Text("words practiced")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        } else {
                            // Show only total initially
                            Text("\(todayData.dueCards)")
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundColor(.blue)
                            
                            Text("words to practice")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            
            // Progress indicator
            if let todayData = calendarData.first, todayData.dueCards > 0 {
                let remaining = todayData.dueCards - todayData.practicedCards
                if remaining > 0 {
                    HStack {
                        Text("\(remaining) words remaining")
                            .font(.subheadline)
                            .foregroundColor(.orange)
                        
                        Spacer()
                        
                        if todayData.practicedCards > 0 {
                            let progress = Double(todayData.practicedCards) / Double(todayData.dueCards)
                            Text("\(Int(progress * 100))%")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.secondary)
                        }
                    }
                } else {
                    // Celebration when completed
                    HStack {
                        Text("All caught up!")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.green)
                        
                        Spacer()
                        
                        HStack(spacing: 4) {
                            Image(systemName: "star.fill")
                                .foregroundColor(.yellow)
                                .scaleEffect(1.2)
                                .animation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true), value: todayData.practicedCards)
                            
                            Image(systemName: "trophy.fill")
                                .foregroundColor(.orange)
                                .scaleEffect(1.2)
                                .animation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true).delay(0.2), value: todayData.practicedCards)
                        }
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.green.opacity(0.1))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.green.opacity(0.3), lineWidth: 1)
                            )
                    )
                }
            } else {
                HStack {
                    Text("No words due today")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                }
            }
            
            // Action Button with guidance
            if let todayData = calendarData.first {
                if todayData.dueCards > 0 {
                    // Enable button when words are due
                    Button(action: {
                        startFocusedStudySession()
                    }) {
                        HStack {
                            Image(systemName: "book.fill")
                                .font(.system(size: 16, weight: .medium))
                            Text(getStudyButtonText())
                                .font(.system(size: 16, weight: .medium))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.blue)
                        )
                    }
                } else {
                    // Disabled state with guidance
                    VStack(spacing: 12) {
                        Button(action: {}) {
                            HStack {
                                Image(systemName: "book.fill")
                                    .font(.system(size: 16, weight: .medium))
                                Text("Study Now")
                                    .font(.system(size: 16, weight: .medium))
                            }
                            .foregroundColor(.white.opacity(0.6))
                            .frame(maxWidth: .infinity)
                            .frame(height: 44)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.gray.opacity(0.3))
                            )
                        }
                        .disabled(true)
                        
                        // Guidance message
                        VStack(spacing: 8) {
                            HStack(spacing: 8) {
                                Image(systemName: "info.circle.fill")
                                    .foregroundColor(.blue)
                                    .font(.subheadline)
                                Text("No words due today")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(.primary)
                            }
                            
                            Text("Practice your words in Review Mode or test yourself with an Exam")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.vertical, 12)
                        .padding(.horizontal, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.blue.opacity(0.1))
                        )
                    }
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
        )
    }
    
    private var upcomingDaysSection: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Upcoming Days")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Spacer()
            }
            
            LazyVStack(spacing: 8) {
                ForEach(Array(calendarData.dropFirst().prefix(3))) { day in
                    upcomingDayRow(day: day)
                }
            }
        }
    }
    
    private func upcomingDayRow(day: CalendarDay) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(day.date.formatted(date: .abbreviated, time: .omitted))
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                Text(day.date.formatted(.dateTime.weekday(.wide)))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(spacing: 4) {
                Text("\(day.dueCards)")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(day.dueCards > 0 ? .orange : .secondary)
                
                Text("words")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
        )
    }
    
    private var reviewStatisticsSection: some View {
        VStack(spacing: 12) {
            // Total Words Card
            VStack(spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Your Vocabulary")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                        
                        Text("Total words in your collection")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    VStack(spacing: 4) {
                        Text("\(getTotalWordsCount())")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.blue)
                        
                        Text("words")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemBackground))
                    .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
            )
            
            // Mastery Progress Card
            VStack(spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Mastery Progress")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                        
                        Text("Words mastered in spaced repetition")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    VStack(spacing: 4) {
                        Text("\(getMasteredWordsCount())")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.green)
                        
                        Text("mastered")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                // Progress bar
                let masteryPercentage = getMasteryPercentage()
                VStack(spacing: 8) {
                    HStack {
                        Text("\(Int(masteryPercentage * 100))%")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Text("\(getMasteredWordsCount())/\(getTotalWordsCount())")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                    }
                    
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color(.systemGray5))
                                .frame(height: 8)
                            
                            RoundedRectangle(cornerRadius: 4)
                                .fill(
                                    LinearGradient(
                                        colors: [.green, .mint],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: geometry.size.width * masteryPercentage, height: 8)
                                .animation(.easeInOut(duration: 0.3), value: masteryPercentage)
                        }
                    }
                    .frame(height: 8)
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemBackground))
                    .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
            )
        }
    }
    
    private var masteryProgressCard: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Mastery Progress")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Text("Words mastered in spaced repetition")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(spacing: 4) {
                    Text("\(getMasteredWordsCount())")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.green)
                    
                    Text("mastered")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            // Progress bar
            let masteryPercentage = getMasteryPercentage()
            VStack(spacing: 8) {
                HStack {
                    Text("\(Int(masteryPercentage * 100))%")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text("\(getMasteredWordsCount())/\(getTotalWordsCount())")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                }
                
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color(.systemGray5))
                            .frame(height: 8)
                        
                        RoundedRectangle(cornerRadius: 4)
                            .fill(
                                LinearGradient(
                                    colors: [.green, .mint],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: geometry.size.width * masteryPercentage, height: 8)
                            .animation(.easeInOut(duration: 0.3), value: masteryPercentage)
                    }
                }
                .frame(height: 8)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
        )
    }
    
    private var reviewStatisticsSectionWithButton: some View {
        VStack(spacing: 12) {
            // Total Words Card
            VStack(spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Your Vocabulary")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                        
                        Text("Total words in your collection")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    VStack(spacing: 4) {
                        Text("\(getTotalWordsCount())")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.green)
                        
                        Text("words")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemBackground))
                    .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
            )
            
            // Review Button Card
            VStack(spacing: 12) {
                // Show review button text based on selected tags
                let reviewButtonText: String = {
                    if selectedReviewTags.isEmpty {
                        return "Start Review All Words"
                    } else if selectedReviewTags.count == 1 {
                        let tag = selectedReviewTags.first!
                        let count = getWordsCountForTags(selectedReviewTags)
                        return "Review \"\(tag)\" (\(count) words)"
                    } else {
                        let count = getWordsCountForTags(selectedReviewTags)
                        return "Review \(selectedReviewTags.count) Tags (\(count) words)"
                    }
                }()
                
                Button(action: {
                    startReviewMode()
                }) {
                    HStack {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 16, weight: .medium))
                        Text(reviewButtonText)
                            .font(.system(size: 16, weight: .medium))
                            .lineLimit(2)
                            .multilineTextAlignment(.center)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: selectedReviewTags.isEmpty ? 44 : 54)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.green)
                    )
                }
                .disabled(getReviewableWordsCount() == 0)
                .opacity(getReviewableWordsCount() == 0 ? 0.6 : 1.0)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemBackground))
                    .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
            )
        }
    }
    
    private var spacedRepetitionActionButtons: some View {
        VStack(spacing: 12) {
            // Study Now Button
            Button(action: {
                startFocusedStudySession()
            }) {
                HStack(spacing: 12) {
                    Image(systemName: "play.fill")
                        .font(.title3)
                    
                    Text(getStudyButtonText())
                        .font(.headline)
                        .fontWeight(.semibold)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(
                    LinearGradient(
                        colors: [.blue, .purple],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(16)
                .shadow(color: .blue.opacity(0.3), radius: 8, x: 0, y: 4)
            }
            .disabled(getTodayDueCards() == 0)
            .opacity(getTodayDueCards() == 0 ? 0.6 : 1.0)
            
            // Temporary: Add Sample Data Button (for testing)
            if getTodayDueCards() == 0 {
                Button(action: {
                    CoreDataManager.shared.addSampleFlashcards()
                    loadCalendarData()
                    studyViewModel.loadDueCards()
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "plus.circle.fill")
                        Text("Add Sample Cards")
                    }
                    .foregroundColor(.blue)
                    .padding(.vertical, 12)
                }
                .padding(.top, 16)
            }
        }
        .padding(.top, 30)
    }
    
    private var reviewModeActionButtons: some View {
        VStack(spacing: 12) {
            // Review All Words Button
            Button(action: {
                startReviewMode()
            }) {
                HStack(spacing: 12) {
                    Image(systemName: "book.fill")
                        .font(.title3)
                    
                    Text("Start Review")
                        .font(.headline)
                        .fontWeight(.semibold)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(
                    LinearGradient(
                        colors: [.green, .mint],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(16)
                .shadow(color: .green.opacity(0.3), radius: 8, x: 0, y: 4)
            }
            .disabled(getTotalWordsCount() == 0)
            .opacity(getTotalWordsCount() == 0 ? 0.6 : 1.0)
            
            // Temporary: Add Sample Data Button (for testing)
            if getTotalWordsCount() == 0 {
                Button(action: {
                    CoreDataManager.shared.addSampleFlashcards()
                    loadCalendarData()
                    studyViewModel.loadDueCards()
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "plus.circle.fill")
                        Text("Add Sample Cards")
                    }
                    .foregroundColor(.blue)
                    .padding(.vertical, 12)
                }
                .padding(.top, 16)
            }
        }
        .padding(.top, 30)
    }
    
    // MARK: - Focused Study View
    private func focusedStudyView(geometry: GeometryProxy) -> some View {
        Group {
            if studyViewModel.studyComplete {
                // Study Complete View
                studyCompleteView(geometry: geometry)
            } else {
                // Active Study View
                activeStudyView(geometry: geometry)
            }
        }
    }
    
    private func activeStudyView(geometry: GeometryProxy) -> some View {
        VStack(spacing: 0) {
            // Header with Progress
            focusedHeaderView
            
            // Card Area
            ZStack {
                // Background cards (for stack effect)
                ForEach(0..<min(3, studyViewModel.cardsToStudy.count), id: \.self) { index in
                    if index != studyViewModel.currentCardIndex {
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color(.systemGray6))
                            .frame(width: UIScreen.main.bounds.width - 40 - CGFloat(index * 8), height: 500 - CGFloat(index * 10))
                            .offset(y: CGFloat(index * 6))
                            .scaleEffect(1.0 - CGFloat(index) * 0.03)
                            .opacity(0.4 - Double(index) * 0.15)
                    }
                }
                
                // Current card
                if studyViewModel.currentCardIndex < studyViewModel.cardsToStudy.count {
                    StudyCardView(
                        flashcard: studyViewModel.cardsToStudy[studyViewModel.currentCardIndex],
                        showingAnswer: $showingAnswer,
                        audioService: audioService
                    )
                    .offset(cardOffset)
                    .rotationEffect(.degrees(cardRotation))
                    .scaleEffect(1.0 + abs(cardOffset.width) / 1000)
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                withAnimation(.easeOut(duration: 0.1)) {
                                    cardOffset = value.translation
                                    cardRotation = Double(value.translation.width / 15)
                                }
                            }
                            .onEnded { value in
                                handleSwipeGesture(value: value, geometry: geometry)
                            }
                    )
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .leading).combined(with: .opacity)
                    ))
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.vertical, 8)
            
            Spacer(minLength: 0)
            
            // Action Buttons
            VStack(spacing: 0) {
                if !studyViewModel.cardsToStudy.isEmpty && !showingAnswer {
                    revealButtonView
                        .padding(.bottom, 100) // Add space for tab bar
                } else if !studyViewModel.cardsToStudy.isEmpty && showingAnswer {
                    actionButtonsView
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .animation(.spring(response: 0.6, dampingFraction: 0.8), value: showingAnswer)
                }
            }
        }
        .padding(.horizontal, 20)
    }
    
    @ViewBuilder
    private func studyCompleteView(geometry: GeometryProxy) -> some View {
        // Show different completion view based on mode
        if isInReviewMode {
            reviewCompleteView(geometry: geometry)
        } else {
            spacedRepetitionCompleteView(geometry: geometry)
        }
    }
    
    private func spacedRepetitionCompleteView(geometry: GeometryProxy) -> some View {
        VStack(spacing: 0) {
            // Minimal header with just close button
            HStack {
                Button(action: {
                    exitStudyMode()
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            .padding(.top, 10)
            .padding(.horizontal, 20)
            .padding(.bottom, 10)
            
            Spacer()
            
            // Centered Celebration View
            VStack(spacing: 32) {
                CelebrationView(message: encouragingMessages.randomElement() ?? "Great job!")
                    .frame(height: 300)
                
                // Finish Session Button
                Button(action: {
                    exitStudyMode()
                }) {
                    HStack(spacing: 12) {
                        Image(systemName: "checkmark.circle.fill")
                        Text("Finish Session")
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        LinearGradient(
                            colors: [.green, .mint],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(16)
                    .shadow(color: .green.opacity(0.3), radius: 8, x: 0, y: 4)
                }
                .padding(.horizontal, 40)
            }
            .frame(maxWidth: .infinity)
            
            Spacer()
            
            // Safe area padding for tab bar
            Spacer()
                .frame(height: 100)
        }
        .transition(.opacity)
        .animation(.easeInOut(duration: 0.5), value: studyViewModel.studyComplete)
    }
    
    private func reviewCompleteView(geometry: GeometryProxy) -> some View {
        VStack(spacing: 0) {
            // Minimal header with just close button
            HStack {
                Button(action: {
                    exitStudyMode()
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            .padding(.top, 10)
            .padding(.horizontal, 20)
            .padding(.bottom, 10)
            
            Spacer()
            
            // Centered Completion View for Review Mode
            VStack(spacing: 32) {
                // Success Icon
                VStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [
                                        Color.green.opacity(0.3),
                                        Color.green.opacity(0.1),
                                        Color.clear
                                    ],
                                    center: .center,
                                    startRadius: 20,
                                    endRadius: 80
                                )
                            )
                            .frame(width: 120, height: 120)
                        
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 60, weight: .medium))
                            .foregroundColor(.green)
                    }
                    
                    Text("You've reviewed all your words!")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                }
                
                // Action Buttons
                VStack(spacing: 16) {
                    // Review Again Button
                    Button(action: {
                        // Restart review mode completely
                        studyViewModel.resetSession()
                        studyViewModel.loadAllCardsForReview() // This sets isReviewMode = true
                        showingAnswer = false
                        cardOffset = .zero
                        cardRotation = 0
                        
                        // Ensure we stay in review mode
                        isInReviewMode = true
                        studyViewModel.isReviewMode = true // Ensure flag is set
                        
                        // Reset study complete state
                        withAnimation(.easeInOut(duration: 0.3)) {
                            studyViewModel.studyComplete = false
                        }
                    }) {
                        HStack(spacing: 12) {
                            Image(systemName: "arrow.clockwise")
                                .font(.system(size: 18, weight: .medium))
                            Text("Want to review again?")
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            LinearGradient(
                                colors: [.green, .mint],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(16)
                        .shadow(color: .green.opacity(0.3), radius: 8, x: 0, y: 4)
                    }
                    
                    // Add New Word Button
                    Button(action: {
                        // Exit study mode first
                        exitStudyMode()
                        // Post notification to navigate to Add Word tab
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            NotificationCenter.default.post(name: NSNotification.Name("NavigateToAddWord"), object: nil)
                        }
                    }) {
                        HStack(spacing: 12) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 18, weight: .medium))
                            Text("Add New Word")
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(.blue)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.blue, lineWidth: 2)
                        )
                    }
                }
                .padding(.horizontal, 40)
            }
            .frame(maxWidth: .infinity)
            
            Spacer()
            
            // Safe area padding for tab bar
            Spacer()
                .frame(height: 100)
        }
        .transition(.opacity)
        .animation(.easeInOut(duration: 0.5), value: studyViewModel.studyComplete)
    }
    
    private var focusedHeaderView: some View {
        HStack {
            // Close button
            Button(action: {
                exitStudyMode()
            }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.title2)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Progress (simplified - only show count and progress bar)
            VStack(spacing: 6) {
                let currentCard = min(studyViewModel.currentCardIndex + 1, studyViewModel.cardsToStudy.count)
                let totalCards = max(studyViewModel.cardsToStudy.count, 1)
                
                // Only show "X of Y" - removed "remaining"
                Text("\(currentCard) of \(totalCards)")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                
                // Progress bar
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color(.systemGray5))
                            .frame(height: 4)
                        
                        RoundedRectangle(cornerRadius: 2)
                            .fill(
                                LinearGradient(
                                    colors: isInReviewMode ? [.green, .mint] : [.blue, .purple],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: geometry.size.width * min(progressPercentage, 1.0), height: 4)
                            .animation(.easeInOut(duration: 0.3), value: progressPercentage)
                    }
                }
                .frame(width: 120, height: 4)
            }
            
            Spacer()
            
            // Placeholder for balance (removed "Correct" and "Total" stats)
            Color.clear
                .frame(width: 30, height: 30)
        }
        .padding(.top, 10)
        .padding(.bottom, 20)
    }
    
    private var revealButtonView: some View {
        Button(action: {
            withAnimation(.easeInOut(duration: 0.6)) {
                showingAnswer = true
            }
        }) {
            HStack(spacing: 12) {
                Image(systemName: "eye.fill")
                    .font(.title3)
                
                Text("Reveal Answer")
                    .font(.headline)
                    .fontWeight(.semibold)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                LinearGradient(
                    colors: [.blue, .purple],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(16)
            .shadow(color: .blue.opacity(0.3), radius: 8, x: 0, y: 4)
        }
        .padding(.bottom, 12)
    }
    
    private var actionButtonsView: some View {
        HStack(spacing: 12) {
            // Hard Button
            Button(action: { answerCard(difficulty: .hard) }) {
                VStack(spacing: 4) {
                    Text("Hard")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                    
                    Text("30s+")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))
                }
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(Color.red)
                .cornerRadius(12)
            }
            .buttonStyle(PlainButtonStyle())
            
            // Good Button
            Button(action: { answerCard(difficulty: .good) }) {
                VStack(spacing: 4) {
                    Text("Good")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                    
                    Text("10-30s")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))
                }
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(Color.orange)
                .cornerRadius(12)
            }
            .buttonStyle(PlainButtonStyle())
            
            // Easy Button
            Button(action: { answerCard(difficulty: .easy) }) {
                VStack(spacing: 4) {
                    Text("Easy")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                    
                    Text("<10s")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))
                }
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(Color.green)
                .cornerRadius(12)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 20)
    }
    
    // MARK: - Exam Mode
    private func examView(geometry: GeometryProxy) -> some View {
        VStack(spacing: 0) {
            // Exam Header
            examHeaderView
            
            if showingExamResults {
                examResultsView
            } else if currentExamQuestionIndex < examQuestions.count {
                // Current Exam Question
                examQuestionView
            } else {
                // Loading or Error
                VStack {
                    ProgressView("Generating exam questions...")
                        .font(.headline)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .padding(.horizontal, 20)
    }
    
    private var examHeaderView: some View {
        HStack {
            Button(action: {
                exitExamMode()
            }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.title2)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(spacing: 4) {
                Text("Exam Mode")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                if currentExamQuestionIndex < examQuestions.count {
                    Text("Question \(currentExamQuestionIndex + 1) of \(examQuestions.count)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            // Placeholder for balance
            Color.clear
                .frame(width: 30, height: 30)
        }
        .padding(.top, 10)
        .padding(.bottom, 20)
    }
    
    private var examQuestionView: some View {
        VStack(spacing: 20) {
            if currentExamQuestionIndex < examQuestions.count {
                let question = examQuestions[currentExamQuestionIndex]
                
                // Question Card
                VStack(spacing: 16) {
                    Text(question.question)
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                    
                    // Options
                    VStack(spacing: 12) {
                        ForEach(question.options.indices, id: \.self) { index in
                            Button(action: {
                                if !showingAnswerFeedback {
                                    answerExamQuestion(selectedIndex: index)
                                }
                            }) {
                                HStack {
                                    Text(question.options[index])
                                        .font(.body)
                                        .fontWeight(.medium)
                                        .foregroundColor(getOptionForegroundColor(index: index, question: question))
                                        .multilineTextAlignment(.leading)
                                    
                                    Spacer()
                                    
                                    // Show checkmark or X
                                    if showingAnswerFeedback {
                                        if index == question.correctAnswerIndex {
                                            Image(systemName: "checkmark.circle.fill")
                                                .foregroundColor(.green)
                                        } else if index == selectedAnswerIndex && index != question.correctAnswerIndex {
                                            Image(systemName: "xmark.circle.fill")
                                                .foregroundColor(.red)
                                        }
                                    }
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(getOptionBackgroundColor(index: index, question: question))
                                )
                            }
                            .buttonStyle(PlainButtonStyle())
                            .disabled(showingAnswerFeedback)
                        }
                    }
                    
                    // Show tip if answer was wrong
                    if showingAnswerFeedback && selectedAnswerIndex != nil && selectedAnswerIndex != question.correctAnswerIndex, let tip = question.tip {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "lightbulb.fill")
                                    .foregroundColor(.orange)
                                Text("Tip")
                                    .font(.headline)
                                    .foregroundColor(.primary)
                            }
                            Text(tip)
                                .font(.body)
                                .foregroundColor(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                                .lineLimit(nil)
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.orange.opacity(0.1))
                        )
                    }
                    
                    // Next Question Button
                    if showingAnswerFeedback {
                        Button(action: {
                            moveToNextQuestion()
                        }) {
                            Text(currentExamQuestionIndex + 1 < examQuestions.count ? "Next Question" : "View Results")
                                .font(.headline)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.purple)
                                )
                        }
                        .padding(.top, 8)
                    }
                }
                .padding(20)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(.systemBackground))
                        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
                )
            }
            
            Spacer()
        }
    }
    
    private var examResultsView: some View {
        VStack(spacing: 20) {
            // Results Summary
            VStack(spacing: 16) {
                Text("Exam Complete!")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                let correctCount = examResults.filter { $0.isCorrect }.count
                let totalCount = examResults.count
                let percentage = totalCount > 0 ? Double(correctCount) / Double(totalCount) * 100 : 0
                
                VStack(spacing: 8) {
                    Text("\(correctCount)/\(totalCount)")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.blue)
                    
                    Text("\(Int(percentage))%")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                }
                
                // Performance message
                Text(getPerformanceMessage(percentage: percentage))
                    .font(.headline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemBackground))
                    .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
            )
            
            // Finish Button
            Button(action: {
                exitExamMode()
            }) {
                HStack(spacing: 12) {
                    Image(systemName: "checkmark.circle.fill")
                    Text("Finish Exam")
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    LinearGradient(
                        colors: [.green, .mint],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(16)
            }
            
            Spacer()
        }
    }
    
    // MARK: - Helper Methods
    private var progressPercentage: Double {
        guard !studyViewModel.cardsToStudy.isEmpty else { return 0 }
        let progress = Double(studyViewModel.currentCardIndex + 1) / Double(studyViewModel.cardsToStudy.count)
        return min(max(progress, 0.0), 1.0) // Clamp between 0 and 1
    }
    
    private func loadCalendarData() {
        let calendar = Calendar.current
        let today = Date()
        
        var days: [CalendarDay] = []
        
        // Generate data for today and next 7 days
        for dayOffset in 0..<8 {
            let date = calendar.date(byAdding: .day, value: dayOffset, to: today) ?? today
            let dueCards = getDueCardsForDate(date)
            let practicedCards = getPracticedCardsForDate(date)
            let isToday = calendar.isDateInToday(date)
            let isPast = date < today
            
            days.append(CalendarDay(
                date: date,
                dueCards: dueCards,
                practicedCards: practicedCards,
                isToday: isToday,
                isPast: isPast
            ))
        }
        
        calendarData = days
    }
    
    private func getDueCardsForDate(_ date: Date) -> Int {
        let count = CoreDataManager.shared.fetchDueCardsCountForDate(date)
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        print("📅 Due cards for \(formatter.string(from: date)): \(count)")
        return count
    }
    
    private func getPracticedCardsForDate(_ date: Date) -> Int {
        // This would track cards practiced on a specific date
        // For now, return 0 - you'll need to implement this in CoreDataManager
        return 0
    }
    
    private func getTodayDueCards() -> Int {
        return calendarData.first?.dueCards ?? 0
    }
    
    private func getTotalWordsCount() -> Int {
        return CoreDataManager.shared.fetchAllFlashcards().count
    }
    
    private func getMasteredWordsCount() -> Int {
        return CoreDataManager.shared.fetchAllFlashcards().filter { $0.mastered }.count
    }
    
    private func getAllTags() -> [String] {
        let allFlashcards = CoreDataManager.shared.fetchAllFlashcards()
        var uniqueTags = Set<String>()
        
        for flashcard in allFlashcards {
            let tags = flashcard.tagList.filter { $0.lowercased() != "all words" }
            uniqueTags.formUnion(tags)
        }
        
        return Array(uniqueTags).sorted()
    }
    
    private func getWordsCountForTag(_ tag: String) -> Int {
        let allFlashcards = CoreDataManager.shared.fetchAllFlashcards()
        return allFlashcards.filter { flashcard in
            flashcard.tagList.contains(tag)
        }.count
    }
    
    private func getWordsCountForTags(_ tags: Set<String>) -> Int {
        guard !tags.isEmpty else { return getTotalWordsCount() }
        
        let allFlashcards = CoreDataManager.shared.fetchAllFlashcards()
        let tagSet = Set(tags)
        return allFlashcards.filter { flashcard in
            // Include flashcard if it has any of the selected tags
            let flashcardTagSet = Set(flashcard.tagList)
            return !flashcardTagSet.intersection(tagSet).isEmpty
        }.count
    }
    
    private func getReviewableWordsCount() -> Int {
        if selectedReviewTags.isEmpty {
            return getTotalWordsCount()
        }
        return getWordsCountForTags(selectedReviewTags)
    }
    
    private func getMasteryPercentage() -> Double {
        let total = getTotalWordsCount()
        guard total > 0 else { return 0 }
        return Double(getMasteredWordsCount()) / Double(total)
    }
    
    private func getStudyButtonText() -> String {
        if let todayData = calendarData.first, todayData.practicedCards > 0 {
            let remaining = todayData.dueCards - todayData.practicedCards
            return remaining > 0 ? "Practice Remaining (\(remaining))" : "Study Now"
        }
        return "Study Now"
    }
    
    private func startFocusedStudySession() {
        // Debug: Check total flashcards in database
        let totalCards = CoreDataManager.shared.fetchAllFlashcards().count
        print("🔍 Total flashcards in database: \(totalCards)")
        
        studyViewModel.startStudySession()
        studyViewModel.isReviewMode = false // Mark that we're NOT in review mode (spaced repetition)
        isInReviewMode = false // Keep for UI state
        withAnimation(.easeInOut(duration: 0.5)) {
            isInStudyMode = true
        }
    }
    
    private func startReviewMode() {
        // Load cards for review (filtered by tags if selected)
        let tagsArray = selectedReviewTags.isEmpty ? nil : Array(selectedReviewTags)
        studyViewModel.loadAllCardsForReview(filteredByTags: tagsArray) // This sets isReviewMode = true internally
        isInReviewMode = true // Keep for UI state
        withAnimation(.easeInOut(duration: 0.5)) {
            isInStudyMode = true
        }
    }
    
    private func startExamMode() {
        isGeneratingExam = true
        examStartTime = Date()
        Task {
            await generateExamQuestions()
        }
    }
    
    private func generateExamQuestions() async {
        // Get all flashcards
        let allFlashcards = coreDataManager.fetchAllFlashcards()
        
        guard allFlashcards.count > 0 else {
            await MainActor.run {
                isGeneratingExam = false
            }
            return
        }
        
        // Select random words (hybrid approach - random from all words)
        let shuffled = allFlashcards.shuffled()
        let selectedWords = Array(shuffled.prefix(min(selectedExamWordCount, allFlashcards.count)))
        
        var questions: [ExamQuestion] = []
        
        // Generate questions with random types
        for card in selectedWords {
            do {
                let question = try await aiService.generateExamQuestion(for: card, allFlashcards: allFlashcards)
                questions.append(question)
            } catch {
                print("Failed to generate exam question for \(card.word): \(error)")
                // Create a fallback question if AI generation fails
                let fallbackQuestion = createFallbackQuestion(for: card)
                questions.append(fallbackQuestion)
            }
        }
        
        await MainActor.run {
            examQuestions = questions
            currentExamQuestionIndex = 0
            examResults = []
            showingExamResults = false
            showingAnswerFeedback = false
            selectedAnswerIndex = nil
            correctAnswerShown = false
            isInExamMode = true
            isInStudyMode = true
            isGeneratingExam = false
        }
    }
    
    private func createFallbackQuestion(for flashcard: Flashcard) -> ExamQuestion {
        let question = "What is the meaning of '\(flashcard.word)'?"
        let correctAnswer = flashcard.definition
        
        // Simple fallback wrong answers
        let wrongAnswers = [
            "A completely different concept",
            "The opposite meaning",
            "A related but incorrect definition"
        ]
        
        // Ensure exactly 4 options
        var options = [correctAnswer] + Array(wrongAnswers.prefix(3))
        options.shuffle()
        
        let correctIndex = options.firstIndex(of: correctAnswer) ?? 0
        
        return ExamQuestion(
            question: question,
            options: options,
            correctAnswerIndex: correctIndex,
            flashcard: flashcard,
            questionType: .definition,
            tip: "'\(flashcard.word)' means: \(flashcard.shortDefinition)."
        )
    }
    
    private func answerExamQuestion(selectedIndex: Int) {
        guard currentExamQuestionIndex < examQuestions.count else { return }
        
        let question = examQuestions[currentExamQuestionIndex]
        let isCorrect = selectedIndex == question.correctAnswerIndex
        
        selectedAnswerIndex = selectedIndex
        showingAnswerFeedback = true
        
        // Store result (but don't move to next question yet)
        examResults.append(ExamResult(
            question: question,
            selectedAnswer: selectedIndex,
            isCorrect: isCorrect
        ))
    }
    
    private func moveToNextQuestion() {
        showingAnswerFeedback = false
        selectedAnswerIndex = nil
        correctAnswerShown = false
        
        currentExamQuestionIndex += 1
        
        if currentExamQuestionIndex >= examQuestions.count {
            // Exam complete - save results and show summary
            saveExamResults()
            showingExamResults = true
        }
    }
    
    private func saveExamResults() {
        let correctCount = examResults.filter { $0.isCorrect }.count
        let incorrectCount = examResults.filter { !$0.isCorrect }.count
        let totalQuestions = examResults.count
        
        var duration: Double = 0
        if let startTime = examStartTime {
            duration = Date().timeIntervalSince(startTime)
        }
        
        CoreDataManager.shared.saveExamSession(
            totalQuestions: totalQuestions,
            correctAnswers: correctCount,
            incorrectAnswers: incorrectCount,
            duration: duration
        )
    }
    
    private func getOptionBackgroundColor(index: Int, question: ExamQuestion) -> Color {
        if showingAnswerFeedback {
            if index == question.correctAnswerIndex {
                return Color.green.opacity(0.2)
            } else if index == selectedAnswerIndex && index != question.correctAnswerIndex {
                return Color.red.opacity(0.2)
            }
        }
        return Color(.systemGray6)
    }
    
    private func getOptionForegroundColor(index: Int, question: ExamQuestion) -> Color {
        if showingAnswerFeedback {
            if index == question.correctAnswerIndex {
                return Color.green
            } else if index == selectedAnswerIndex && index != question.correctAnswerIndex {
                return Color.red
            }
        }
        return Color.primary
    }
    
    private func getPerformanceMessage(percentage: Double) -> String {
        switch percentage {
        case 90...100:
            return "Outstanding! You're a vocabulary master! 🌟"
        case 80..<90:
            return "Excellent work! You're making great progress! 🎉"
        case 70..<80:
            return "Good job! Keep practicing to improve further! 💪"
        case 60..<70:
            return "Not bad! Review the missed questions to get better! 📚"
        default:
            return "Keep studying! Practice makes perfect! 📖"
        }
    }
    
    private func exitStudyMode() {
        withAnimation(.easeInOut(duration: 0.5)) {
            isInStudyMode = false
            isInExamMode = false
            isInReviewMode = false // Reset review mode flag
        }
        studyViewModel.resetSessionAndLoadDueCards()
        showingAnswer = false
        cardOffset = .zero
        cardRotation = 0
        loadCalendarData()
    }
    
    private func exitExamMode() {
        withAnimation(.easeInOut(duration: 0.5)) {
            isInStudyMode = false
            isInExamMode = false
        }
        examQuestions = []
        currentExamQuestionIndex = 0
        examResults = []
        showingExamResults = false
        loadCalendarData()
    }
    
    // MARK: - Loading Views
    private var examGenerationLoadingView: some View {
        ZStack {
            // Semi-transparent background
            Color.black.opacity(0.4)
                .ignoresSafeArea()
            
            // Loading card
            VStack(spacing: 24) {
                // Animated icon
                ZStack {
                    Circle()
                        .fill(Color.blue.opacity(0.1))
                        .frame(width: 80, height: 80)
                    
                    Image(systemName: "brain.head.profile")
                        .font(.system(size: 32, weight: .medium))
                        .foregroundColor(.blue)
                        .scaleEffect(1.2)
                        .animation(
                            .easeInOut(duration: 1.0)
                            .repeatForever(autoreverses: true),
                            value: isGeneratingExam
                        )
                }
                
                VStack(spacing: 12) {
                    Text("Creating Your Exam")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Text("Our AI is generating personalized questions based on your vocabulary...")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                }
                
                // Progress indicator
                VStack(spacing: 8) {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                        .scaleEffect(1.2)
                    
                    Text("This may take a few moments")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(32)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(.systemBackground))
                    .shadow(color: .black.opacity(0.2), radius: 20, x: 0, y: 10)
            )
            .padding(.horizontal, 40)
        }
        .transition(.opacity.combined(with: .scale))
        .animation(.easeInOut(duration: 0.3), value: isGeneratingExam)
    }
    
    private func handleSwipeGesture(value: DragGesture.Value, geometry: GeometryProxy) {
        let swipeThreshold: CGFloat = geometry.size.width * 0.3
        
        withAnimation(.easeOut(duration: 0.3)) {
            if abs(value.translation.width) > swipeThreshold {
                if value.translation.width > 0 {
                    answerCard(difficulty: .easy)
                } else {
                    answerCard(difficulty: .hard)
                }
            } else {
                cardOffset = .zero
                cardRotation = 0
            }
        }
    }
    
    private func answerCard(difficulty: AnswerDifficulty) {
        studyViewModel.answerCard(difficulty: difficulty)
        
        // Animate card out
        withAnimation(.easeInOut(duration: 0.3)) {
            cardOffset = CGSize(width: difficulty == .easy ? 500 : -500, height: 0)
            cardRotation = difficulty == .easy ? 15 : -15
        }
        
        // Reset for next card
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation(.easeInOut(duration: 0.3)) {
                showingAnswer = false
                cardOffset = .zero
                cardRotation = 0
            }
        }
    }
}

// MARK: - Exam Models
struct ExamResult {
    let question: ExamQuestion
    let selectedAnswer: Int
    let isCorrect: Bool
}

// MARK: - Study Card View (Redesigned)
struct StudyCardView: View {
    let flashcard: Flashcard
    @Binding var showingAnswer: Bool
    let audioService: AudioService
    
    // Fixed card dimensions
    private let cardWidth: CGFloat = UIScreen.main.bounds.width - 40
    private let cardHeight: CGFloat = 500
    
    var body: some View {
        // Card Background with Content - Entire card flips together
        ZStack {
            // Card Background
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.systemBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.blue.opacity(0.1), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.15), radius: 15, x: 0, y: 8)
            
            // Card Content - Both sides visible during transition
            ZStack {
                questionSide
                    .opacity(showingAnswer ? 0 : 1)
                
                answerSide
                    .opacity(showingAnswer ? 1 : 0)
                    .scaleEffect(x: -1, y: 1) // Flip horizontally to correct mirroring from rotation
            }
            .frame(width: cardWidth, height: cardHeight)
            .clipped()
        }
        .frame(width: cardWidth, height: cardHeight)
        .rotation3DEffect(
            .degrees(showingAnswer ? 180 : 0),
            axis: (x: 0, y: 1, z: 0),
            perspective: 0.5
        )
        .onTapGesture {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                showingAnswer.toggle()
            }
        }
    }
    
    // MARK: - Card Sides
    
    private var questionSide: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Question")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Image(systemName: "questionmark.circle.fill")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 12)
            
            // Main Content - Fixed height to match answer side
            VStack(spacing: 20) {
                Spacer()
                
                // Main word
                VStack(spacing: 12) {
                    Text(flashcard.word)
                        .font(.system(size: 42, weight: .bold, design: .default))
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                        .minimumScaleFactor(0.8)
                    
                    // Pronunciation
                    if !flashcard.phonetics.isEmpty {
                        Text(flashcard.phonetics)
                            .font(.title3)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    
                    // Audio button
                    Button(action: {
                        let languageCode = audioService.getLanguageCode(for: flashcard.sourceLanguage)
                        audioService.speak(text: flashcard.word, language: languageCode)
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "speaker.wave.2.fill")
                                .font(.subheadline)
                            
                            Text("Listen")
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }
                        .foregroundColor(.blue)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(16)
                    }
                }
                
                Spacer()
            }
            .frame(height: 300) // Fixed height to match answer side
            .padding(.horizontal, 20)
            
            // Footer - Fixed position
            VStack(spacing: 3) {
                Text("What does this word mean?")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                
                Text("Tap to reveal answer")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
        .frame(width: cardWidth, height: cardHeight)
    }
    
    private var answerSide: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Answer")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                // CEFR Level Badge
                if let cefrLevel = flashcard.cefrLevel {
                    Text(cefrLevel)
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(cefrLevelColor(cefrLevel))
                        )
                }
                
                Image(systemName: "eye.fill")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 12)
            
            // Main Content - Proper spacing without gaps
            VStack(spacing: 16) {
                // Word with sound icon
                HStack(spacing: 8) {
                    Text(flashcard.word)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Button(action: {
                        let languageCode = audioService.getLanguageCode(for: flashcard.sourceLanguage)
                        audioService.speak(text: flashcard.word, language: languageCode)
                    }) {
                        Image(systemName: "speaker.wave.2.fill")
                            .font(.title3)
                            .foregroundColor(.blue)
                    }
                    
                    Spacer()
                }
                .padding(.horizontal, 20)
                
                // Definition
                VStack(alignment: .leading, spacing: 8) {
                    Text("Definition")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                    
                    Text(flashcard.definition)
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.horizontal, 20)
                
                // Translation
                VStack(alignment: .leading, spacing: 8) {
                    Text("Translation")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                    
                    Text(flashcard.translation)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.blue)
                        .multilineTextAlignment(.leading)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(10)
                }
                .padding(.horizontal, 20)
                
                // Example (if available)
                if !flashcard.example.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Example")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                        
                        Text(flashcard.example)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .italic()
                            .multilineTextAlignment(.leading)
                            .fixedSize(horizontal: false, vertical: true)
                            .lineLimit(nil)
                    }
                    .padding(.horizontal, 20)
                }
            }
            
            Spacer()
            
            // Footer - Fixed position
            Text("Tap to flip back")
                .font(.caption)
                .foregroundColor(.secondary)
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
        .frame(width: cardWidth, height: cardHeight)
    }
    
    // MARK: - Helper Methods
    
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
    
}

#Preview {
    StudyView()
}