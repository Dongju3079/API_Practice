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
    
    var completedTodosId: Set<Int> = [] {
        didSet {
            print(#fileID, #function, #line, "-완료된 할 일이 추가되었습니다. ")
            self.notifyCompletedTodos?(Array(completedTodosId))
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
    
    var isLoading: Bool = false
    
    var moreDataIsLoading: Bool = false {
        didSet {
            print(#fileID, #function, #line, "-isLoading: \(isLoading) ")
            self.notifyMoreDataIsLoading?(isLoading)
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
    var notifyCompletedTodos: (([Int]) -> Void)? = nil
    var notifyTodosChanged: (([Todo]) -> Void)? = nil
    var notifyNoContent : ((Bool) -> Void)? = nil
    var notifyCurrentPage : ((Int) -> Void)? = nil
    var notifyMoreDataIsLoading : ((Bool) -> Void)? = nil
    var notifyRefresh : (() -> Void)? = nil
    var notifyHasNext : ((Bool) -> Void)? = nil
    var notifyErrResponse : ((String) -> Void)? = nil
    var notifyIsLoading : ((Bool) -> Void)? = nil
    var notifyCompletedIsEmpty : (() -> Void)? = nil
    
    let disposeBag = DisposeBag()
    var subscriptions = Set<AnyCancellable>()
}

// MARK: - fetch Data
extension TodosVM_Closure {
    
    func fetchRefresh() {
        self.fetchTodos(page: 1)
    }
    
    func fetchMore() {
        
        guard let pageInfo = self.currentPageMeta,
              pageInfo.hasNext() else {
            return print("다음페이지에 대한 정보가 없습니다.")
        }
        notifyMoreDataIsLoading?(true)
        if searchTerm.count > 0 {
            // 검색어가 있을 때
            self.searchTodos(searchTerm: searchTerm, page: currentPage + 1)
        } else {
            // 검색어가 없을 때
            self.fetchTodos(page: currentPage + 1)
        }
    }
    
    func fetchTodos(page: Int = 1) {
        guard checkIsLoading() else { return }
        self.notifyIsLoading?(true)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
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
                    notifyMoreDataIsLoading?(false)
                    self.currentPageMeta = pageInfo
                    
                case .failure(let failure):
                    self.handleError(failure)
                }
                
                self.notifyIsLoading?(false)
                notifyRefresh?()
            }
        }
    }
    
    func searchTodos(searchTerm: String = "빡코딩", page: Int = 1) {
        guard checkIsLoading() else { return }
        self.notifyIsLoading?(true)
        if page == 1 {
            self.todos = []
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
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
                    notifyMoreDataIsLoading?(false)
                    self.currentPageMeta = pageInfo
                    
                case .failure(let failure):
                    
                    self.handleError(failure)
                }
                self.notifyIsLoading?(false)
            }
        }
    }
    
    func addTodoFetchTodo(content: String) {
        
        guard checkIsLoading() else { return }
        self.notifyIsLoading?(true)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            TodosAPI_Closure.addTodoAndFetchTodos(title: content) { [weak self] result in
                guard let self = self else { return }
                
                self.isLoading = false
                
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
                self.notifyIsLoading?(false)
            }
        }
    }
    
    func editTodoEncoded(todo: Todo,
                         editContent: String? = nil,
                         changeIsDone: Bool? = nil,
                         completion : (() -> Void)? = nil) {
        
        guard checkIsLoading() else { return }
        
        guard let id = todo.id,
              let existingContent = todo.title,
              let existingIsDone = todo.isDone,
              let index = self.todos.firstIndex(where: { $0.id == id }) else { return }
        
        self.notifyIsLoading?(true)
        
        let content = editContent ?? existingContent
        let isDone = changeIsDone ?? existingIsDone
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            TodosAPI_Closure.editTodoClosureEncoded(id: id,
                                                    content: content,
                                                    isDone: isDone) { [weak self] result in
                
                guard let self = self else { return }
                
                self.isLoading = false
                
                switch result {
                case .success(let todoResponse):
                    guard let todo = todoResponse.data else { return }
                    
                    self.todos[index] = todo
                    
                    completion?()
                case .failure(let err):
                    self.handleError(err)
                    
                }
                self.notifyIsLoading?(false)
            }
        }
    }
    
    func changeCompleted(todoId: Int, isOn: Bool) {
        if isOn {
            self.completedTodosId.insert(todoId)
        } else {
            self.completedTodosId.remove(todoId)
        }
    }
    
    func deleteTodo(todo: Todo) {
        
        guard checkIsLoading() else { return }
        
        guard let todoId = todo.id else { return }
        
        self.notifyIsLoading?(true)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            TodosAPI_Closure.deleteTodoClosure(id: todoId) { [weak self] result in
                
                guard let self = self else { return }
                
                self.isLoading = false
                
                switch result {
                case .success(let todoResponse):
                    
                    guard let id = todoResponse.data?.id else { return }
                    
                    // id가 같지 않은 데이터만 다시 넣어줄 수도 있다.
                    self.todos = self.todos.filter({ $0.id ?? 0 != todoId })
                    
                    self.completedTodosId.remove(id)
                    
                case .failure(let err):
                    self.handleError(err)
                }
                self.notifyIsLoading?(false)
            }
        }
    }
    
    func deleteCompletedTodos() {
        
        guard checkCompletedTodos() else { return }
        guard checkIsLoading() else { return }
        
        self.notifyIsLoading?(true)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            TodosAPI_Closure.deleteTodosClosure(id: Array(self.completedTodosId)) { [weak self] deletedTodos in
                guard let self = self else { return }
                
                self.isLoading = false
                
                // todoList에서 삭제된 데이터 제거하기
                self.todos = self.todos.filter { !deletedTodos.contains($0.id ?? 0) }
                
                // completedList에서 삭제된 데이터 제거하기
                self.completedTodosId = self.completedTodosId.filter { !deletedTodos.contains($0) }
                
                self.notifyIsLoading?(false)
            }
        }
        
    }
    
    // MARK: - Closure To Async
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
    
//    private func deleteTodoAndFetchListClosureToAsync() {
//        Task {
//            do {
//                let result = try await TodosAPI_Closure.deleteTodosClosureToAsync(id: [5322, 5320])
//                print("테스트 result : \(result)")
//            } catch {
//                self.handleError(error)
//            }
//        }
//    }
    
    // MARK: - Closure To Rx
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
    
    // MARK: - Closure To Combine
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

// MARK: - Helper
extension TodosVM_Closure {
    private func resetInfo() {
        self.notifyNoContent?(false)
        self.notifyHasNext?(true)
    }
    
    private func checkIsLoading() -> Bool {
        
        if isLoading {
            return false
        } else {
            self.resetInfo()
            isLoading = true
            return true
        }
    }
    
    private func checkCompletedTodos() -> Bool {
        
        if self.completedTodosId.isEmpty {
            self.notifyCompletedIsEmpty?()
            return false
        } else {
            return true
        }
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

