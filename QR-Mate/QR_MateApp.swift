//
//  QR_MateApp.swift
//  QR-Mate
//
//  Created by Dev Reptech on 22/02/2024.
//

import SwiftUI

@main
struct QR_MateApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
