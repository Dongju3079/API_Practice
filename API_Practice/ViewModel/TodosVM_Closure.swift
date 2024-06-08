//
//  TodosVM+Closure.swift
//  API_Practice
//
//  Created by CatSlave on 6/4/24.
//

import Foundation
import Combine

class TodosVM_Closure: ObservableObject {
    
    init() {
        self.addTodoMultipart()
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
    private func fetchTodos() {
        TodosAPI_Closure.fetchTodosClosure { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let todoList):
                print("테스트 success : \(todoList)")

            case .failure(let failure):
                self.handleError(failure)
            }
        }
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
                return
            case .failure(let failure):
                return
            }
        }
    }
    
}
