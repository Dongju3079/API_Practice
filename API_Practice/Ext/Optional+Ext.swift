//
//  Optional+Ext.swift
//  API_Practice
//
//  Created by CatSlave on 6/20/24.
//

import Foundation

extension Optional {
    init<T, U>(tuple: (T?, U?)) where Wrapped == (T, U) {
        
        switch tuple{
        case (let t?, let u?):
            self = (t, u)
        default:
            self = nil
        }
    }
}
