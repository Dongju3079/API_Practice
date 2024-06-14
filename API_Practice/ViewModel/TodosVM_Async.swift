//
//  TodosVM_Async.swift
//  API_Practice
//
//  Created by CatSlave on 6/10/24.
//

import Foundation
import Combine
import CombineExt
import RxSwift

class TodosVM_Async: ObservableObject {
    
    var subscriptions = Set<AnyCancellable>()
    var disposeBag = DisposeBag()
    
    init() {
        fetchTodosRetryExtResult()
    }
    
    private func handleError(_ err: Error) {
        
        
        if let apiError = err as? TodosAPI_Async.ApiError {
            print(apiError.info)
            return
        }
        print(err)
    }
}

// MARK: - fetch Data
extension TodosVM_Async {
    
    private func fetchTodos() {
        Task {
            do {
                let todosResponse = try await TodosAPI_Async.fetchTodos()
                print(#fileID, #function, #line, "-todos: \(todosResponse) ")
            } catch {
                self.handleError(error)
            }
            
        }
    }
    
    private func fetchTodosRetryExtValue() {
        let retryAsync = Task.retry(retryCount: 3, delay: 3) { err in
            if case TodosAPI_Async.ApiError.noContent = err {
                return true
            } else {
                return false
            }
        } asyncWork: {
            try await TodosAPI_Async.fetchTodos(page: 1)
        }
        
        // value 방식
        Task {
            do {
                let fetchResult = try await retryAsync.value
                print("테스트 listResponse : \(fetchResult)")
            } catch {
                self.handleError(error)
            }
        }
    }
    
    private func fetchTodosRetryExtResult() {
        let retryAsync = Task.retry(retryCount: 3, delay: 3) { err in
            if case TodosAPI_Async.ApiError.noContent = err {
                return true
            } else {
                return false
            }
        } asyncWork: {
            try await TodosAPI_Async.fetchTodos(page: 999)
        }
        
        // value 방식
        Task {
            switch await retryAsync.result {
            case .success(let data):
                print("테스트 data : \(data)")
            case .failure(let err):
                self.handleError(err)
            }
        }
    }
    
    private func fetchTodosResultType() {
        Task {
            let todosResponse = await TodosAPI_Async.fetchTodosResultType()
            switch todosResponse {
            case .success(let listResponse):
                print(#fileID, #function, #line, "-todos: \(listResponse) ")
            case .failure(let err):
                self.handleError(err)
            }
        }
    }
    
    private func addTodoAndFetch() {
        Task {
            do {
                let todoList = try await TodosAPI_Async.addTodoAndFetchTodos(content: "async add and fetch")
                print("테스트 todoList : \(todoList)")
            } catch {
                self.handleError(error)
            }
        }
    }
    
    private func deleteTodos() {
        Task {
            do {
                let result = try await TodosAPI_Async.deleteTodosWithError(selectedTodosId: [])
                print("테스트 result : \(result)")
            } catch {
                self.handleError(error)
            }
        }
    }
    
    private func deleteTodosWithGroup() {
        Task {
            do {
                let result = try await TodosAPI_Async.deleteTodosWithThrowingTaskGroup(selectedTodosId: [2712, 2752, 2753])
                print("테스트 result : \(result)")
            } catch {
                self.handleError(error)
            }
        }
    }
    
    private func deleteTodosWithGroupNoError() {
        Task {
            
            let result = await TodosAPI_Async.deleteTodosWithTaskGroup(selectedTodosId: [2754, 2755, 2757, 2762])
            print("테스트 result : \(result)")
        }
    }
 
    private func addTodoJson() {
        Task {
            do {
                let todosResponse = try await TodosAPI_Async.addTodoByJson(content: "글자만 가능", isDone: true)
                print(#fileID, #function, #line, "-todos: \(todosResponse) ")
            } catch {
                self.handleError(error)
            }
            
        }
    }
    private func editTodoEncoded() {
        Task {
            do {
                let todosResponse = try await TodosAPI_Async.editTodoEncoded(id: 5309, content: "change 5309", isDone: false)
                print(#fileID, #function, #line, "-todos: \(todosResponse) ")
            } catch {
                self.handleError(error)
            }
            
        }
    }
    
    private func deleteTodo() {
        Task {
            do {
                let todosResponse = try await TodosAPI_Async.deleteTodo(id: 5310)
                print(#fileID, #function, #line, "-todos: \(todosResponse) ")
            } catch {
                self.handleError(error)
            }
        }
    }
}


extension TodosVM_Async {
    private func handleCompletion(_ completion: Subscribers.Completion<TodosAPI_Combine.ApiError>) {
        switch completion {
        case .failure(let err):
            self.handleError(err)
        case .finished:
            print(#fileID, #function, #line, "-데이터 업로드 성공 ")
        }
    }
}

// MARK: - Async To Combine
extension TodosVM_Async {
    private func fetchTodoAsyncToCombineNoParameter() {
        TodosAPI_Async.genericFetchTodosAsyncToCombine(asyncTask: {
            try await TodosAPI_Async.fetchTodos()
        })
        .sink { [weak self] completion in
            guard let self = self else { return }
            switch completion {
            case .failure(let err):
                self.handleError(err)
            case .finished:
                print("테스트 finished")
            }
        } receiveValue: { listResponse in
            print("테스트 list : \(listResponse)")
        }
        .store(in: &subscriptions)
    }
    
    
    private func fetchTodoAsyncToCombine(page: Int) {
        Just(page)
            .mapAsync(asyncTask: TodosAPI_Async.fetchTodos(page:))
        .sink { [weak self] completion in
            guard let self = self else { return }
            switch completion {
            case .failure(let err):
                self.handleError(err)
            case .finished:
                print("테스트 finished")
            }
        } receiveValue: { listResponse in
            print("테스트 list : \(listResponse)")
        }
        .store(in: &subscriptions)
    }
}


// MARK: - Async To Rx {
extension TodosVM_Async {
    private func fetchTodosAsyncToRx() {
        Observable.just(1)
            .mapAsync { value in
                try await TodosAPI_Async.fetchTodos(page: value)
            }
            .subscribe(
                onNext: { data in
                    print("테스트 listResponse : \(data)")
                },
                onError: { [weak self] err in
                    self?.handleError(err)
                }
            )
            .disposed(by: disposeBag)
    }
}

