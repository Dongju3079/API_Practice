//
//  TodosVM+Closure.swift
//  API_Practice
//
//  Created by CatSlave on 6/4/24.
//

import Foundation
import Combine
import RxSwift
import RxCocoa
import RxRelay
import RxCombine

class TodosVM_Rx: ObservableObject {
    
    let disposeBag = DisposeBag()
    var subscriptions = Set<AnyCancellable>()
    
    init() {
        
        TodosAPI_Rx.fetchTodosRxAddErrorTask()
            .retry(when: { (observableErr: Observable<any Error>) in
                observableErr
                                .do(onNext: { err in
                                    print("observableErr : \(err)")
                                })
                                .flatMap { err in

                                    if case TodosAPI_Rx.ApiError.noContent = err {
                                        throw err
                                    }
                                    
                                    return Observable<Void>
                                        .just(())
                                        .delay(.seconds(3), scheduler: MainScheduler.instance)
                                }
                                .take(3) // : 횟수 제한
            })
            .subscribe(onNext: {
                print("onNext:\($0)")
            }, onError: {
                print("onError:\($0)")
            }, onCompleted: {
                print("onCompleted")
            }, onDisposed: {
                print("onDisposed")
            })
            .disposed(by: disposeBag)
        
//        
//        TodosAPI_Rx.fetchTodosRxAddErrorTask()
//            .retryWithDelayAndCondition(retryCount: 3, delay: 2, when: { err in
//                print("테스트 err : \(err)")
//                return true
//            })
//            .subscribe(onNext: {
//                print("onNext:\($0)")
//            }, onError: {
//                print("onError:\($0)")
//            }, onCompleted: {
//                print("onCompleted")
//            }, onDisposed: {
//                print("onDisposed")
//            })
//            .disposed(by: disposeBag)
    }
    
    private func handleError(_ err: Error) {
        
        guard let apiError = err as? TodosAPI_Rx.ApiError else {
            print("알 수 없는 에러입니다.")
            return
        }
        
        print(apiError.info)
    }
    
}

// MARK: - fetch Data
extension TodosVM_Rx {
    
    private func searchTodos() {
        TodosAPI_Rx.searchTodosRx(todosId: [2691, 2701, 2708, 2709])
            .debug()
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { todos in
                todos.forEach {
                    guard let id = $0.id else { return }
                    print("테스트 할 일 : \(id)")
                }
            })
            .disposed(by: disposeBag)
    }
    
    private func deleteTodosZip() {
        TodosAPI_Rx.deleteTodosRxZip(selectedTodos: [5149, 5169, 5163, 5162, 5160, 5159, 5158, 5156, 5154, 5153])
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { todos in
                print("테스트 할 일 목록 : \(todos)")
            })
            .disposed(by: disposeBag)
    }
    
    private func deleteTodosMerge() {
        TodosAPI_Rx.deleteTodosRxMerge(selectedTodos: [2664, 2682])
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { todos in
                print("테스트 할 일 목록 : \(todos)")
            })
            .disposed(by: disposeBag)
    }
    
    private func addTodoAndFetchTodos() {
        TodosAPI_Rx.addTodoAndFetchTodos(content: "add And Fetch", isDone: true)
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { todos in
                print("테스트 할 일 목록 : \(todos)")
            })
            .disposed(by: disposeBag)
    }
    
    private func fetchTodos() {
        TodosAPI_Rx.fetchTodosRx()
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] result in
                guard let self = self else { return }
                switch result {
                case .success(let todos):
                    print("테스트 할 일 : \(todos)")
                case .failure(let err):
                    self.handleError(err)
                }
            }).disposed(by: disposeBag)
    }
    
    private func fetchTodosAddErrorTask() {
        TodosAPI_Rx.fetchTodosRxAddErrorTask()
            .observe(on: MainScheduler.instance)
            .compactMap { $0.data }
            .catchAndReturn([])
            .subscribe(onNext: { todoList in
                print("테스트 todoList : \(todoList)")

            }).disposed(by: disposeBag)
    }
    
    private func addTodoMultipart() {
        TodosAPI_Rx.addTodoRxByMultipart(content: "Rx 추가완료", isDone: false)
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] result in
                guard let self = self else { return }
                switch result {
                case .success(let todos):
                    print("테스트 할 일 : \(todos)")
                case .failure(let err):
                    self.handleError(err)
                }
            }).disposed(by: disposeBag)
    }
    
    private func searchTodo() {
        TodosAPI_Closure.addTodoClosureByMultipart(content: "테스트합니다 1234",
                                           isDone: true) { result in
            switch result {
            case .success(let todoList):
                print("테스트 success : \(todoList)")

            case .failure(let failure):
                self.handleError(failure)
            }
        }
    }
    
    private func addTodoJson() {
            
        TodosAPI_Rx.addTodoRxByJson(content: "Json(Rx) 추가완료", isDone: false)
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] result in
                guard let self = self else { return }
                switch result {
                case .success(let todos):
                    print("테스트 할 일 : \(todos)")
                case .failure(let err):
                    self.handleError(err)
                }
            }).disposed(by: disposeBag)
    }
    
//    private func searchTodo() {
//        TodosAPI_Closure.searchTodoClosure(id: 5168) { result in
//            switch result {
//            case .success(let todoList):
//                print("테스트 success : \(todoList)")
//
//            case .failure(let failure):
//                self.handleError(failure)
//            }
//        }
//    }
    
    private func editTodoEncoded() {
        TodosAPI_Closure.editTodoClosureEncoded(id: 5168,
                                 content: "5168 Edit",
                                 isDone: true) { result in
            switch result {
            case .success(let todo):
                print("테스트 todo : \(todo)")
            case .failure(let err):
                self.handleError(err)

            }
        }
    }
    
    private func deleteTodo() {
        TodosAPI_Rx.deleteTodoRx(id: 4613)
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { todo in
                print(#fileID, #function, #line, "-delete todo : \(todo) ")
            }, onError: { [weak self] err in
                guard let self = self else { return }
                self.handleError(err)
            })
            .disposed(by: disposeBag)
    }
    
    private func editTodoJson() {
        TodosAPI_Closure.editTodoClosureByJson(id: 5166,
                                 content: "수정된 5166",
                                 isDone: true) { result in
            switch result {
            case .success(let todo):
                print("테스트 todo : \(todo)")
            case .failure(let err):
                self.handleError(err)

            }
        }
    }
}

// MARK: - Rx to Async
extension TodosVM_Rx {
    
    private func fetchTodoRxToAsync() {
        Task {
            do {
                let _ = try await TodosAPI_Rx.fetchTodosRxAddErrorTask().toAsync()
            } catch {
                self.handleError(error)
            }
        }
    }
}

// MARK: - Rx to Combine
extension TodosVM_Rx {
    private func fetchTodoRxToCombine() {
        TodosAPI_Rx.fetchTodosRxAddErrorTask()
            .publisher
            .sink {[weak self] completion in
                guard let self = self else { return }
                switch completion {
                case .finished:
                    print("테스트 finished")
                case .failure(let err):
                    self.handleError(err)
                }
            } receiveValue: { listResponse in
                print("테스트 listData : \(listResponse)")
            }
            .store(in: &subscriptions)
    }
}

