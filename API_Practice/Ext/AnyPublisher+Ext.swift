//
//  AnyPublisher+Ext.swift
//  API_Practice
//
//  Created by CatSlave on 6/12/24.
//

import Foundation
import Combine

extension AnyPublisher {
    
    func toAsync() async throws -> Output {
        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Output, Error>) in
            
            // cancellabel 생성
            var cancellable : AnyCancellable? = nil
            
            // 구독할 것 담기
            cancellable = first()
                .sink(receiveCompletion: { completion in
                    switch completion {
                    case .finished:
                        break
                    case .failure(let failure):
                        continuation.resume(throwing: failure)
                    }
                    // 작업완료 후 해제하기(필수)
                    cancellable?.cancel()
                }, receiveValue: { listData in
                    continuation.resume(returning: listData)
                })
            
            
        }
    }
}
