//
//  Nibbed.swift
//  API_Practice
//
//  Created by CatSlave on 5/30/24.
//

import UIKit

protocol Nibbed {
    static var uinib: UINib { get }
}

extension Nibbed {
    static var uinib: UINib {
        UINib(nibName: String(describing: self), bundle: Bundle.main)
    }
}

extension UITableViewCell : Nibbed { }
