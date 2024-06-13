//
//  ObservableType+Ext.swift
//  API_Practice
//
//  Created by CatSlave on 6/13/24.
//

import Foundation
import RxSwift
 
extension ObservableType {
    
    func toAsync() async throws -> Element {
        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Element, Error>) in
            
            var disposable : Disposable? = nil
            
            disposable = single()
                .debug()
                .subscribe(
                    onNext: { data in
                        continuation.resume(returning: data)
                    },
                    onError: { err in
                        continuation.resume(throwing: err)
                    },
                    onCompleted: {
                        disposable?.dispose()
                    },
                    onDisposed: {
                    }
                )
        }
    }
}
