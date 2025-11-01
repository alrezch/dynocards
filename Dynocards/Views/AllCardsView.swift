//
//  AllCardsView.swift
//  Dynocards
//
//  Created by User on 2024
//

import SwiftUI
import CoreData

struct AllCardsView: View {
    @StateObject private var coreDataManager = CoreDataManager.shared
    @State private var flashcards: [Flashcard] = []
    
    var body: some View {
        NavigationView {
            List {
                ForEach(flashcards, id: \.id) { card in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(card.word)
                            .font(.headline)
                            .fontWeight(.medium)
                        
                        Text(card.shortDefinition)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        HStack {
                            Text("Box \(card.leitnerBox)")
                                .font(.caption)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.blue.opacity(0.2))
                                .cornerRadius(4)
                            
                            Spacer()
                            
                            if card.mastered {
                                Text("Mastered")
                                    .font(.caption)
                                    .foregroundColor(.green)
                            }
                        }
                    }
                    .padding(.vertical, 2)
                }
                .onDelete(perform: deleteCard)
            }
            .navigationTitle("All Cards")
            .onAppear {
                loadCards()
            }
        }
    }
    
    private func loadCards() {
        flashcards = coreDataManager.fetchFlashcards()
    }
    
    private func deleteCard(offsets: IndexSet) {
        for index in offsets {
            coreDataManager.deleteFlashcard(flashcards[index])
        }
        loadCards()
    }
} 