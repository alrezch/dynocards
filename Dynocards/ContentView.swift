//
//  ContentView.swift
//  Dynocards
//
//  Created by User on 2024
//

import SwiftUI

struct ContentView: View {
    @State private var selectedTab = 0
    @State private var showingWelcome = true
    
    var body: some View {
        if showingWelcome {
            WelcomeView(showingWelcome: $showingWelcome)
        } else {
            MainTabView(selectedTab: $selectedTab, showingWelcome: $showingWelcome)
        }
    }
}

struct WelcomeView: View {
    @Binding var showingWelcome: Bool
    @State private var animationOffset: CGFloat = 100
    @State private var animationOpacity: Double = 0
    
    var body: some View {
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
            
            VStack(spacing: 40) {
                Spacer()
                
                // App Icon and Title
                VStack(spacing: 24) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [.blue, .purple],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 120, height: 120)
                            .shadow(color: .blue.opacity(0.3), radius: 20, x: 0, y: 10)
                        
                        Image(systemName: "brain.head.profile")
                            .font(.system(size: 50, weight: .medium))
                            .foregroundColor(.white)
                    }
                    .offset(y: animationOffset)
                    .opacity(animationOpacity)
                    
                    VStack(spacing: 12) {
                        Text("Dynocards")
                            .font(.system(size: 42, weight: .bold, design: .rounded))
                            .foregroundColor(.primary)
                        
                        Text("AI-Powered Vocabulary Learning")
                            .font(.title3)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                    }
                    .offset(y: animationOffset)
                    .opacity(animationOpacity)
                }
                
                // Features
                VStack(spacing: 20) {
                    FeatureItem(
                        icon: "sparkles",
                        title: "AI-Generated Content",
                        description: "Get contextual definitions and examples"
                    )
                    
                    FeatureItem(
                        icon: "repeat",
                        title: "Spaced Repetition",
                        description: "Learn efficiently with the Leitner system"
                    )
                    
                    FeatureItem(
                        icon: "chart.line.uptrend.xyaxis",
                        title: "Track Progress",
                        description: "Monitor your learning journey"
                    )
                }
                .offset(y: animationOffset)
                .opacity(animationOpacity)
                
                Spacer()
                
                // Get Started Button
                Button(action: {
                    withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                        showingWelcome = false
                    }
                }) {
                    HStack(spacing: 12) {
                        Text("Get Started")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        Image(systemName: "arrow.right")
                            .font(.headline)
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
                    .shadow(color: .blue.opacity(0.3), radius: 10, x: 0, y: 5)
                }
                .padding(.horizontal, 32)
                .offset(y: animationOffset)
                .opacity(animationOpacity)
                
                Spacer()
            }
            .padding(.horizontal, 24)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 1.0).delay(0.2)) {
                animationOffset = 0
                animationOpacity = 1
            }
        }
    }
}

struct FeatureItem: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.blue)
                .frame(width: 32, height: 32)
                .background(Color.blue.opacity(0.1))
                .cornerRadius(8)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding(.horizontal, 8)
    }
}

struct MainTabView: View {
    @Binding var selectedTab: Int
    @Binding var showingWelcome: Bool
    @State private var isInStudyMode = false
    
    var body: some View {
        ZStack {
            // Regular TabView (hidden during study mode)
            TabView(selection: $selectedTab) {
                HomeView()
                    .tabItem {
                        Image(systemName: selectedTab == 0 ? "house.fill" : "house")
                        Text("Home")
                    }
                    .tag(0)
                
                AddWordView()
                    .tabItem {
                        Image(systemName: selectedTab == 1 ? "plus.circle.fill" : "plus.circle")
                        Text("Add")
                    }
                    .tag(1)
                
                // StudyView in TabView (shows calendar when not in study mode)
                StudyView()
                    .tabItem {
                        Image(systemName: selectedTab == 2 ? "brain.head.profile" : "brain")
                        Text("Study")
                    }
                    .tag(2)
                
                DashboardView()
                    .tabItem {
                        Image(systemName: selectedTab == 3 ? "chart.bar.fill" : "chart.bar")
                        Text("Progress")
                    }
                    .tag(3)
                
                SettingsView()
                    .tabItem {
                        Image(systemName: selectedTab == 4 ? "gearshape.fill" : "gearshape")
                        Text("Settings")
                    }
                    .tag(4)
            }
            .accentColor(.blue)
            .opacity(isInStudyMode ? 0 : 1)
            .animation(.easeInOut(duration: 0.3), value: isInStudyMode)
            .onAppear {
                // Customize tab bar appearance
                let appearance = UITabBarAppearance()
                appearance.configureWithOpaqueBackground()
                appearance.backgroundColor = UIColor.systemBackground
                appearance.shadowColor = UIColor.separator
                
                UITabBar.appearance().standardAppearance = appearance
                UITabBar.appearance().scrollEdgeAppearance = appearance
            }
            .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("NavigateToAddWord"))) { _ in
                selectedTab = 1 // Switch to Add Word tab (index 1)
            }
            .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("NavigateToStudy"))) { _ in
                selectedTab = 2 // Switch to Study tab (index 2)
            }
            
            // StudyView overlay (visible during study mode)
            if isInStudyMode {
                StudyView()
                    .transition(.opacity)
                    .animation(.easeInOut(duration: 0.3), value: isInStudyMode)
            }
        }
    }
}

#Preview {
    ContentView()
} 