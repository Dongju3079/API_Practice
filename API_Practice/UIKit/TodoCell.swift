//
//  TodoCell.swift
//  API_Practice
//
//  Created by CatSlave on 5/30/24.
//

import UIKit

class TodoCell: UITableViewCell {
    
    var todo: Todo? {
        didSet {
            guard let todo = todo else { return }
            self.setTodo(data: todo)
        }
    }
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var contentLabel: UILabel!
    @IBOutlet weak var selectionSwitch: UISwitch!
    
    
    override class func awakeFromNib() {
        super.awakeFromNib()
    }
    
    
    @IBAction func onEditBtnClicked(_ sender: UIButton) {
    }
    
 
    @IBAction func onDeleteBtnClicked(_ sender: UIButton) {
    }
    
    private func setTodo(data: Todo) {
        guard let title = data.id,
              let content = data.title,
              let completed = data.isDone else { return }
        
        titleLabel.text = "\(title)"
        contentLabel.text = content
        selectionSwitch.isOn = completed
    }
    
    
    
}
