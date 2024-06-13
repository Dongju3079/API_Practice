//
//  Publisher+Ext.swift
//  API_Practice
//
//  Created by CatSlave on 6/13/24.
//

import Foundation
import Combine

extension Publisher {
    
    func mapAsync<T>(asyncTask: @escaping (Output) async throws -> T) -> Publishers.FlatMap<Future<T, Error>, Publishers.SetFailureType<Self, Error>> {
        
        return self.setFailureType(to: Error.self)
        
            .flatMap { output in

            return Future { (promise: @escaping (Result<T, Error>) -> Void) in
                Task {
                    do {
                        let listResponse = try await asyncTask(output)
                        promise(.success(listResponse))
                    } catch {
                        promise(.failure(error))
                    }
                }
            }
        }
    }
}
