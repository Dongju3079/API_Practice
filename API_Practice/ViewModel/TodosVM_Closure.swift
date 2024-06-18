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
    
    // MARK: - Variables
    var todos: [Todo] = [] {
        didSet {
            print(#fileID, #function, #line, "-TodosChanged ")
            self.notifyTodosChanged?(todos)
        }
    }
    
    var currentPageMeta: Meta? = nil {
        didSet {
            self.notifyHasNext?(currentPageMeta?.hasNext() ?? true)
            self.notifyCurrentPage?(currentPage)
        }
    }
    
    var currentPage: Int {
        get {
            if let pageInfo = self.currentPageMeta,
               let currentPage = pageInfo.currentPage {
                return currentPage
            } else {
                return 1
            }
        }
    }
    
    var isLoading: Bool = false {
        didSet {
            print(#fileID, #function, #line, "-isLoading: \(isLoading) ")
            self.notifyIsLoading?(isLoading)
        }
    }
    
    var searchTerm: String = "" {
        didSet {
            if searchTerm.count > 1 {
                self.searchTodos(searchTerm: searchTerm)
            } else {
                self.fetchTodos(page: 1)
            }
        }
    }
    
    var notifyUploadCompleted : (() -> Void)? = nil
    var notifyTodosChanged: (([Todo]) -> Void)? = nil
    var notifyNoContent : ((Bool) -> Void)? = nil
    var notifyCurrentPage : ((Int) -> Void)? = nil
    var notifyIsLoading : ((Bool) -> Void)? = nil
    var notifyRefresh : (() -> Void)? = nil
    var notifyHasNext : ((Bool) -> Void)? = nil
    var notifyErrResponse : ((String) -> Void)? = nil
    
    let disposeBag = DisposeBag()
    var subscriptions = Set<AnyCancellable>()
    
    // MARK: - Initializer
    init() {
        self.fetchTodos()
    }
    
    private func handleError(_ err: Error) {
        
        guard let apiError = err as? TodosAPI_Closure.ApiError else {
            print("알 수 없는 에러입니다.")
            return
        }
        
        switch apiError {
        case .noContent:
            self.notifyNoContent?(true)
        case .errResponseFromServer(let errResponse):
            guard let message = errResponse?.message else { return }
            self.notifyErrResponse?(message)
        default :
            print(apiError.info)
        }
        
    }
    
}

// MARK: - fetch Data
extension TodosVM_Closure {
    
    func fetchRefresh() {
        guard !isLoading else { return }

        self.fetchTodos(page: 1)
    }
    
    func fetchMore() {
        
        guard let pageInfo = self.currentPageMeta,
              pageInfo.hasNext(),
              !isLoading else {
            return print("다음페이지에 대한 정보가 없습니다.")
        }
        
        if searchTerm.count > 0 {
            // 검색어가 있을 때
            self.searchTodos(searchTerm: searchTerm, page: currentPage + 1)
        } else {
            // 검색어가 없을 때
            self.fetchTodos(page: currentPage + 1)
        }
    }
    
    func fetchTodos(page: Int = 1) {
        
        self.notifyNoContent?(false)
        self.notifyHasNext?(true)
        isLoading = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            TodosAPI_Closure.fetchTodosClosure(page: page) { [weak self] result in
                
                guard let self = self else { return }
                
                self.isLoading = false
                
                switch result {
                case .success(let listResponse):
                    
                    guard let todos = listResponse.data,
                          let pageInfo = listResponse.meta else {
                        return
                    }
                    
                    if page == 1 {
                        self.todos = todos
                    } else {
                        self.todos.append(contentsOf: todos)
                    }
                    
                    self.currentPageMeta = pageInfo
                    
                case .failure(let failure):
                    self.handleError(failure)
                }
                
                
                notifyRefresh?()
            }
        }
    }
    
    
    
    func searchTodos(searchTerm: String = "빡코딩", page: Int = 1) {
        
        self.notifyNoContent?(false)
        self.notifyHasNext?(true)
        isLoading = true
        
        if page == 1 {
            self.todos = []
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            TodosAPI_Closure.searchTodosClosure(searchTerm: searchTerm,
                                                page: page) { [weak self] result in
                guard let self = self else { return }
                self.isLoading = false
                switch result {
                case .success(let listResponse):
                    guard let todos = listResponse.data,
                          let pageInfo = listResponse.meta else { return }
                    print("테스트 todos list : \(todos)")
                    
                    if page == 1 {
                        self.todos = todos
                    } else {
                        self.todos.append(contentsOf: todos)
                    }
                    
                    self.currentPageMeta = pageInfo
                    
                case .failure(let failure):
                    
                    self.handleError(failure)
                }
            }
        }
    }
    
    func addTodoFetchTodo(content: String) {
        print("테스트 addTodoFetchTodo : \(content)")
        TodosAPI_Closure.addTodoAndFetchTodos(title: content) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let listResponse):
                guard let todos = listResponse.data,
                      let pageInfo = listResponse.meta else { return }
                
                self.todos = todos
                
                self.currentPageMeta = pageInfo
                self.notifyUploadCompleted?()
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
    
    private func addTodoJson(content: String) {
        TodosAPI_Closure.addTodoClosureByJson(content: content,
                                      isDone: false) { result in
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
    
    func editTodoEncoded(editTodo: Todo, content: String) {
        let index = self.todos.firstIndex { todo in
            return todo.id == editTodo.id
        }
        
        guard let todoId = editTodo.id,
              let isDone = editTodo.isDone,
              let index = index else { return }
        
        TodosAPI_Closure.editTodoClosureEncoded(id: todoId,
                                 content: content,
                                 isDone: isDone) { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let todoResponse):
                guard let todo = todoResponse.data else { return }
                self.todos[index] = todo
                
            case .failure(let err):
                self.handleError(err)

            }
        }
    }
    
    func editTodoCompleted(editTodo: Todo, isDone: Bool) {
        let index = self.todos.firstIndex { todo in
            return todo.id == editTodo.id
        }
        
        guard let todoId = editTodo.id,
              let content = editTodo.title,
              let index = index else { return }
        
        TodosAPI_Closure.editTodoClosureEncoded(id: todoId,
                                 content: content,
                                 isDone: isDone) { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let todoResponse):
                guard let todo = todoResponse.data else { return }
                self.todos[index] = todo
                
            case .failure(let err):
                self.handleError(err)

            }
        }
    }
    
    func deleteTodoEncoded(editTodo: Todo) {
        let index = self.todos.firstIndex { todo in
            return todo.id == editTodo.id
        }
        
        guard let todoId = editTodo.id,
              let index = index else { return }
        
        TodosAPI_Closure.deleteTodoClosure(id: todoId) { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(_):
                self.todos.remove(at: index)
                
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
