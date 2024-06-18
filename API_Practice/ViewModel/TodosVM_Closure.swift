//
//  TodosVM+Closure.swift
//  API_Practice
//
//  Created by CatSlave on 6/4/24.
//

import Foundation
import RxSwift
import Combine

class TodosVM_Closure: ObservableObject {
    
    var todos: [Todo] = [] {
        didSet {
            print(#fileID, #function, #line, "-TodosChanged ")
            self.notifyTodosChanged?(todos)
        }
    }
    
    var currentPage: Int = 1 {
        didSet {
            print(#fileID, #function, #line, "-\(currentPage) ")
            self.notifyCurrentPage?(currentPage)
        }
    }
    
    var isLoading: Bool = false {
        didSet {
            print(#fileID, #function, #line, "-isLoading: \(isLoading) ")
            self.notifyIsLoading?(isLoading)
        }
    }
    
    var notifyTodosChanged: (([Todo]) -> Void)? = nil
    var notifyCurrentPage : ((Int) -> Void)? = nil
    var notifyIsLoading : ((Bool) -> Void)? = nil
    
    let disposeBag = DisposeBag()
    var subscriptions = Set<AnyCancellable>()

    init() {
        self.fetchTodos()
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
extension TodosVM_Closure {
    
    func fetchTodos(page: Int = 1) {
        
        if isLoading {
            return
        } else {
            isLoading = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            TodosAPI_Closure.fetchTodosClosure(page: page) { [weak self] result in
                guard let self = self else { return }
                switch result {
                case .success(let listResponse):
                    
                    
                    guard let todos = listResponse.data else {
                        return
                    }
                    
                    if page == 1 {
                        self.todos = todos
                    } else {
                        self.todos.append(contentsOf: todos)
                    }
                    
                    self.currentPage = page
                    
                case .failure(let failure):
                    self.handleError(failure)
                }
                
                self.isLoading = false
            }
        }
    }
    
    func fetchMore() {
        self.fetchTodos(page: currentPage + 1)
    }
    
    private func searchTodos() {
        TodosAPI_Closure.searchTodosClosure(searchTerm: "빡코딩") { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let todoList):
                print("테스트 success : \(todoList)")

            case .failure(let failure):
                self.handleError(failure)
            }
        }
    }
    
    private func addTodoMultipart() {
        TodosAPI_Closure.addTodoClosureByMultipart(content: "테스트합니다 1",
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
        TodosAPI_Closure.addTodoClosureByJson(content: "Json 테스트합니다.",
                                      isDone: true) { result in
            switch result {
            case .success(let todoList):
                print("테스트 success : \(todoList)")

            case .failure(let failure):
                self.handleError(failure)
            }
        }
    }
    
    private func searchTodo() {
        TodosAPI_Closure.searchTodoClosure(id: 5168) { result in
            switch result {
            case .success(let todoList):
                print("테스트 success : \(todoList)")

            case .failure(let failure):
                self.handleError(failure)
            }
        }
    }
    
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
        TodosAPI_Closure.deleteTodoClosure(id: 5167) { result in
            switch result {
            case .success(let todo):
                print("테스트 삭제된 toto : \(todo)")

            case .failure(let err):
                self.handleError(err)
            }
        }
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
    
    private func deleteTodos() {
        TodosAPI_Closure.deleteTodosClosure(id: [5164, 5165, 5166]) { result in
            switch result {
            case .success(let success):
                print("테스트 deleteTodo : \(success)")
            case .failure(let failure):
                self.handleError(failure)
            }
        }
    }
    
    private func addTodoAndFetchListClosureToAsync() {
        Task {
            do {
                let result = try await TodosAPI_Closure.addTodoAndFetchListClosureToAsync(content: "클로저 -> async 변환")
                print("테스트 result : \(result)")
            } catch {
                self.handleError(error)
            }
        }
    }
    
    private func deleteTodoAndFetchListClosureToAsync() {
        Task {
            do {
                let result = try await TodosAPI_Closure.deleteTodosClosureToAsync(id: [5322, 5320])
                print("테스트 result : \(result)")
            } catch {
                self.handleError(error)
            }
        }
    }
    
    private func addTodoAndFetchListClosureToRx() {
        TodosAPI_Closure.addTodosClosureToRxWithError(content: "Closure To Rx")
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { result in
                print("테스트 result : \(result)")
            }, onError: { [weak self] err in
                guard let self = self else { return }
                self.handleError(err)
            })
            .disposed(by: disposeBag)
    }
    
    private func addTodoAndFetchListClosureToCombine() {
        TodosAPI_Closure.fetchTodosClosureToCombineWithError()
            .sink { [weak self] completion in
                switch completion {
                case .failure(let err):
                    self?.handleError(err)
                case .finished:
                    print("테스트 finished")
                }
            } receiveValue: { data in
                print("테스트 data : \(data)")
            }
            .store(in: &subscriptions)
    }
    
}
