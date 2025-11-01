//
//  Flashcard.swift
//  Dynocards
//
//  Created by User on 2024
//

import Foundation
import CoreData

@objc(Flashcard)
public class Flashcard: NSManagedObject {
    @NSManaged public var id: UUID
    @NSManaged public var word: String
    @NSManaged public var definition: String
    @NSManaged public var shortDefinition: String
    @NSManaged public var translation: String
    @NSManaged public var example: String
    @NSManaged public var phonetics: String
    @NSManaged public var audioURL: String?
    @NSManaged public var cefrLevel: String?
    @NSManaged public var tags: String?
    @NSManaged public var sourceLanguage: String
    @NSManaged public var targetLanguage: String
    @NSManaged public var dateCreated: Date
    @NSManaged public var lastStudied: Date?
    @NSManaged public var nextReview: Date
    @NSManaged public var leitnerBox: Int16
    @NSManaged public var studyCount: Int16
    @NSManaged public var correctCount: Int16
    @NSManaged public var mastered: Bool
    @NSManaged public var difficulty: Int16
    
    public override func awakeFromInsert() {
        super.awakeFromInsert()
        self.id = UUID()
        self.dateCreated = Date()
        self.nextReview = Date()
        self.leitnerBox = 1
        self.studyCount = 0
        self.correctCount = 0
        self.mastered = false
        self.difficulty = 1
    }
}

extension Flashcard {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<Flashcard> {
        return NSFetchRequest<Flashcard>(entityName: "Flashcard")
    }
    
    var successRate: Double {
        guard studyCount > 0 else { return 0.0 }
        return Double(correctCount) / Double(studyCount)
    }
    
    var tagList: [String] {
        guard let tags = tags, !tags.isEmpty else { return ["All words"] }
        return tags.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
    }
    
    func updateLeitnerBox(correct: Bool) {
        studyCount += 1
        
        if correct {
            correctCount += 1
            // Move to next box (max 5 boxes)
            if leitnerBox < 5 {
                leitnerBox += 1
            }
            // Set next review based on box level
            let days = pow(2.0, Double(leitnerBox - 1))
            nextReview = Calendar.current.date(byAdding: .day, value: Int(days), to: Date()) ?? Date()
            
            // Mark as mastered if in box 5 with high success rate
            if leitnerBox >= 5 && successRate >= 0.8 {
                mastered = true
            }
        } else {
            // Move back to box 1
            leitnerBox = 1
            nextReview = Calendar.current.date(byAdding: .hour, value: 1, to: Date()) ?? Date()
        }
        
        lastStudied = Date()
    }
} 