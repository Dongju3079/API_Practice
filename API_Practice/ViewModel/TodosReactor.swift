//
//  TodosReactor.swift
//  API_Practice
//
//  Created by CatSlave on 6/27/24.
//

import Foundation
import ReactorKit

class TodosReactor: Reactor {
    
    enum Action {
        case fetchRefresh
        case fetchMore
        case searchTodos(searchTerm: String)
        case clearTodos
        case addTodo(content: String)
        case deleteTodo(id: Int)
        case completeTodos
        case editTodo(todo: Todo, content: String?, isDone: Bool?)
    }
    
    enum Mutation {
        case setTodos(fetchTodos: [Todo], page: Meta)
        case appendTodos(addedTodos: [Todo], page: Meta)
        case addedTodo
        case deleteTodo(deleteTodo: Todo)
        case clearTodos
        case setLoading(isLoading: Bool)
        case setSearchTerm(term: String?)
        case refreshEnded
        case resetSearchText
        case catchError(err: Error)
        case editTodo(todo: Todo, index: Int)
    }
    
    struct State {
        var searchTerm: String? = nil
        
        var completedTodos: [Int] {
            todos.filter({ $0.isDone ?? false }).compactMap({ $0.id })
        }
        
        @Pulse var todos: [Todo] = []
        @Pulse var pageInfo: Meta? = nil
        @Pulse var isLoading: Bool = false
        @Pulse var refreshEnded: Void? = nil
        @Pulse var resetSearchTerm: Void? = nil
        @Pulse var errorMessage: String? = nil
        @Pulse var hasContent: Bool = true
        @Pulse var addedTodo: Void? = nil
    }
    
    var initialState: State = State()
    
    init() {
        action.onNext(.fetchRefresh)
    }
    
    func mutate(action: Action) -> Observable<Mutation> {
        print("테스트 150 action : \(action)")
        guard !self.currentState.isLoading else {
            return Observable.empty()
        }
        
        switch action {
            
        case .fetchRefresh:
            return fetchTodos()
            
        case .fetchMore:
            guard let pageInfo = self.currentState.pageInfo,
                  let page = pageInfo.currentPage,
                  !self.currentState.todos.isEmpty,
                  pageInfo.hasNext() else {
                return Observable.empty()
            }
            
            return fetchMore(page)
            
        case .searchTodos(let term):
            return searchTodos(term)
            
        case .addTodo(let content):
            return addTodo(content)
            
        case .deleteTodo(let id):
            return deleteTodo(id)
            
        case .completeTodos:
            return completedTodo()
            
        case .editTodo(let todo, let content, let isDone):
            guard let id = todo.id,
                  let existingContent = todo.title,
                  let existingIsDone = todo.isDone,
                  let index = self.currentState.todos.firstIndex(where: { $0.id == id }) else { 
                return Observable.empty()
            }
            
            let content = content ?? existingContent
            let isDone = isDone ?? existingIsDone
            
            return TodosAPI_Rx.editTodoRxEncoded(id: id, content: content, isDone: isDone)
                .compactMap { $0.data }
                .map { Mutation.editTodo(todo: $0, index: index) }
            
        case .clearTodos:
            return Observable.just(Mutation.clearTodos)
        }
    }
    
    func reduce(state: State, mutation: Mutation) -> State {
        
        var newState = state
        
        switch mutation {
            
        case .setTodos(let fetchTodos, let meta):
            newState.hasContent = true
            newState.todos = fetchTodos
            newState.pageInfo = meta
            
        case .appendTodos(let fetchTodos, let page):
            newState.todos.append(contentsOf: fetchTodos)
            newState.pageInfo = page
            
        case .editTodo(let todo, let index):
            newState.todos[index] = todo
            
        case .deleteTodo(let todo):
            newState.todos.removeAll { $0.id == todo.id }
            
        case .setLoading(let isLoading):
            newState.isLoading = isLoading
            
        case .setSearchTerm(let term):
            newState.searchTerm = term
            
        case .clearTodos:
            newState.todos = []
            
        case .resetSearchText:
            newState.searchTerm = nil
            newState.resetSearchTerm = ()
            
        case .refreshEnded:
            newState.refreshEnded = ()
            
        case .catchError(let err):
            newState = handleError(state: newState, err: err)
            
        case .addedTodo:
            newState.addedTodo = ()
        }
        
        return newState
    }
    
    func handleError(state: State, err: Error) -> State {
        var newState = state
        guard let apiError = err as? TodosAPI_Rx.ApiError else {
            newState.errorMessage = TodosAPI_Rx.ApiError.unknown(err).info
            return newState
        }
        
        switch apiError {
        case .noContent:
            newState.hasContent = false
            newState.pageInfo = nil
        case .errResponseFromServer(let errorResponse):
            if let message = errorResponse?.message {
                newState.errorMessage = message
            }
        case .incompleteTask:
            newState.errorMessage = apiError.info
        default:
            newState.errorMessage = apiError.info
        }
        
        return newState
    }
    
}

// MARK: - CRUD
extension TodosReactor {
    
    private func fetchTodos() -> Observable<TodosReactor.Mutation> {

        let setLoadingOn = Observable.just(Mutation.setLoading(isLoading: true))
        
        let fetchTodo = TodosAPI_Rx.fetchTodosRxAddErrorTask()
            .delay(.milliseconds(1500), scheduler: MainScheduler.instance)
            .compactMap {
                if let responseData = Optional(tuple: ($0.data, $0.meta)) {
                    return responseData
                } else {
                    throw TodosAPI_Rx.ApiError.noContent
                }
            }
            .map { (fetchTodos, pageInfo) in
                Mutation.setTodos(fetchTodos: fetchTodos, page: pageInfo)
            }
            .catch { err in
                let stopLoading = Observable.just(Mutation.setLoading(isLoading: false))
                let err = Observable.just(Mutation.catchError(err: err))
                return Observable.concat([stopLoading, err])
            }
        
        let setLoadingOff = Observable.just(Mutation.setLoading(isLoading: false))
        let resetSearchTerm = Observable.just(Mutation.resetSearchText)
        let refreshEnded = Observable.just(Mutation.refreshEnded)
        
        return Observable.concat([setLoadingOn,
                                  fetchTodo,
                                  setLoadingOff,
                                  resetSearchTerm,
                                  refreshEnded])
    }
    
    private func fetchMore(_ page: Int) -> Observable<TodosReactor.Mutation> {
        let setLoadingOn = Observable.just(Mutation.setLoading(isLoading: true))
        
        let fetchAddedTodo = Observable.just(())
            .delay(.milliseconds(1500), scheduler: MainScheduler.instance)
            .withUnretained(self)
            .flatMapLatest { reactor, _ in
                if let term = reactor.currentState.searchTerm {
                    return TodosAPI_Rx.searchTodosRx(searchTerm: term, page: page + 1)
                } else {
                    return TodosAPI_Rx.fetchTodosRxAddErrorTask(page: page + 1)
                }
            }
            .compactMap {
                if let responseData = Optional(tuple: ($0.data, $0.meta)) {
                    return responseData
                } else {
                    throw TodosAPI_Rx.ApiError.noContent
                }
            }
            .map { Mutation.appendTodos(addedTodos: $0.0, page: $0.1) }
            .catch { err in
                let stopLoading = Observable.just(Mutation.setLoading(isLoading: false))
                let err = Observable.just(Mutation.catchError(err: err))
                return Observable.concat([stopLoading, err])
            }
        
        let setLoadingOff = Observable.just(Mutation.setLoading(isLoading: false))
        
        return Observable.concat([setLoadingOn, fetchAddedTodo, setLoadingOff])
    }
    
    
    private func searchTodos(_ term: String) -> Observable<TodosReactor.Mutation> {
        let setLoadingOn = Observable.just(Mutation.setLoading(isLoading: true))
        
        let searchTodos =  Observable.just(())
            .delay(.milliseconds(1500), scheduler: MainScheduler.instance)
            .flatMapLatest { _ in
                TodosAPI_Rx.searchTodosRx(searchTerm: term)
            }
            .compactMap { Optional(tuple: ($0.data, $0.meta)) }
            .map { Mutation.setTodos(fetchTodos: $0.0, page: $0.1) }
            .catch { err in
                return Observable.just(Mutation.catchError(err: err))
            }
        
        let setStateTerm = Observable.just(Mutation.setSearchTerm(term: term))
        
        let setLoadingOff = Observable.just(Mutation.setLoading(isLoading: false))
        
        return Observable.concat([setLoadingOn, searchTodos, setStateTerm, setLoadingOff])
    }
    
    private func addTodo(_ content: String) -> Observable<TodosReactor.Mutation> {
        let setLoadingOn = Observable.just(Mutation.setLoading(isLoading: true))
        
        let fetchAddedTodo = TodosAPI_Rx.addTodoAndFetchTodos(content: content)
            .delay(.milliseconds(500), scheduler: MainScheduler.instance)
            .compactMap {
                if let responseData = Optional(tuple: ($0.data, $0.meta)) {
                    return responseData
                } else {
                    throw TodosAPI_Rx.ApiError.noContent
                }
            }
            .map { (todoList, pageInfo) in
                Mutation.setTodos(fetchTodos: todoList, page: pageInfo)
            }
            .catch { err in
                let stopLoading = Observable.just(Mutation.setLoading(isLoading: false))
                let err = Observable.just(Mutation.catchError(err: err))
                return Observable.concat([stopLoading, err])
            }
        
        let resetSearchTerm = Observable.just(Mutation.resetSearchText)
        let setLoadingOff = Observable.just(Mutation.setLoading(isLoading: false))
        let addedTodo = Observable.just(Mutation.addedTodo)
        
        return Observable.concat([setLoadingOn, fetchAddedTodo, resetSearchTerm, setLoadingOff, addedTodo])
    }
    
    private func deleteTodo(_ id: Int) -> Observable<TodosReactor.Mutation> {
        let setLoadingOn = Observable.just(Mutation.setLoading(isLoading: true))
        
        let deleteTodo = TodosAPI_Rx.deleteTodoRx(id: id)
            .delay(.milliseconds(500), scheduler: MainScheduler.instance)
            .compactMap {
                if let responseData = $0.data {
                    return responseData
                } else {
                    throw TodosAPI_Rx.ApiError.noContent
                }
            }
            .map { Mutation.deleteTodo(deleteTodo: $0) }
            .catch { err in
                let stopLoading = Observable.just(Mutation.setLoading(isLoading: false))
                let incompleteError = Observable.just(Mutation.catchError(err: TodosAPI_Rx.ApiError.incompleteTask))
                return Observable.concat([stopLoading, incompleteError])
            }
        
        let setLoadingOff = Observable.just(Mutation.setLoading(isLoading: false))
        
        return Observable.concat([setLoadingOn, deleteTodo, setLoadingOff])
    }
    
    private func completedTodo() -> Observable<TodosReactor.Mutation> {
        let setLoadingOn = Observable.just(Mutation.setLoading(isLoading: true))
        
        let deleteTodo = TodosAPI_Rx.deleteTodosRxZip(selectedTodos: self.currentState.completedTodos)
            .withUnretained(self)
            .delay(.milliseconds(500), scheduler: MainScheduler.instance)
            .map { reactor, completedTodosId in
                guard let page = reactor.currentState.pageInfo else {
                    throw TodosAPI_Rx.ApiError.noContent
                }
                let remainingTodo = reactor.currentState.todos.filter { !completedTodosId.contains($0.id ?? 0) }
                return Mutation.setTodos(fetchTodos: remainingTodo, page: page)
            }
        
        let setLoadingOff = Observable.just(Mutation.setLoading(isLoading: false))
        
        return Observable.concat([setLoadingOn, deleteTodo, setLoadingOff])
    }
}

