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
    }
    
    enum Mutation {
        case setTodos(fetchTodos: [Todo], page: Meta)
        case appendTodos(addedTodos: [Todo], page: Meta)
        case clearTodos
        case setLoading(isLoading: Bool)
        case setSearchTerm(term: String?)
        case refreshEnded
        case catchError(err: Error)
    }
    
    
    struct State {
        var searchTerm: String? = nil
        @Pulse var todos: [Todo]
        @Pulse var pageInfo: Meta? = nil
        @Pulse var isLoading: Bool = false
        @Pulse var refreshEnded: Void? = nil
        @Pulse var errorMessage: String? = nil
        @Pulse var hasContent: Bool = true
    }
    
    var initialState: State = State(todos: [])
    
    func mutate(action: Action) -> Observable<Mutation> {
        
        switch action {
        case .fetchRefresh:
            guard !self.currentState.isLoading else {
                return Observable.empty()
            }
            let setLoadingOn = Observable.just(Mutation.setLoading(isLoading: true))
            let setStateTerm = Observable.just(Mutation.setSearchTerm(term: nil))
            
            let fetchTodo = Observable.just(())
                .delay(.milliseconds(1500), scheduler: MainScheduler.instance)
                .flatMapLatest { TodosAPI_Rx.fetchTodosRxAddErrorTask() }
                .compactMap { Optional(tuple: ($0.data, $0.meta)) }
                .map { Mutation.setTodos(fetchTodos: $0.0, page: $0.1) }
                .catch { err in
                    let stopLoading = Observable.just(Mutation.setLoading(isLoading: false))
                    let err = Observable.just(Mutation.catchError(err: err))
                    return Observable.concat([stopLoading, err])
                }

            let setLoadingOff = Observable.just(Mutation.setLoading(isLoading: false))
            let refreshEnded = Observable.just(Mutation.refreshEnded)
            
            return Observable.concat([setLoadingOn,
                                      setStateTerm,
                                      fetchTodo,
                                      setLoadingOff,
                                      refreshEnded])
            
        case .fetchMore:
            
            guard !self.currentState.isLoading,
                  let pageInfo = self.currentState.pageInfo,
                  let page = pageInfo.currentPage,
                  pageInfo.hasNext() else {
                return Observable.empty()
            }
            
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
                .compactMap { Optional(tuple: ($0.data, $0.meta)) }
                .map { Mutation.appendTodos(addedTodos: $0.0, page: $0.1) }
                .catch { err in
                    let stopLoading = Observable.just(Mutation.setLoading(isLoading: false))
                    let err = Observable.just(Mutation.catchError(err: err))
                    return Observable.concat([stopLoading, err])
                }
            
            let setLoadingOff = Observable.just(Mutation.setLoading(isLoading: false))
            
            return Observable.concat([setLoadingOn, fetchAddedTodo, setLoadingOff])
            
        case .searchTodos(let term):
            guard !self.currentState.isLoading else {
                return Observable.empty()
            }
                        
            let setLoadingOn = Observable.just(Mutation.setLoading(isLoading: true))
            
            let searchTodos =  TodosAPI_Rx.searchTodosRx(searchTerm: term)
                .compactMap { Optional(tuple: ($0.data, $0.meta)) }
                .map { Mutation.setTodos(fetchTodos: $0.0, page: $0.1) }
                .catch { err in
                    let stopLoading = Observable.just(Mutation.setLoading(isLoading: false))
                    let err = Observable.just(Mutation.catchError(err: err))
                    return Observable.concat([stopLoading, err])
                }

            let setStateTerm = Observable.just(Mutation.setSearchTerm(term: term))
            
            let setLoadingOff = Observable.just(Mutation.setLoading(isLoading: false))
            
            return Observable.concat([setLoadingOn, setStateTerm, setLoadingOff, searchTodos])
            
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
        case .appendTodos(let fetchedTodos, let page):
            newState.todos.append(contentsOf: fetchedTodos)
            newState.pageInfo = page
        case .setLoading(let isLoading):
            newState.isLoading = isLoading
        case .setSearchTerm(let term):
            newState.searchTerm = term
            
        case .clearTodos:
            newState.todos = []
            newState.pageInfo = nil
        case .refreshEnded:
            newState.refreshEnded = ()
        case .catchError(let err):
            newState = handleError(state: newState, err: err)
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
        case .errResponseFromServer(let errorResponse):
            if let message = errorResponse?.message {
                newState.errorMessage = message
            }
        default:
            newState.errorMessage = apiError.info
        }
        
        return newState
    }
    
}
