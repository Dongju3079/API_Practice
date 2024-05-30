//
//  TodoCell.swift
//  API_Practice
//
//  Created by CatSlave on 5/30/24.
//

import UIKit

class TodoCell: UITableViewCell {
    
    
    
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
    
    
    
}
