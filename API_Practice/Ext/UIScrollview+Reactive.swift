//
//  UIScrollview+Reactive.swift
//  API_Practice
//
//  Created by CatSlave on 6/21/24.
//

import Foundation
import UIKit
import RxSwift
import RxCocoa

extension Reactive where Base: UIScrollView {
    
    var isBottomNeared: Observable<Void> {
        return contentOffset
            .map { cgPoint in
                let viewHeight = self.base.frame.size.height
                let contentHeight = self.base.contentSize.height
                let offsetY = cgPoint.y
                let threshold : CGFloat = contentHeight - (offsetY + 200)
                
                return threshold < viewHeight
            }
            .filter { $0 == true }.map { _ in }
    }
}
