//
//  DynocardsApp.swift
//  Dynocards
//
//  Created by User on 2024
//

import SwiftUI

@main
struct DynocardsApp: App {
    let coreDataManager = CoreDataManager.shared
    
    init() {
        // Create sample data on first launch
        coreDataManager.createSampleDataIfNeeded()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, coreDataManager.context)
                .environmentObject(coreDataManager)
        }
    }
} 