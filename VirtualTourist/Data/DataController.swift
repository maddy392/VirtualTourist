//
//  DataController.swift
//  VirtualTourist
//
//  Created by Madhu Babu Adiki on 6/29/24.
//

import Foundation
import CoreData

class DataController {
    let persistentContainer: NSPersistentContainer
    
    var viewContext: NSManagedObjectContext {
        return persistentContainer.viewContext
    }
    
    init(modelName: String) {
        persistentContainer = NSPersistentContainer(name: modelName)
    }
    
    func load(completion: (() -> Void)? = nil) {
        persistentContainer.loadPersistentStores { storeDescription, error in
            guard error == nil else {
                fatalError(error!.localizedDescription)
            }
            completion?()
        }
    }
    
    func wipeAllData() {
        let fetchRequestPin: NSFetchRequest<NSFetchRequestResult> = Pin.fetchRequest()
        let deleteRequestPin = NSBatchDeleteRequest(fetchRequest: fetchRequestPin)
        
        let fetchRequestPhoto: NSFetchRequest<NSFetchRequestResult> = Photo.fetchRequest()
        let deleteRequestPhoto = NSBatchDeleteRequest(fetchRequest: fetchRequestPhoto)
        
        do {
            try viewContext.execute(deleteRequestPin)
            try viewContext.execute(deleteRequestPhoto)
            try viewContext.save()
        } catch {
            print("Failed to wipe data: \(error.localizedDescription)")
        }
    }
}
