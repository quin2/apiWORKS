//
//  DataController.swift
//  apiWORKS
//
//  Created by Quinn Vinlove on 7/4/22.
//

import Foundation
import CoreData

class DataController: ObservableObject {
    init() {
        container.loadPersistentStores { description, error in
            if let error = error {
                print("Core Data failed to load: \(error.localizedDescription)")
            }
        }
    }
    
    let container = NSPersistentContainer(name: "APIModel")
}
