//
//  ViewController.swift
//  toDo
//
//  Created by marcus on 22/01/2019.
//  Copyright © 2019 marcusklausen. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let todoItem = TodoItem(title: "Read news2222", completed: false, createdAt: Date(), itemIdentifier:UUID())
        todoItem.saveItem()
        
        let todos = DataManager.loadAll(TodoItem.self)
        
        print(todos)
    }


}
