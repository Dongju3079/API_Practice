//
//  TodoCell.swift
//  API_Practice
//
//  Created by CatSlave on 5/30/24.
//

import UIKit

class RxTodoCell: UITableViewCell {
    
    var todo: Todo? = nil
    
    var tappedEditBtn : ((Todo, String) -> Void)? = nil
    var tappedDeleteBtn : ((Int) -> Void)? = nil
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
        guard let todo = todo,
              let existingContent = todo.title else { return }
        self.tappedEditBtn?(todo, existingContent)
    }
    
 
    @IBAction func onDeleteBtnClicked(_ sender: UIButton) {
        guard let id = todo?.id else { return }
        self.tappedDeleteBtn?(id)
    }
    
    func setTodo(_ todo: Todo) {  //
        guard let id = todo.id,
              let content = todo.title,
              let isDone = todo.isDone else { return }
        
        self.todo = todo
        
        titleLabel.text = "\(id)"
        contentLabel.text = content
        selectionSwitch.isOn = isDone
    
    }
    
    
    
}
