//
//  AddWordView.swift
//  Dynocards
//
//  Created by User on 2024
//

import SwiftUI
import CoreData

struct AddWordView: View {
    @StateObject private var aiService = AIService.shared
    @StateObject private var coreDataManager = CoreDataManager.shared
    
    @State private var inputWord = ""
    @State private var sourceLanguage = "English"
    @State private var targetLanguage = "Spanish"
    @State private var isLoading = false
    @State private var showingResult = false
    @State private var generatedDefinition: WordDefinition?
    @State private var errorMessage: String?
    @State private var showingSuccess = false
    @State private var showingLanguageSelector = false
    @State private var selectedTags: [String] = []
    @State private var editingTagIndex: Int? = nil
    @State private var editingTagText: String = ""
    @State private var showingAddTagField = false
    @State private var newTagText: String = ""
    
    let languages = ["English", "Spanish", "French", "German", "Italian", "Portuguese", "Chinese", "Japanese", "Korean", "Arabic"]
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with Language Selector
            headerSection
            
            // Main Content
            if isLoading {
                // Loading State
                loadingCard
            } else if let definition = generatedDefinition {
                // Generated Card State
                generatedCardView(definition: definition)
            } else {
                // Input State
                inputStateView
            }
            
            // Error and Success Messages
            if errorMessage != nil {
                errorCard
            }
            
            if showingSuccess {
                successCard
            }
        }
        .background(
            LinearGradient(
                colors: [
                    Color(.systemBackground),
                    Color.green.opacity(0.03),
                    Color.blue.opacity(0.02)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .sheet(isPresented: $showingLanguageSelector) {
            LanguageSelectorSheet(
                sourceLanguage: $sourceLanguage,
                targetLanguage: $targetLanguage,
                languages: languages
            )
        }
    }
    
    private var headerSection: some View {
        HStack {
            Text("Add Word")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            Spacer()
            
            // Compact Language Selector
            Button(action: {
                showingLanguageSelector = true
            }) {
                HStack(spacing: 6) {
                    Image(systemName: "globe")
                        .font(.subheadline)
                        .foregroundColor(.blue)
                    
                    Text("\(sourceLanguage) → \(targetLanguage)")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    Image(systemName: "chevron.down")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(.systemGray6))
                )
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 10)
        .padding(.bottom, 16)
    }
    
    private var inputStateView: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Input Card
                inputCard
                
                // Generate Button
                generateButton
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
        }
    }
    
    private var inputCard: some View {
        VStack(spacing: 16) {
            TextField("Type a word to learn...", text: $inputWord)
                .font(.title2)
                .padding(20)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(.systemGray6))
                )
                .onSubmit {
                    generateFlashcard()
                }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
        )
    }
    
    
    private var generateButton: some View {
        Button(action: generateFlashcard) {
            HStack(spacing: 12) {
                Image(systemName: "brain.head.profile")
                    .font(.title3)
                
                Text("Generate with AI")
                    .font(.headline)
                    .fontWeight(.semibold)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(
                Group {
                    if inputWord.isEmpty {
                        Color.gray
                    } else {
                        LinearGradient(
                            colors: [.blue, .purple],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    }
                }
            )
            .cornerRadius(16)
            .shadow(color: .blue.opacity(0.3), radius: 10, x: 0, y: 5)
        }
        .disabled(inputWord.isEmpty)
    }
    
    private func generatedCardView(definition: WordDefinition) -> some View {
        ScrollView {
            VStack(spacing: 24) {
                // Generated Flashcard
                flashcardView(definition: definition)
                
                // Tags Section
                tagsSection
                
                // Action Buttons (Horizontal)
                actionButtonsView(definition: definition)
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
        }
        .onAppear {
            // Initialize tags from definition if not already set
            if selectedTags.isEmpty {
                selectedTags = definition.tags ?? []
            }
        }
    }
    
    private func flashcardView(definition: WordDefinition) -> some View {
        VStack(spacing: 20) {
            // Word and Translation
            VStack(spacing: 12) {
                HStack {
                    Spacer()
                    // CEFR Level Badge
                    if let cefrLevel = definition.cefrLevel {
                        Text(cefrLevel)
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(cefrLevelColor(cefrLevel))
                            )
                    }
                }
                
                Text(definition.word)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                if !definition.phonetics.isEmpty {
                    Text(definition.phonetics)
                        .font(.title3)
                        .foregroundColor(.secondary)
                }
                
                Text(definition.translation)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.blue)
            }
            .padding(.vertical, 20)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemGray6))
            )
            
            // Definition
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "book.fill")
                        .foregroundColor(.blue)
                        .font(.title3)
                    Text("Definition")
                        .font(.headline)
                        .fontWeight(.semibold)
                    Spacer()
                }
                
                Text(definition.definition)
                    .font(.body)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.leading)
            }
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemBackground))
                    .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
            )
            
            // Example
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "quote.bubble.fill")
                        .foregroundColor(.green)
                        .font(.title3)
                    Text("Example")
                        .font(.headline)
                        .fontWeight(.semibold)
                    Spacer()
                }
                
                Text(definition.example)
                    .font(.body)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.leading)
            }
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemBackground))
                    .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
            )
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
        )
    }
    
    private func actionButtonsView(definition: WordDefinition) -> some View {
        HStack(spacing: 16) {
            // Save Button
            Button(action: {
                saveFlashcard(definition: definition)
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title3)
                    
                    Text("Save")
                        .font(.headline)
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
                .cornerRadius(12)
                .shadow(color: .green.opacity(0.3), radius: 6, x: 0, y: 3)
            }
            
            // Discard Button
            Button(action: {
                discardCard()
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title3)
                    
                    Text("Discard")
                        .font(.headline)
                        .fontWeight(.semibold)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    LinearGradient(
                        colors: [.red, .pink],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(12)
                .shadow(color: .red.opacity(0.3), radius: 6, x: 0, y: 3)
            }
        }
    }
    
    private func discardCard() {
        withAnimation(.easeInOut(duration: 0.3)) {
            generatedDefinition = nil
            inputWord = ""
            errorMessage = nil
            showingSuccess = false
        }
    }
    
    
    private var loadingCard: some View {
        VStack(spacing: 40) {
            Spacer()
            
            // Loading Animation
            ZStack {
                Circle()
                    .stroke(Color.blue.opacity(0.2), lineWidth: 4)
                    .frame(width: 80, height: 80)
                
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                    .scaleEffect(2.0)
            }
            
            VStack(spacing: 12) {
                Text("🤖 AI is generating your flashcard...")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .multilineTextAlignment(.center)
                
                Text("Using AI to generate definition, translation, and example")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                
                Text("Powered by OpenAI")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.blue)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(12)
            }
            
            Spacer()
        }
        .padding(.horizontal, 40)
    }
    
    private func resultCard(definition: WordDefinition) -> some View {
        VStack(spacing: 20) {
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .font(.title2)
                    .foregroundColor(.green)
                
                Text("Flashcard Generated")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
            }
            
            FlashcardPreview(definition: definition, sourceLanguage: sourceLanguage)
            
            HStack(spacing: 12) {
                Button("Regenerate") {
                    generateFlashcard()
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color(.systemGray5))
                .foregroundColor(.primary)
                .cornerRadius(12)
                
                Button("Save Card") {
                    saveFlashcard(definition: definition)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(
                    LinearGradient(
                        colors: [.green, .mint],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .foregroundColor(.white)
                .cornerRadius(12)
                .shadow(color: .green.opacity(0.3), radius: 6, x: 0, y: 3)
            }
        }
        .padding(20)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
    }
    
    private var successCard: some View {
        VStack(spacing: 20) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(.green)
            
            VStack(spacing: 8) {
                Text("Card Saved!")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.green)
                
                Text("Your new flashcard has been added to your collection")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            Button("Add Another Word") {
                resetForm()
            }
            .font(.headline)
            .fontWeight(.semibold)
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
        .padding(32)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 12, x: 0, y: 6)
        )
        .padding(.horizontal, 20)
    }
    
    private var errorCard: some View {
        HStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.orange)
            
            Text(errorMessage ?? "")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Spacer()
        }
        .padding()
        .background(Color.orange.opacity(0.1))
        .cornerRadius(12)
    }
    
    
    private func generateFlashcard() {
        let trimmedWord = inputWord.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedWord.isEmpty else { return }
        
        // Check for duplicate before generating
        if coreDataManager.checkWordExists(word: trimmedWord, sourceLanguage: sourceLanguage) {
            errorMessage = "This word already exists in your collection"
            return
        }
        
        isLoading = true
        errorMessage = nil
        showingSuccess = false
        
        Task {
            do {
                let definition = try await aiService.generateFlashcard(
                    word: trimmedWord,
                    sourceLanguage: sourceLanguage,
                    targetLanguage: targetLanguage
                )
                
                await MainActor.run {
                    self.generatedDefinition = definition
                    // Initialize tags from suggestion
                    self.selectedTags = definition.tags ?? []
                    self.isLoading = false
                    self.showingResult = true
                }
            } catch {
                await MainActor.run {
                    self.isLoading = false
                    self.errorMessage = "Failed to generate flashcard. Please try again."
                }
            }
        }
    }
    
    
    private func saveFlashcard(definition: WordDefinition) {
        // Double-check for duplicate before saving
        if coreDataManager.checkWordExists(word: definition.word, sourceLanguage: sourceLanguage) {
            errorMessage = "This word already exists in your collection"
            return
        }
        
        // Use selected tags or default to empty (will use "All words" internally)
        let tagsToSave = selectedTags.filter { $0.lowercased() != "all words" && !$0.isEmpty }
        
        let success = coreDataManager.createFlashcard(
            word: definition.word,
            definition: definition.definition,
            shortDefinition: definition.shortDefinition,
            translation: definition.translation,
            example: definition.example,
            phonetics: definition.phonetics,
            sourceLanguage: sourceLanguage,
            targetLanguage: targetLanguage,
            cefrLevel: definition.cefrLevel,
            tags: tagsToSave.isEmpty ? nil : tagsToSave
        )
        
        if success {
            showingSuccess = true
            generatedDefinition = nil
            showingResult = false
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                resetForm()
            }
        } else {
            errorMessage = "Failed to save flashcard. Please try again."
        }
    }
    
    private func resetForm() {
        inputWord = ""
        generatedDefinition = nil
        showingResult = false
        showingSuccess = false
        errorMessage = nil
        selectedTags = []
        editingTagIndex = nil
        editingTagText = ""
        showingAddTagField = false
        newTagText = ""
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
    
    // MARK: - Tags Section
    
    private var tagsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Tags")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            if selectedTags.isEmpty && !showingAddTagField {
                Text("No tags added")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .italic()
            } else {
                // Tags Display
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(Array(selectedTags.enumerated()), id: \.offset) { index, tag in
                            if editingTagIndex == index {
                                // Editable tag
                                TextField("Tag", text: $editingTagText)
                                    .textFieldStyle(.roundedBorder)
                                    .font(.subheadline)
                                    .frame(width: 100)
                                    .onSubmit {
                                        if !editingTagText.trimmingCharacters(in: .whitespaces).isEmpty {
                                            selectedTags[index] = editingTagText.trimmingCharacters(in: .whitespaces)
                                        }
                                        editingTagIndex = nil
                                        editingTagText = ""
                                    }
                                    .onAppear {
                                        editingTagText = tag
                                    }
                            } else {
                                // Tag chip
                                TagChipView(
                                    tag: tag,
                                    onDelete: {
                                        selectedTags.remove(at: index)
                                    },
                                    onEdit: {
                                        editingTagIndex = index
                                        editingTagText = tag
                                    }
                                )
                            }
                        }
                        
                        // Add tag button/field
                        if showingAddTagField {
                            TextField("New tag", text: $newTagText)
                                .textFieldStyle(.roundedBorder)
                                .font(.subheadline)
                                .frame(width: 100)
                                .onSubmit {
                                    addNewTag()
                                }
                                .submitLabel(.done)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            
            // Add Tag Button
            if !showingAddTagField && selectedTags.count < 5 {
                Button(action: {
                    showingAddTagField = true
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "plus.circle.fill")
                            .font(.subheadline)
                        Text("Add Tag")
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                    .foregroundColor(.blue)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(8)
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
        )
    }
    
    private func addNewTag() {
        let trimmedTag = newTagText.trimmingCharacters(in: .whitespaces)
        if !trimmedTag.isEmpty && !selectedTags.contains(trimmedTag) && selectedTags.count < 5 {
            selectedTags.append(trimmedTag.lowercased())
            newTagText = ""
            showingAddTagField = false
        }
    }
    
}

// MARK: - Tag Chip View
struct TagChipView: View {
    let tag: String
    let onDelete: () -> Void
    let onEdit: () -> Void
    
    var body: some View {
        HStack(spacing: 6) {
            Text(tag.capitalized)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.primary)
                .onTapGesture {
                    onEdit()
                }
            
            Button(action: onDelete) {
                Image(systemName: "xmark.circle.fill")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.blue.opacity(0.15))
        )
    }
}


struct FlashcardPreview: View {
    let definition: WordDefinition
    let sourceLanguage: String
    @State private var isFlipped = false
    
    var body: some View {
        ZStack {
            // Back of card - Always present but rotated
            ScrollView {
                VStack(spacing: 20) {
                    // Word Header on Back
                    VStack(spacing: 8) {
                        Text(definition.word)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        
                        if !definition.phonetics.isEmpty {
                            Text(definition.phonetics)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.white.opacity(0.8))
                    .cornerRadius(10)
                    
                    // Definition Section
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Image(systemName: "book.fill")
                                .foregroundColor(.blue)
                            Text("Definition")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)
                            Spacer()
                        }
                        
                        Text(definition.definition)
                            .font(.body)
                            .foregroundColor(.primary)
                            .lineLimit(nil)
                            .multilineTextAlignment(.leading)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.white.opacity(0.6))
                    .cornerRadius(10)
                    
                    // Translation Section
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Image(systemName: "globe")
                                .foregroundColor(.green)
                            Text("Translation")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)
                            Spacer()
                        }
                        
                        Text(definition.translation)
                            .font(.headline)
                            .fontWeight(.medium)
                            .foregroundColor(.green)
                            .lineLimit(nil)
                            .multilineTextAlignment(.leading)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.white.opacity(0.6))
                    .cornerRadius(10)
                    
                    // Example Section (if available)
                    if !definition.example.isEmpty {
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                Image(systemName: "quote.bubble.fill")
                                    .foregroundColor(.orange)
                                Text("Example")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.primary)
                                Spacer()
                            }
                            
                            Text(definition.example)
                                .font(.body)
                                .foregroundColor(.primary)
                                .italic()
                                .lineLimit(nil)
                                .multilineTextAlignment(.leading)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.white.opacity(0.6))
                        .cornerRadius(10)
                    }
                    
                    // Short Definition (if different)
                    if !definition.shortDefinition.isEmpty && definition.shortDefinition != definition.definition {
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                Image(systemName: "lightbulb.fill")
                                    .foregroundColor(.yellow)
                                Text("Quick Summary")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.primary)
                                Spacer()
                            }
                            
                            Text(definition.shortDefinition)
                                .font(.subheadline)
                                .foregroundColor(.primary)
                                .lineLimit(nil)
                                .multilineTextAlignment(.leading)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.white.opacity(0.6))
                        .cornerRadius(10)
                    }
                    
                    Text("Tap to flip back")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                        .padding(.top, 8)
                }
                .padding(20)
            }
            .frame(maxWidth: .infinity, minHeight: 200)
            .background(
                LinearGradient(
                    colors: [.blue.opacity(0.08), .purple.opacity(0.05)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .cornerRadius(16)
            .opacity(isFlipped ? 1 : 0)
            .rotation3DEffect(.degrees(isFlipped ? 0 : 180), axis: (x: 0, y: 1, z: 0))
            
            // Front of card - Always present but rotated
            VStack(spacing: 20) {
                Spacer()
                
                VStack(spacing: 12) {
                    Text(definition.word)
                        .font(.system(size: 32, weight: .bold, design: .default))
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.center)
                        .lineLimit(nil)
                        .fixedSize(horizontal: false, vertical: true)
                    
                    if !definition.phonetics.isEmpty {
                        Text(definition.phonetics)
                            .font(.title3)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    
                    Text(definition.translation)
                        .font(.title2)
                        .fontWeight(.medium)
                        .foregroundColor(.blue)
                        .multilineTextAlignment(.center)
                        .lineLimit(nil)
                        .fixedSize(horizontal: false, vertical: true)
                }
                
                Spacer()
                
                Text("Tap to see full definition")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                
                Spacer()
            }
            .padding(20)
            .frame(maxWidth: .infinity, minHeight: 200)
            .background(
                LinearGradient(
                    colors: [.mint.opacity(0.08), .cyan.opacity(0.05)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .cornerRadius(16)
            .opacity(isFlipped ? 0 : 1)
            .rotation3DEffect(.degrees(isFlipped ? -180 : 0), axis: (x: 0, y: 1, z: 0))
        }
        .onTapGesture {
            withAnimation(.easeInOut(duration: 0.8)) {
                isFlipped.toggle()
            }
        }
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
    }
}

// MARK: - Language Selector Sheet
struct LanguageSelectorSheet: View {
    @Binding var sourceLanguage: String
    @Binding var targetLanguage: String
    let languages: [String]
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 8) {
                    Text("Select Languages")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Text("Choose source and target languages for translation")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 20)
                
                // Language Selection
                VStack(spacing: 20) {
                    // Source Language
                    VStack(alignment: .leading, spacing: 12) {
                        Text("From")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                        
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                            ForEach(languages, id: \.self) { language in
                                Button(action: {
                                    sourceLanguage = language
                                }) {
                                    Text(language)
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                        .foregroundColor(sourceLanguage == language ? .white : .primary)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 12)
                                        .background(
                                            RoundedRectangle(cornerRadius: 12)
                                                .fill(sourceLanguage == language ? Color.blue : Color(.systemGray6))
                                        )
                                }
                            }
                        }
                    }
                    
                    // Swap Button
                    Button(action: {
                        let temp = sourceLanguage
                        sourceLanguage = targetLanguage
                        targetLanguage = temp
                    }) {
                        Image(systemName: "arrow.up.arrow.down")
                            .font(.title2)
                            .foregroundColor(.blue)
                            .frame(width: 44, height: 44)
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(22)
                    }
                    
                    // Target Language
                    VStack(alignment: .leading, spacing: 12) {
                        Text("To")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                        
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                            ForEach(languages, id: \.self) { language in
                                Button(action: {
                                    targetLanguage = language
                                }) {
                                    Text(language)
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                        .foregroundColor(targetLanguage == language ? .white : .primary)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 12)
                                        .background(
                                            RoundedRectangle(cornerRadius: 12)
                                                .fill(targetLanguage == language ? Color.green : Color(.systemGray6))
                                        )
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, 20)
                
                Spacer()
                
                // Done Button
                Button(action: {
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Text("Done")
                        .font(.headline)
                        .fontWeight(.semibold)
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
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
            .navigationBarHidden(true)
            .background(Color(.systemBackground))
        }
    }
}

#Preview {
    AddWordView()
} 