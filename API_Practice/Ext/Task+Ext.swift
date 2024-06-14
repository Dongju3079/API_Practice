//
//  Task+Ext.swift
//  API_Practice
//
//  Created by CatSlave on 6/15/24.
//

import Foundation

extension Task {
    
    enum TaskRetryError: Error {
        case maxRetryRequest
    }
    
    static func retry(retryCount: Int = 1,
                      delay: Int = 1,
                      when: ((Error) -> Bool)? = nil,
                      // Task의 <Success, Failure> 의 제네릭 타입을 명시해주는 것
                      // where Failure == Error : 타입을 지정(제한)함으로써 내부에서 do, catch 블록을 사용할 수 있게 되는 것
                      asyncWork: @Sendable @escaping () async throws -> Success) -> Task where Failure == Error {
        
        return Task {
            for _ in 0...retryCount {
                print("retry")
                do {
                    let todosResponse = try await asyncWork()
                    return todosResponse
                } catch {
                    
                    guard (when?(error) ?? false) else {
                        throw error
                    }
                    
                    try await Task<Never,Never>.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                    continue
                }
            }
            
            throw TaskRetryError.maxRetryRequest
        }
    }
}
