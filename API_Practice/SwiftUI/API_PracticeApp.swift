//
//  API_PracticeApp.swift
//  API_Practice
//
//  Created by CatSlave on 5/29/24.
//

import SwiftUI

@main
struct API_PracticeApp: App {
    
    @State var selectedTab: Int = 1
    
    var body: some Scene {
        WindowGroup {
            TabView(selection: $selectedTab) {
                TodosView()
                    .tabItem {
                        Image(systemName: "1.square.fill")
                        Text("SwiftUI")
                    }
                    .tag(0)
                RxMainVC.instantiate()
                    .getRepresentable()
                    .tabItem {
                        Image(systemName: "2.square.fill")
                        Text("UIKit")
                    }
                    .tag(1)
            }
            
        }
    }
}
