//
//  ExamSession.swift
//  Dynocards
//
//  Created by User on 2024
//

import Foundation
import CoreData

@objc(ExamSession)
public class ExamSession: NSManagedObject {
    
}

extension ExamSession {
    
    @nonobjc public class func fetchRequest() -> NSFetchRequest<ExamSession> {
        return NSFetchRequest<ExamSession>(entityName: "ExamSession")
    }
    
    @NSManaged public var id: UUID
    @NSManaged public var date: Date
    @NSManaged public var totalQuestions: Int16
    @NSManaged public var correctAnswers: Int16
    @NSManaged public var incorrectAnswers: Int16
    @NSManaged public var duration: Double
    
}

extension ExamSession : Identifiable {
    
}

