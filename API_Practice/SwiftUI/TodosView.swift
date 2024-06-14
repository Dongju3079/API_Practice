//
//  TodosView.swift
//  API_Practice
//
//  Created by CatSlave on 5/30/24.
//

import Foundation
import SwiftUI

struct TodosView: View {
    
    @State var todoResponse = TodosVM_Rx()
    
    var body: some View {
        
        VStack(alignment: .leading) {
            
            getHeader()
            UISearchBarWrapper()
            Spacer()
            
            List {
                TodoRow()
                TodoRow()
                TodoRow()
                TodoRow()
                TodoRow()
                TodoRow()
            }.listStyle(.plain)
        }
         
    }
    
    private func getHeader() -> some View {
        Group {
            topView
            middleView
        }.padding(.horizontal, 10)
    }
    
    private var topView: some View {
        Group {
            Text("TodosView / page: 0")
            Text("선택된 할 일 : [ ]")
            
            HStack {
                Button(action: { }, label: { Text("클로저") })
                    .buttonStyle(MyDefaultBtnStyle())
                
                Button(action: { }, label: { Text("Rx") })
                    .buttonStyle(MyDefaultBtnStyle())
                
                Button(action: { },
                       label: { Text("Combine") })
                    .buttonStyle(MyDefaultBtnStyle())
                
                Button(action: { }, label: { Text("Async") })
                    .buttonStyle(MyDefaultBtnStyle())
            }
        }
    }
    private var middleView: some View {
        Group {
            Text("Async 변환 액션")
            
            HStack {
                Button(action: { }, label: { Text("클로저 -> Async") })
                    .buttonStyle(MyDefaultBtnStyle())
                Button(action: { }, label: { Text("Rx -> Async") })
                    .buttonStyle(MyDefaultBtnStyle())
                Button(action: { }, label: { Text("Combine -> Async") })
                    .buttonStyle(MyDefaultBtnStyle())
                Button(action: { }, label: { Text("Async -> Async") })
                    .buttonStyle(MyDefaultBtnStyle())
            }
            
            HStack {
                Button(action: { }, label: { Text("초기화") })
                    .buttonStyle(MyDefaultBtnStyle(bgColor: .purple))
                Button(action: { }, label: { Text("선택된 할 일 삭제") })
                    .buttonStyle(MyDefaultBtnStyle(bgColor: .black))
                Button(action: { }, label: { Text("할 일 추가") })
                    .buttonStyle(MyDefaultBtnStyle(bgColor: .gray))
            }
        }
    }
}

struct TodosView_Previews: PreviewProvider {
    static var previews: some View {
        TodosView()
    }
}
