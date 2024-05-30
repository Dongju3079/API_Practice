//
//  TodosView.swift
//  API_Practice
//
//  Created by CatSlave on 5/30/24.
//

import Foundation
import SwiftUI

struct TodosView: View {
    
    var body: some View {
        
        VStack {
            Circle()
                .background(Color.yellow)
                .padding(20)
                .background(Color.blue)
            Text("Todos View")
        }
         
    }
}

struct TodosView_Previews: PreviewProvider {
    static var previews: some View {
        TodosView()
    }
}
