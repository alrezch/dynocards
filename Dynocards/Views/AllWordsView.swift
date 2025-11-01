//
//  AllWordsView.swift
//  Dynocards
//
//  Created by User on 2024
//

import SwiftUI
import CoreData

struct AllWordsView: View {
    @StateObject private var coreDataManager = CoreDataManager.shared
    @State private var flashcards: [Flashcard] = []
    @State private var searchText = ""
    @State private var selectedTag: String? = nil
    
    var filteredFlashcards: [Flashcard] {
        var filtered = flashcards
        
        // Filter by tag
        if let tag = selectedTag, tag != "All words" {
            filtered = filtered.filter { flashcard in
                flashcard.tagList.contains(tag)
            }
        }
        
        // Filter by search text
        if !searchText.isEmpty {
            filtered = filtered.filter { flashcard in
                flashcard.word.localizedCaseInsensitiveContains(searchText) ||
                flashcard.definition.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        return filtered
    }
    
    var availableTags: [String] {
        var allTags: Set<String> = ["All words"]
        for flashcard in flashcards {
            allTags.formUnion(flashcard.tagList)
        }
        return Array(allTags).sorted()
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Search Bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                
                TextField("Search words...", text: $searchText)
                    .textFieldStyle(PlainTextFieldStyle())
                
                if !searchText.isEmpty {
                    Button(action: {
                        searchText = ""
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding()
            .background(Color(.systemGray6))
            
            // Tag Filter
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(availableTags, id: \.self) { tag in
                        Button(action: {
                            selectedTag = selectedTag == tag ? nil : tag
                        }) {
                            HStack(spacing: 6) {
                                Text(tag)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                
                                if selectedTag == tag {
                                    Image(systemName: "checkmark")
                                        .font(.caption)
                                }
                            }
                            .foregroundColor(selectedTag == tag ? .white : .primary)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(selectedTag == tag ? Color.blue : Color(.systemGray6))
                            )
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 12)
            }
            
            // Words List
            if filteredFlashcards.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)
                    
                    Text("No words found")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    Text(searchText.isEmpty ? "Start adding words to build your vocabulary!" : "Try a different search or filter")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding()
            } else {
                List {
                    ForEach(filteredFlashcards, id: \.id) { flashcard in
                        NavigationLink(destination: WordDetailView(flashcard: flashcard)) {
                            WordRowView(flashcard: flashcard)
                        }
                    }
                    .onDelete(perform: deleteWords)
                }
                .listStyle(PlainListStyle())
            }
        }
        .navigationTitle("All Words")
        .navigationBarTitleDisplayMode(.large)
        .onAppear {
            loadWords()
        }
    }
    
    private func loadWords() {
        flashcards = coreDataManager.fetchAllFlashcards()
    }
    
    private func deleteWords(offsets: IndexSet) {
        let wordsToDelete = offsets.map { filteredFlashcards[$0] }
        for word in wordsToDelete {
            coreDataManager.deleteFlashcard(word)
        }
        loadWords()
        // Update filtered list
        flashcards = coreDataManager.fetchAllFlashcards()
    }
}

struct WordRowView: View {
    let flashcard: Flashcard
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(flashcard.word)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Spacer()
                
                if flashcard.mastered {
                    Image(systemName: "star.fill")
                        .foregroundColor(.yellow)
                        .font(.caption)
                }
            }
            
            Text(flashcard.shortDefinition)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .lineLimit(2)
            
            // Tags
            if !flashcard.tagList.isEmpty && flashcard.tagList != ["All words"] {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(flashcard.tagList.filter { $0 != "All words" }, id: \.self) { tag in
                            Text(tag)
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.blue.opacity(0.1))
                                .foregroundColor(.blue)
                                .cornerRadius(8)
                        }
                    }
                }
            }
            
            // CEFR Level
            if let cefrLevel = flashcard.cefrLevel {
                HStack {
                    Text("CEFR: \(cefrLevel)")
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(cefrLevelColor(cefrLevel).opacity(0.1))
                        .foregroundColor(cefrLevelColor(cefrLevel))
                        .cornerRadius(8)
                    
                    Spacer()
                }
            }
        }
        .padding(.vertical, 4)
    }
    
    private func cefrLevelColor(_ level: String) -> Color {
        switch level {
        case "A1", "A2": return .green
        case "B1", "B2": return .blue
        case "C1", "C2": return .purple
        default: return .gray
        }
    }
}

struct WordDetailView: View {
    let flashcard: Flashcard
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Word Header
                VStack(alignment: .leading, spacing: 8) {
                    Text(flashcard.word)
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    if let phonetics = flashcard.phonetics as String?, !phonetics.isEmpty {
                        Text(phonetics)
                            .font(.title3)
                            .foregroundColor(.secondary)
                    }
                }
                
                // Definition
                VStack(alignment: .leading, spacing: 8) {
                    Text("Definition")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    Text(flashcard.definition)
                        .font(.body)
                }
                
                // Example
                if !flashcard.example.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Example")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        
                        Text(flashcard.example)
                            .font(.body)
                            .italic()
                            .foregroundColor(.primary)
                    }
                }
                
                // Translation
                VStack(alignment: .leading, spacing: 8) {
                    Text("Translation")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    Text(flashcard.translation)
                        .font(.body)
                }
                
                // CEFR Level
                if let cefrLevel = flashcard.cefrLevel {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("CEFR Level")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        
                        Text(cefrLevel)
                            .font(.body)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(cefrLevelColor(cefrLevel).opacity(0.1))
                            .foregroundColor(cefrLevelColor(cefrLevel))
                            .cornerRadius(8)
                    }
                }
                
                // Tags
                if !flashcard.tagList.isEmpty && flashcard.tagList != ["All words"] {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Tags")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        
                        HStack {
                            ForEach(flashcard.tagList.filter { $0 != "All words" }, id: \.self) { tag in
                                Text(tag)
                                    .font(.subheadline)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(Color.blue.opacity(0.1))
                                    .foregroundColor(.blue)
                                    .cornerRadius(8)
                            }
                            Spacer()
                        }
                    }
                }
            }
            .padding()
        }
        .navigationTitle(flashcard.word)
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func cefrLevelColor(_ level: String) -> Color {
        switch level {
        case "A1", "A2": return .green
        case "B1", "B2": return .blue
        case "C1", "C2": return .purple
        default: return .gray
        }
    }
}


