//
//  SubscriptionView.swift
//  Dynocards
//
//  Created by User on 2024
//

import SwiftUI

struct SubscriptionView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var aiService = AIService.shared
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 32) {
                    // Header
                    VStack(spacing: 20) {
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [.blue, .purple],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 100, height: 100)
                            
                            Image(systemName: "brain.head.profile")
                                .font(.system(size: 50))
                                .foregroundColor(.white)
                        }
                        
                        VStack(spacing: 8) {
                            Text("Unlock AI-Powered Learning")
                                .font(.title)
                                .fontWeight(.bold)
                                .multilineTextAlignment(.center)
                            
                            Text("Get unlimited access to ChatGPT-powered flashcard generation")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                    }
                    .padding(.top)
                    
                    // Features
                    VStack(alignment: .leading, spacing: 20) {
                        FeatureRow(
                            icon: "brain.head.profile",
                            title: "AI-Powered Definitions",
                            description: "Get comprehensive, contextual definitions for any word",
                            color: .blue
                        )
                        
                        FeatureRow(
                            icon: "globe",
                            title: "Smart Translations",
                            description: "Accurate translations in multiple languages",
                            color: .green
                        )
                        
                        FeatureRow(
                            icon: "quote.bubble",
                            title: "Natural Examples",
                            description: "Real-world example sentences for better understanding",
                            color: .orange
                        )
                        
                        FeatureRow(
                            icon: "speaker.wave.2",
                            title: "Pronunciation Guide",
                            description: "IPA phonetics and audio pronunciation",
                            color: .purple
                        )
                        
                        FeatureRow(
                            icon: "infinity",
                            title: "Unlimited Generation",
                            description: "Create as many AI flashcards as you want",
                            color: .mint
                        )
                    }
                    .padding(.horizontal)
                    
                    // Pricing
                    VStack(spacing: 20) {
                        Text("Choose Your Plan")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        VStack(spacing: 16) {
                            SubscriptionCard(
                                title: "Monthly",
                                price: "$4.99",
                                period: "per month",
                                isPopular: false
                            )
                            
                            SubscriptionCard(
                                title: "Annual",
                                price: "$39.99",
                                period: "per year",
                                savings: "Save 33%",
                                isPopular: true
                            )
                        }
                    }
                    
                    // Terms
                    VStack(spacing: 8) {
                        Text("• Cancel anytime")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text("• Secure payment via App Store")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text("• Terms of Service and Privacy Policy apply")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                }
                .padding(.horizontal, 20)
            }
            .navigationTitle("Premium")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.1))
                    .frame(width: 44, height: 44)
                
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .fontWeight(.medium)
                
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
    }
}

struct SubscriptionCard: View {
    let title: String
    let price: String
    let period: String
    let savings: String?
    let isPopular: Bool
    
    init(title: String, price: String, period: String, savings: String? = nil, isPopular: Bool = false) {
        self.title = title
        self.price = price
        self.period = period
        self.savings = savings
        self.isPopular = isPopular
    }
    
    var body: some View {
        VStack(spacing: 16) {
            if isPopular {
                Text("MOST POPULAR")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(
                        LinearGradient(
                            colors: [.blue, .purple],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(8)
            }
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    if let savings = savings {
                        Text(savings)
                            .font(.caption)
                            .foregroundColor(.green)
                            .fontWeight(.medium)
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text(price)
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text(period)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Button("Subscribe") {
                // Handle subscription purchase
                print("Subscribe to \(title) plan")
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                Group {
                    if isPopular {
                        LinearGradient(colors: [.blue, .purple], startPoint: .leading, endPoint: .trailing)
                    } else {
                        LinearGradient(colors: [Color(.systemGray5), Color(.systemGray5)], startPoint: .leading, endPoint: .trailing)
                    }
                }
            )
            .foregroundColor(isPopular ? .white : .primary)
            .cornerRadius(12)
            .fontWeight(.semibold)
        }
        .padding(20)
        .background(Color(.systemBackground))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(isPopular ? Color.blue : Color(.systemGray4), lineWidth: isPopular ? 2 : 1)
        )
        .cornerRadius(16)
    }
}

#Preview {
    SubscriptionView()
} 