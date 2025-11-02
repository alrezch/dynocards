//
//  User.swift
//  Dynocards
//
//  Created by User on 2024
//

import Foundation
import CoreData
import UIKit

@objc(User)
public class User: NSManagedObject {
    @NSManaged public var id: UUID?
    @NSManaged public var name: String?
    @NSManaged public var preferredLanguage: String?
    @NSManaged public var sourceLanguage: String?
    @NSManaged public var dailyGoal: Int16
    @NSManaged public var streakCount: Int16
    @NSManaged public var totalPoints: Int32
    @NSManaged public var dateJoined: Date?
    @NSManaged public var lastActiveDate: Date?
    @NSManaged public var notificationsEnabled: Bool
    @NSManaged public var studyReminderTime: Date?
    @NSManaged public var profileImageData: Data?
    
    public override func awakeFromInsert() {
        super.awakeFromInsert()
        self.id = UUID()
        self.dateJoined = Date()
        self.lastActiveDate = Date()
        self.dailyGoal = 10
        self.streakCount = 0
        self.totalPoints = 0
        self.notificationsEnabled = true
        self.preferredLanguage = "English"
        self.sourceLanguage = "English"
        self.name = "User"
        
        // Set default reminder time to 7 PM
        let calendar = Calendar.current
        let components = DateComponents(hour: 19, minute: 0)
        self.studyReminderTime = calendar.date(from: components) ?? Date()
    }
}

extension User {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<User> {
        return NSFetchRequest<User>(entityName: "User")
    }
    
    /// Returns profile image as UIImage if available
    var profileImage: UIImage? {
        guard let imageData = profileImageData else { return nil }
        return UIImage(data: imageData)
    }
    
    /// Sets profile image from UIImage
    func setProfileImage(_ image: UIImage?) {
        if let image = image {
            // Resize image to save storage space (max 500x500)
            if let resizedImage = image.resizeToMaxDimension(500),
               let imageData = resizedImage.jpegData(compressionQuality: 0.8) {
                profileImageData = imageData
            }
        } else {
            profileImageData = nil
        }
    }
} 