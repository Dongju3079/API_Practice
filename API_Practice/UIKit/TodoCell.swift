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
    
    var tappedEditBtn : ((Todo) -> Void)? = nil
    var tappedDeleteBtn : ((Todo) -> Void)? = nil
    var tappedSwitch : ((Todo, Bool) -> Void)? = nil
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var contentLabel: UILabel!
    @IBOutlet weak var selectionSwitch: UISwitch!
    
    
    override class func awakeFromNib() {
        super.awakeFromNib()
    }
    
    @IBAction func onSwitchClicked(_ sender: UISwitch) {
        guard let todo = todo else { return }
        self.tappedSwitch?(todo, selectionSwitch.isOn)
    }
    
    @IBAction func onEditBtnClicked(_ sender: UIButton) {
        guard let todo = todo else { return }
        self.tappedEditBtn?(todo)
    }
    
 
    @IBAction func onDeleteBtnClicked(_ sender: UIButton) {
        guard let todo = todo else { return }
        self.tappedDeleteBtn?(todo)
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
