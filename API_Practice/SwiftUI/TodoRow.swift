//
//  TodoRow.swift
//  API_Practice
//
//  Created by CatSlave on 5/31/24.
//

import Foundation
import SwiftUI

struct TodoRow: View {
    
    @State var isSelected: Bool = false
    
    var body: some View {
        HStack(alignment: .top) {
            
            VStack(alignment: .leading) {
                Text("id: 123 / 완료여부: 미완료")
                Text("오늘도 짱아는 귀여워")
            }
            .frame(maxWidth: .infinity)
            
            VStack(alignment: .trailing) {
                actionBtns
                Toggle(isOn: $isSelected, label: {
                    EmptyView()
                })
                .background(Color.gray)
                .frame(width: 80)
            }
        }
        .frame(maxWidth: .infinity )
    }
    
    private var actionBtns: some View {
        VStack {
            HStack {
                Button(action: { }, label: { Text("수정") })
                    .buttonStyle(MyDefaultBtnStyle())
                    .frame(width: 80)
                Button(action: { }, label: { Text("삭제") })
                    .buttonStyle(MyDefaultBtnStyle(bgColor: .purple))
                    .frame(width: 80)
            }
        }
    }
}

struct TodoRow_Previews: PreviewProvider {
    static var previews: some View {
        TodoRow()
    }
}
