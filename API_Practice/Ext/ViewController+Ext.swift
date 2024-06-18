//
//  ViewController+Ext.swift
//  API_Practice
//
//  Created by CatSlave on 6/18/24.
//

import Foundation
import UIKit
import SwiftUI

extension MainVC {
    
    private struct VCRepresentable: UIViewControllerRepresentable {
        
        let mainVC: MainVC
        
        func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) {
        }
        
        func makeUIViewController(context: Context) -> some UIViewController {
            return mainVC
        }
    }
    
    func getRepresentable() -> some View {
        VCRepresentable(mainVC: self)
    }
}
