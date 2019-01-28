//
//  ToDoItem.swift
//  toDo
//
//  Created by marcus on 22/01/2019.
//  Copyright © 2019 marcusklausen. All rights reserved.
//

import Foundation


struct TodoItem : Codable {
    var title: String
    var completed: Bool
    var createdAt: Date
    var itemIdentifier:UUID
    
    func saveItem(){
        DataManager.save(self, with: itemIdentifier.uuidString)
    }
    
    func deleteItem() {
        DataManager.delete(itemIdentifier.uuidString)
        
    }
    
    mutating func markAsCompleted() {
        self.completed = true
        DataManager.save(self, with: itemIdentifier.uuidString)
    }
}
