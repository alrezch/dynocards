//
//  ExportDataView.swift
//  Dynocards
//
//  Created by User on 2024
//

import SwiftUI
import CoreData

struct ExportDataView: View {
    @StateObject private var coreDataManager = CoreDataManager.shared
    @State private var showingShareSheet = false
    @State private var exportURL: URL?
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Image(systemName: "square.and.arrow.up")
                    .font(.system(size: 60))
                    .foregroundColor(.blue)
                
                Text("Export Your Data")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("Export all your flashcards and progress data to a JSON file.")
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
                
                Spacer()
                
                Button("Export Data") {
                    exportData()
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
                .padding(.horizontal)
                
                Spacer()
            }
            .padding()
            .navigationTitle("Export Data")
            .navigationBarTitleDisplayMode(.inline)
        }
        .sheet(isPresented: $showingShareSheet) {
            if let url = exportURL {
                ShareSheet(activityItems: [url])
            }
        }
    }
    
    private func exportData() {
        let flashcards = coreDataManager.fetchFlashcards()
        let user = coreDataManager.getOrCreateUser()
        
        let exportData: [String: Any] = [
            "user": [
                "name": user.name ?? "User",
                "totalPoints": user.totalPoints,
                "streakCount": user.streakCount,
                "dateJoined": user.dateJoined?.timeIntervalSince1970 ?? Date().timeIntervalSince1970
            ] as [String: Any],
            "flashcards": flashcards.map { card in
                [
                    "word": card.word,
                    "definition": card.definition,
                    "shortDefinition": card.shortDefinition,
                    "example": card.example,
                    "sourceLanguage": card.sourceLanguage,
                    "targetLanguage": card.targetLanguage,
                    "leitnerBox": card.leitnerBox,
                    "mastered": card.mastered,
                    "studyCount": card.studyCount,
                    "correctCount": card.correctCount,
                    "dateCreated": card.dateCreated.timeIntervalSince1970
                ] as [String: Any]
            }
        ]
        
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: exportData, options: .prettyPrinted)
            
            let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let exportURL = documentsPath.appendingPathComponent("dynocards_export.json")
            
            try jsonData.write(to: exportURL)
            
            self.exportURL = exportURL
            showingShareSheet = true
            
        } catch {
            print("Export error: \(error)")
        }
    }
} 