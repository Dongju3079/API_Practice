//
//  TodosVM_Combine.swift
//  API_Practice
//
//  Created by CatSlave on 6/6/24.
//

import Foundation
import Combine
import CombineExt
import RxSwift

class TodosVM_Combine: ObservableObject {
    
    let disposeBag = DisposeBag()
    var subscriptions = Set<AnyCancellable>()
    
    init() {
        fetchTodosRetryExt()
    }
    
    private func handleError(_ err: Error) {
        
        guard let apiError = err as? TodosAPI_Closure.ApiError else {
            print("알 수 없는 에러입니다.")
            return
        }
        
        print(apiError.info)
    }
    
}

// MARK: - fetch Data
extension TodosVM_Combine {
    
    private func fetchTodos() {
        TodosAPI_Combine.fetchTodos(page: 555)
            .tryCatch({ err in
                
                if case TodosAPI_Combine.ApiError.noContent = err {
                    throw err
                }
                
                return Just(Void(()))
                    .delay(for: 3, scheduler: DispatchQueue.main)
                    .flatMap { _ in
                        return TodosAPI_Combine.fetchTodos(page: 555)
                    }
                    .retry(3)
            })
            .sink { [weak self] completion in
                guard let self = self else { return }
                switch completion {
                case .failure(let err):
                    print("combine retry-error")
                    self.handleError(err)
                case .finished:
                    print(#fileID, #function, #line, "-Test : finished ")
                }
            } receiveValue: { todoListResponse in
                print(#fileID, #function, #line, "-todoList: \(todoListResponse) ")
            }.store(in: &subscriptions)
    }
    
    private func fetchTodosRetryExt() {
        TodosAPI_Combine.fetchTodos(page: 555)
            .retryWithDelayAndConditionAnyPublisher(retryCount: 0, delay: 3) { err in
                if case TodosAPI_Combine.ApiError.noContent = err {
                    return true
                } else {
                    return false
                }
            }
            .sink { [weak self] completion in
                guard let self = self else { return }
                switch completion {
                case .failure(let err):
                    print("combine retry-error")
                    self.handleError(err)
                case .finished:
                    print(#fileID, #function, #line, "-Test : finished ")
                }
            } receiveValue: { todoListResponse in
                print(#fileID, #function, #line, "-todoList: \(todoListResponse) ")
            }.store(in: &subscriptions)
    }
    
    private func fetchTodosByResultType() {
        TodosAPI_Combine.fetchTodosResultType()
            .sink { [weak self ]result in
                guard let self = self else { return }
                switch result {
                case .success(let todosResponse):
                    print(#fileID, #function, #line, "-todosResponse: \(todosResponse) ")
                case .failure(let err):
                    self.handleError(err)
                }
            }.store(in: &subscriptions)
    }
        
    private func addTodoMultipart() {
        TodosAPI_Combine.addTodoByMultipart(content: "6.10 addTest", isDone: true)
            .sink { [weak self] completion in
                guard let self = self else { return }
                self.handleCompletion(completion)
            } receiveValue: { todoResponse in
                print(#fileID, #function, #line, "-todoResponse: \(todoResponse) ")
            }.store(in: &subscriptions)
    }
    
    private func addTodoJson() {
        TodosAPI_Combine.addTodoByJson(content: "Json addTest", isDone: true)
            .sink { [weak self] completion in
                guard let self = self else { return }
                self.handleCompletion(completion)
            } receiveValue: { todoResponse in
                print(#fileID, #function, #line, "-todoResponse: \(todoResponse) ")
            }.store(in: &subscriptions)
    }
    
    private func searchTodoById() {
        TodosAPI_Combine.searchTodo(id: 5291)
            .sink { [weak self] completion in
                guard let self = self else { return }
                self.handleCompletion(completion)
            } receiveValue: { todoResponse in
                print(#fileID, #function, #line, "-todoResponse: \(todoResponse) ")
            }.store(in: &subscriptions)
    }

    private func searchTodosByTerm() {
        TodosAPI_Combine.searchTodos(searchTerm: "빡코딩")
            .sink { [weak self] completion in
                guard let self = self else { return }
                self.handleCompletion(completion)
            } receiveValue: { todoResponse in
                print(#fileID, #function, #line, "-todoResponse: \(todoResponse) ")
            }.store(in: &subscriptions)
    }
    
    
    private func editTodoEncoded() {
        TodosAPI_Combine.editTodoEncoded(id: 5292, content: "Edit Encoded", isDone: false)
            .sink { [weak self] completion in
                guard let self = self else { return }
                self.handleCompletion(completion)
            } receiveValue: { todoResponse in
                print(#fileID, #function, #line, "-todoResponse: \(todoResponse) ")
            }.store(in: &subscriptions)
    }
    
    private func editTodoJson() {
        TodosAPI_Combine.editTodoByJson(id: 5292, content: "Edit Json", isDone: false)
            .sink { [weak self] completion in
                guard let self = self else { return }
                self.handleCompletion(completion)
            } receiveValue: { todoResponse in
                print(#fileID, #function, #line, "-todoResponse: \(todoResponse) ")
            }.store(in: &subscriptions)
    }
    
    private func searchTodos() {
        TodosAPI_Combine.deleteTodosMerge(selectedTodos: [5291, 4722, 4620, 9999])
            .sink { [weak self] completion in
                guard let self = self else { return }
                switch completion {
                case .failure(let err):
                    self.handleError(err)
                case .finished:
                    print(#fileID, #function, #line, "-succes data upload ")
                }
            } receiveValue: { todo in
                print(#fileID, #function, #line, "-todo : \(todo) ")
            }.store(in: &subscriptions)
    }
    
    private func searchTodosNoError() {
        TodosAPI_Combine.deleteTodosZipNoError(selectedTodos: [4610, 4609])
            .sink { todosId in
                print(#fileID, #function, #line, "-todosId: \(todosId) ")
            }.store(in: &subscriptions)
    }    
}

extension TodosVM_Combine {
    private func handleCompletion(_ completion: Subscribers.Completion<TodosAPI_Combine.ApiError>) {
        switch completion {
        case .failure(let err):
            self.handleError(err)
        case .finished:
            print(#fileID, #function, #line, "-데이터 업로드 성공 ")
        }
    }
}

// MARK: - Combine To Async
extension TodosVM_Combine {
    private func fetchTodosCombineToAsync() {
        Task {
            do {
                let listData = try await TodosAPI_Combine.fetchTodos().toAsync()
                print("테스트 listData : \(listData)")
            } catch {
                self.handleError(error)
            }
        }
    }
}

// MARK: - Combine To Rx
extension TodosVM_Combine {
    private func fetchTodosCombineToRx() {
        TodosAPI_Combine.fetchTodosResultType()
            .asObservable()
            .subscribe(
                onNext: { data in
                    print("테스트 data : \(data)")
                },
                onError: { [weak self] err in
                    guard let self = self else { return }
                    self.handleError(err)
                }
            )
            .disposed(by: disposeBag)
    }
}
