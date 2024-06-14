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
    
    func mapAsync<T>(asyncTask: @escaping (Element) async throws -> T) -> Observable<T> {
        return flatMap { value in
            return Observable.create { (emitter: AnyObserver<T>) in
                Task {
                    do {
                        let listResponse = try await asyncTask(value)
                        emitter.onNext(listResponse)
                        emitter.onCompleted()
                    } catch {
                        emitter.onError(error)
                    }
                }
                return Disposables.create()
            }
        }
    }
    
    
    
    func retryWithDelayAndCondition(retryCount: Int = 1,
                                    delay: Int =  1,
                                    when : ((Error) -> Bool)? = nil
    ) -> Observable<Element> {
        
        var requestCount: Int = 0
        
        return self.retry { (observableErr: Observable<TodosAPI_Rx.ApiError>) in
            
            observableErr
                .do(onNext: { err in
                    print("observableErr : \(err)")
                })
                .flatMap { err in
                    
                    // escaping closure 를 optional로 지정
                    // 기존 optional binding 처리와 같이 처리할 수 있음
                    if !(when?(err) ?? true) {
                        throw err
                    }

                    requestCount += 1
                    
                    return Observable<Void>.just(()).delay(.seconds(delay), scheduler: MainScheduler.instance)
                }
                .take(retryCount) // : 횟수 제한
        }
    }
    
    
    func retryWithDelayAndConditionCatch(retryCount: Int = 1,
                                    delay: Int =  1,
                                    when : ((Error) -> Bool)? = nil
    ) -> Observable<Element> {
        
        var requestCount: Int = 0
        
        // retry : API 통신이 성공적으로 되거나 에러를 던질 때 retry를 벗어남
        // 횟수, 딜레이, 조건을 설정할 수 있음
        
        return self.catch { err -> Observable<Element> in
            
            // err에 걸어준 조건이 맞지 않다면 throw err
            if !(when?(err) ?? true) {
                throw err
            }
            
            // err가 들어온다면 Observable을 리턴 (단순 딜레이를 가지고 신호보내는 Observable)
            // flatMap을 통해서 다른 Observable로 전환 (여기서 다른 Observable은 self)
            // retry를 통해서 다시 시도, 지정된 횟수만큼 try
            return Observable<Void>
                .just(())
                .delay(.seconds(delay), scheduler: MainScheduler.instance)
                .flatMap { _ in
                    requestCount += 1
                    return self
                }
                .retry(retryCount)
        }
    }
}


