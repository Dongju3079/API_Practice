//
//  TodoCell.swift
//  API_Practice
//
//  Created by CatSlave on 5/30/24.
//

import UIKit

class RxTodoCell: UITableViewCell {
    
    var todo: Todo? = nil
    
    var tappedEditBtn : ((Todo) -> Void)? = nil
    var tappedDeleteBtn : ((Todo) -> Void)? = nil
    var tappedSwitch : ((Int, Bool) -> Void)? = nil
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var contentLabel: UILabel!
    @IBOutlet weak var selectionSwitch: UISwitch!
    
    
    override class func awakeFromNib() {
        super.awakeFromNib()
    }
    
    @IBAction func onSwitchClicked(_ sender: UISwitch) {
        guard let id = todo?.id else { return }
        self.tappedSwitch?(id, selectionSwitch.isOn)
    }
    
    @IBAction func onEditBtnClicked(_ sender: UIButton) {
        guard let todo = todo else { return }
                
        self.tappedEditBtn?(todo)
    }
    
 
    @IBAction func onDeleteBtnClicked(_ sender: UIButton) {
        guard let todo = todo else { return }
                
        self.tappedDeleteBtn?(todo)
    }
    
    func setTodo(todo: Todo) {  // , isCompleted: Set<Int>
        guard let id = todo.id,
              let content = todo.title else { return }
        
        self.todo = todo
        
        titleLabel.text = "\(id)"
        contentLabel.text = content
//        selectionSwitch.isOn = isCompleted.contains(where: { $0 == id })
    }
    
    
    
}
