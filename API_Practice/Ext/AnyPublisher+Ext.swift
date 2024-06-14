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
    
    // retryCount 보다 한번 더 실행됨 (Ex: count를 1번으로 지정했으나 error 발생 시 2번 retry)
    func retryWithDelayAndConditionAnyPublisher(retryCount: Int = 1,
                                          delay: Int = 1,
                                          when: ((Error) -> Bool)? = nil)
    -> Publishers.TryCatch<Self, AnyPublisher<Self.Output, Self.Failure>> {
        
        return self.tryCatch({ err -> AnyPublisher<Self.Output, Self.Failure> in
                
            guard (when?(err) ?? false) else {
                throw err
            }
            
            return Just(Void())
                .delay(for: .seconds(delay), scheduler: DispatchQueue.main)
                .flatMap { _ in
                    return self
                }
                .retry(retryCount)
                .eraseToAnyPublisher()
        })
    }
}
