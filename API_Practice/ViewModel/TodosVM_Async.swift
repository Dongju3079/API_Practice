//
//  TodosVM_Async.swift
//  API_Practice
//
//  Created by CatSlave on 6/10/24.
//

import Foundation
import Combine
import CombineExt

class TodosVM_Async: ObservableObject {
    
    init() {
        deleteTodosWithGroupNoError()
    }
    
    private func handleError(_ err: Error) {
        
        guard let apiError = err as? TodosAPI_Async.ApiError else {
            print("알 수 없는 에러입니다.")
            return
        }
        
        print(apiError.info)
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
//    private func fetchTodosByResultType() {
//        TodosAPI_Combine.fetchTodosResultType()
//            .sink { [weak self ]result in
//                guard let self = self else { return }
//                switch result {
//                case .success(let todosResponse):
//                    print(#fileID, #function, #line, "-todosResponse: \(todosResponse) ")
//                case .failure(let err):
//                    self.handleError(err)
//                }
//            }.store(in: &subscriptions)
//    }
//        
//    private func addTodoMultipart() {
//        TodosAPI_Combine.addTodoByMultipart(content: "6.8 addTest", isDone: true)
//            .sink { [weak self] completion in
//                guard let self = self else { return }
//                self.handleCompletion(completion)
//            } receiveValue: { todoResponse in
//                print(#fileID, #function, #line, "-todoResponse: \(todoResponse) ")
//            }.store(in: &subscriptions)
//    }
//    
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
//    
//    private func searchTodoById() {
//        TodosAPI_Combine.searchTodo(id: 5291)
//            .sink { [weak self] completion in
//                guard let self = self else { return }
//                self.handleCompletion(completion)
//            } receiveValue: { todoResponse in
//                print(#fileID, #function, #line, "-todoResponse: \(todoResponse) ")
//            }.store(in: &subscriptions)
//    }
//
//    private func searchTodosByTerm() {
//        TodosAPI_Combine.searchTodos(searchTerm: "빡코딩")
//            .sink { [weak self] completion in
//                guard let self = self else { return }
//                self.handleCompletion(completion)
//            } receiveValue: { todoResponse in
//                print(#fileID, #function, #line, "-todoResponse: \(todoResponse) ")
//            }.store(in: &subscriptions)
//    }
//    
//    
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
//
//    private func editTodoJson() {
//        TodosAPI_Combine.editTodoByJson(id: 5292, content: "Edit Json", isDone: false)
//            .sink { [weak self] completion in
//                guard let self = self else { return }
//                self.handleCompletion(completion)
//            } receiveValue: { todoResponse in
//                print(#fileID, #function, #line, "-todoResponse: \(todoResponse) ")
//            }.store(in: &subscriptions)
//    }
//    
//    private func searchTodos() {
//        TodosAPI_Combine.deleteTodosMerge(selectedTodos: [5291, 4722, 4620, 9999])
//            .sink { [weak self] completion in
//                guard let self = self else { return }
//                switch completion {
//                case .failure(let err):
//                    self.handleError(err)
//                case .finished:
//                    print(#fileID, #function, #line, "-succes data upload ")
//                }
//            } receiveValue: { todo in
//                print(#fileID, #function, #line, "-todo : \(todo) ")
//            }.store(in: &subscriptions)
//    }
//    
//    private func searchTodosNoError() {
//        TodosAPI_Combine.deleteTodosZipNoError(selectedTodos: [4610, 4609])
//            .sink { todosId in
//                print(#fileID, #function, #line, "-todosId: \(todosId) ")
//            }.store(in: &subscriptions)
//    }
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


