//
//  API_PracticeApp.swift
//  API_Practice
//
//  Created by CatSlave on 5/29/24.
//

import SwiftUI

@main
struct API_PracticeApp: App {
    
    var body: some Scene {
        WindowGroup {
            TabView {
                ContentView()
                    .tabItem {
                        Image(systemName: "1.square.fill")
                        Text("SwiftUI")
                    }
                MainVC.instantiate()
                    .getRepresentable()
                    .tabItem {
                        Image(systemName: "2.square.fill")
                        Text("UIKit")
                    }
            }
            
        }
    }
}
