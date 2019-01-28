//
//  TodoTableViewController.swift
//  toDo
//
//  Created by marcus on 23/01/2019.
//  Copyright © 2019 marcusklausen. All rights reserved.
//

import UIKit
import MultipeerConnectivity

class TodoTableViewController: UITableViewController, MCSessionDelegate, MCBrowserViewControllerDelegate {

    
    

    var todoItems:[TodoItem]! {
        didSet {
            progressBar.setProgress(progress, animated: true)
        }
    }
    
    var peerID: MCPeerID!
    var mcSession: MCSession!
    var mcAdvertiserAssistant: MCAdvertiserAssistant!
    
    
    @IBOutlet weak var progressBar: UIProgressView!
    
    var progress: Float {
        if todoItems.count > 0 {
            return Float(todoItems.filter({$0.completed}).count) / Float(todoItems.count)
        } else {
            return 0
        }
    }
    
    var connectionButtonReference: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        setupConnectivity()
        loadData()
    }

    
    func setupConnectivity() {
        
        peerID = MCPeerID(displayName: UIDevice.current.name)
        mcSession = MCSession(peer: peerID, securityIdentity: nil, encryptionPreference: .required)
        mcSession.delegate = self
    }
    
    func loadData() {
        todoItems = [TodoItem]()
        todoItems = DataManager.loadAll(TodoItem.self).sorted(by: {
            $0.createdAt < $1.createdAt
        })
        tableView.reloadData()
        
        print("Load data \(self.todoItems)")
        
        progressBar.setProgress(progress, animated: true)
    }
    
    func addNewTodo() {
    
        print("Pre new todo : \(self.todoItems)")
        let addAlert = UIAlertController(title: "Ny to-do?", message: "Skriv title", preferredStyle: .alert)
        addAlert.addTextField { (textfield:UITextField) in
            textfield.placeholder = "Hvad skal du nå?"
        }
        addAlert.addAction(UIAlertAction(title: "Opret", style: .default, handler: { (action:UIAlertAction) in
            
            guard let title = addAlert.textFields?.first?.text else { return }
            
            let newTodo = TodoItem(title: title, completed: false, createdAt: Date(), itemIdentifier:UUID())
            
            newTodo.saveItem()
            
            self.todoItems.append(newTodo)
            
            let indexPath = IndexPath(row: self.tableView.numberOfRows(inSection: 0), section: 0)
            
            self.tableView.insertRows(at: [indexPath], with: .automatic)
            
            print("Post new todo: \(self.todoItems)")
        }))
        
        
        
        addAlert.addAction(UIAlertAction(title: "Annuller", style: .default, handler: nil))
        
        self.present(addAlert, animated: true, completion: nil)
    }
    
    func showConnectivity() {
        
        let actionSheet = UIAlertController(title: "Todo deling", message: "Vil du deltage i, eller oprette, en session?", preferredStyle: .actionSheet)
        
        actionSheet.addAction(UIAlertAction(title: "Opret session", style: .default, handler: {
            (action:UIAlertAction) in
            
            self.mcAdvertiserAssistant = MCAdvertiserAssistant(serviceType: "mk-td", discoveryInfo: nil, session: self.mcSession)
            self.mcAdvertiserAssistant.start()
            
        }))
        
        actionSheet.addAction(UIAlertAction(title: "Deltag i session", style: .default, handler: {
            (action:UIAlertAction) in
            
            let mcBrowser = MCBrowserViewController(serviceType: "mk-td", session: self.mcSession)
            mcBrowser.delegate = self
            self.present(mcBrowser, animated: true, completion: nil)
            
        }))
        
        actionSheet.addAction(UIAlertAction(title: "Annuller", style: .cancel, handler: nil))
        
        self.present(actionSheet, animated: true, completion: nil)
    }
    
    
    func completeTodo(_ indexPath: IndexPath) {
        var todoItem = todoItems[indexPath.row]
        todoItem.markAsCompleted()
        todoItems[indexPath.row] = todoItem
        
        if let cell = tableView.cellForRow(at: indexPath) as? ToDoTableViewCell {
            cell.todoLabel.attributedText = strikeThroughText(todoItem.title)
            
            
            UIView.animate(withDuration: 0.1,
                           animations: {
        cell.transform = cell.transform.scaledBy(x: 1.5, y: 1.5)
            }) { (success) in
                UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 0.5, options: .curveEaseOut, animations: {cell.transform = CGAffineTransform.identity}, completion: nil)
            }
        }
    print(todoItems)
    
    }
    
 
    
    func sendTodo(_ todoItem: TodoItem) {
        if mcSession.connectedPeers.count > 0 {
            if let todoData = DataManager.loadData(todoItem.itemIdentifier.uuidString) {
                do {
                    try mcSession.send(todoData, toPeers: mcSession.connectedPeers, with: .reliable)
                } catch {
                    fatalError("Kunne ikke sende todo punkt")
                }
            }
        } else {
            showConnectivity()
        }
    }
    
    func strikeThroughText (_ text:String) -> NSAttributedString {
        let attributeString: NSMutableAttributedString = NSMutableAttributedString(string: text)
        attributeString.addAttribute(NSAttributedString.Key.strikethroughStyle, value: 1, range: NSMakeRange(0, attributeString.length))
        
        return attributeString
    }
    
    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return todoItems.count
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! ToDoTableViewCell
        

        let todoItem = todoItems[indexPath.row]
        
        cell.todoLabel.text = todoItem.title
        
        if todoItem.completed {
            cell.todoLabel.attributedText = strikeThroughText(todoItem.title)
        }

        return cell
    }
    
    override func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        let shareAction = UITableViewRowAction(style: .normal, title: "Del") { (action:UITableViewRowAction, indexPath:IndexPath) in
            let todoItem = self.todoItems[indexPath.row]
            self.sendTodo(todoItem)
        }
        shareAction.backgroundColor = UIColor(named: "Blue")
        
        let deleteAction = UITableViewRowAction(style: .normal
        , title: "Slet") { (action:UITableViewRowAction, indexPath:IndexPath) in
            
            print("Pre delete: \(self.todoItems)")
            DataManager.delete(self.todoItems[indexPath.row].itemIdentifier.uuidString)
            self.todoItems[indexPath.row].deleteItem()
            self.todoItems.remove(at: indexPath.row)
            self.tableView.deleteRows(at: [indexPath], with: .automatic)
            print("Post delete: \(self.todoItems)")
            
        }
        deleteAction.backgroundColor = UIColor(named: "Red")
        
        return [deleteAction, shareAction]
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        completeTodo(indexPath)
    }

    // MARK: - MC Delegate functions
    
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        
        switch state {
        case .connected:
            
            DispatchQueue.main.async {
                self.connectionButtonReference.setTitle("Forbundet", for: .normal)
            }
            
        case .connecting:
            
            DispatchQueue.main.async {
            self.connectionButtonReference.setTitle("Forbinder", for: .normal)
            }
        case .notConnected:
            DispatchQueue.main.async {
                self.connectionButtonReference.setTitle("Afbrudt", for: .normal)
            }
        }
        
    }
    
    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        
        do {
            let todoItem = try JSONDecoder().decode(TodoItem.self, from: data)
            DataManager.save(todoItem, with: todoItem.itemIdentifier.uuidString)
            DispatchQueue.main.async {
                self.loadData()
            }
        } catch {
            fatalError("Kunne ikke behandle data")
        }
    }
    
    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {
        
    }
    
    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {
        
    }
    
    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {
        
    }
    
    func browserViewControllerDidFinish(_ browserViewController: MCBrowserViewController) {
        dismiss(animated: true, completion: nil)
    }
    
    func browserViewControllerWasCancelled(_ browserViewController: MCBrowserViewController) {
        dismiss(animated: true, completion: nil)
    }

}
