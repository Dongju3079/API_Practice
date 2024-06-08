//
//  Button+Style.swift
//  API_Practice
//
//  Created by CatSlave on 5/30/24.
//

import Foundation
import SwiftUI

struct MyDefaultBtnStyle: ButtonStyle {
    
    let bgColor: Color
    let textColor: Color
    
    init(bgColor: Color = .blue,
         textColor: Color = .white) {
        
        self.bgColor = bgColor
        self.textColor = textColor
    }
    
  func makeBody(configuration: Configuration) -> some View {
    HStack {
      Spacer()
      configuration.label
            .lineLimit(2)
            .minimumScaleFactor(0.7)
            .foregroundColor(textColor)
      Spacer()
    }
    .padding()
    .background(bgColor.cornerRadius(8))
    .scaleEffect(configuration.isPressed ? 0.95 : 1)
  }
}
