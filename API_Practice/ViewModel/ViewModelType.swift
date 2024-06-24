//
//  ViewModelType.swift
//  API_Practice
//
//  Created by CatSlave on 6/24/24.
//

import Foundation

protocol ViewModelType {
    associatedtype Input
    associatedtype Output
    
    func transform(input: Input) -> Output
}
