//
//  TodosAPI+Async.swift
//  API_Practice
//
//  Created by CatSlave on 6/10/24.
//

import Foundation
import MultipartForm
import Combine
import RxSwift


extension TodosAPI_Async {
    
    typealias ListResponse = BaseListResponse<Todo>
    typealias TodoResponse = BaseResponse<Todo>
    typealias ResultListData = Result<ListResponse, ApiError>
    typealias ResultTodoData = Result<TodoResponse, ApiError>
    
    static func fetchTodosResultType(page: Int = 1) async -> ResultListData {
        
        guard let url = URL(baseUrl: baseUrl, optionUrl: "/todos", queryItems: ["page":"\(page)"]) else {
            return .failure(ApiError.notAllowedUrl)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue("application/json", forHTTPHeaderField: "accept")
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            if let err = checkResponse(response) {
                return .failure(err)
            }
            
            let todoListResponse = try JSONDecoder().decode(ListResponse.self, from: data)
            
            if let response = todoListResponse.data,
               !response.isEmpty {
                return .success(todoListResponse)
            } else {
                return .failure(ApiError.noContent)
            }
        } catch {
            return .failure(ApiError.decodingError)
        }
    }
    
    
    
    static func fetchTodos(page: Int = 1) async throws -> ListResponse {
        
        guard let url = URL(baseUrl: baseUrl, optionUrl: "/todos", queryItems: ["page":"\(page)"]) else {
            // eraseToAnyPublisher : Publisher wrapping
            let test = ListResponse(data: nil, meta: nil, message: nil)
            return test
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue("application/json", forHTTPHeaderField: "accept")
 
        let listResponse = try await executeRequest(request, ListResponse.self)
        
        return listResponse
    }
    
    static func fetchTodosNoParameter() async throws -> ListResponse {
        
        guard let url = URL(baseUrl: baseUrl, optionUrl: "/todos", queryItems: ["page":"1"]) else {
            // eraseToAnyPublisher : Publisher wrapping
            let test = ListResponse(data: nil, meta: nil, message: nil)
            return test
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue("application/json", forHTTPHeaderField: "accept")
 
        let listResponse = try await executeRequest(request, ListResponse.self)
        
        return listResponse
    }
 
    static func addTodoByMultipart(content: String, isDone: Bool = false) async throws -> TodoResponse {
        
        guard let url = URL(string: baseUrl + "/todos") else {
            throw ApiError.notAllowedUrl
        }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.addValue("application/json", forHTTPHeaderField: "accept")

        let form = MultipartForm(parts: [
            MultipartForm.Part(name: "title", value: content),
            MultipartForm.Part(name: "is_done", value: "\(isDone)")
        ])

        // 데이터 형식
        urlRequest.addValue(form.contentType, forHTTPHeaderField: "Content-Type")

        // 실제 데이터
        urlRequest.httpBody = form.bodyData
        
        let listResponse = try await executeRequest(urlRequest, TodoResponse.self)
        
        return listResponse
    }
        
    static func addTodoByJson(content: String, isDone: Bool = false) async throws -> TodoResponse {
        
        guard let url = URL(string: baseUrl + "/todos-json") else {
            throw ApiError.notAllowedUrl
        }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.addValue("application/json", forHTTPHeaderField: "accept")
        urlRequest.addValue("application/json", forHTTPHeaderField: "Content-Type")

        let requestParams : [String : Any] = ["title": content, "is_done" : "\(isDone)"]

        do {
            let jsonData = try JSONSerialization.data(withJSONObject: requestParams, options: [.prettyPrinted])
            urlRequest.httpBody = jsonData
            let listResponse = try await executeRequest(urlRequest, TodoResponse.self)
            return listResponse
        } catch {
            throw handleError(error)
        }
    }
    
    static func searchTodo(id: Int) async throws -> TodoResponse {
        
        guard let url = URL(string: baseUrl + "/todos" + "/\(id)") else {
            throw ApiError.notAllowedUrl
        }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "GET"
        urlRequest.addValue("application/json", forHTTPHeaderField: "accept")
        
        let listResponse = try await executeRequest(urlRequest, TodoResponse.self)
        
        return listResponse
    }
    
    static func editTodoEncoded(id: Int, content: String, isDone: Bool) async throws -> TodoResponse {
        
        guard let url = URL(string: baseUrl + "/todos" + "/\(id)") else {
            throw ApiError.notAllowedUrl
        }
        
        let requestParams = ["title" : content, "is_done" : "\(isDone)"]
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "PUT"
        urlRequest.addValue("application/json", forHTTPHeaderField: "accept")
        urlRequest.addValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        urlRequest.percentEncodeParameters(parameters: requestParams)
        
        let listResponse = try await executeRequest(urlRequest, TodoResponse.self)
        
        return listResponse
    }
    
    static func editTodoByJson(id: Int, content: String, isDone: Bool) async throws -> TodoResponse {
        
        guard let url = URL(string: baseUrl + "/todos-json" + "/\(id)") else {
            throw ApiError.notAllowedUrl
        }
        
        let requestParams = ["title" : content, "is_done" : "\(isDone)"]
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.addValue("application/json", forHTTPHeaderField: "accept")
        urlRequest.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: requestParams, options: [.prettyPrinted])
            urlRequest.httpBody = jsonData
            let listResponse = try await executeRequest(urlRequest, TodoResponse.self)
            return listResponse
        } catch {
            throw handleError(error)
        }
    }
    
    static func deleteTodo(id: Int) async throws -> TodoResponse {
        
        guard let url = URL(string: baseUrl + "/todos" + "/\(id)") else {
            throw ApiError.notAllowedUrl
        }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "DELETE"
        
        urlRequest.addValue("application/json", forHTTPHeaderField: "accept")
        
        let listResponse = try await executeRequest(urlRequest, TodoResponse.self)
        
        return listResponse
    }
    
    // MARK: - API 연쇄 호출
    
    static func addTodoAndFetchTodos(content: String) async throws -> [Todo] {
        
        let _ = try await addTodoByJson(content: content)
        let fetchTodoResponse = try await fetchTodos()
        
        guard let todos = fetchTodoResponse.data else {
            throw ApiError.noContent
        }
        
        return todos
    }
    
    static func addTodoAndFetchTodosNoError(content: String) async -> [Todo] {
        
        do {
            let _ = try await addTodoByJson(content: content)
            let fetchTodoResponse = try await fetchTodos()
            
            guard let todos = fetchTodoResponse.data else {
                return []
            }
            return todos
        } catch {
            return []
        }
    }
    
    // MARK: - API 동시 호출
    
    // async 배열 활용
    static func deleteTodosWithError(selectedTodosId: [Int]) async throws -> [Todo] {
        
        async let firstTask = self.deleteTodo(id: 2709)
        async let secondTask = self.deleteTodo(id: 2710)
        async let thirdTask = self.deleteTodo(id: 2708)
        
        let result = try await [firstTask.data,
                                secondTask.data,
                                thirdTask.data].compactMap { $0 }
        
        return result
    }
    
    static func deleteTodosNoError(selectedTodosId: [Int]) async -> [Todo] {
        async let firstTask = self.deleteTodo(id: 2709)
        async let secondTask = self.deleteTodo(id: 2710)
        async let thirdTask = self.deleteTodo(id: 2708)
        
        do {
            let result = try await [firstTask.data,
                                    secondTask.data,
                                    thirdTask.data].compactMap { $0 }
            
            return result
        } catch {
            return []
        }
    }

    // TaskGroup 활용
    
    static func deleteTodosWithThrowingTaskGroup(selectedTodosId: [Int]) async throws -> [Todo] {
        
        // Error를 던지는 작업 그룹
        try await withThrowingTaskGroup(of: Todo?.self) { (group: inout ThrowingTaskGroup<Todo?, any Error>) -> [Todo] in
            
            // 그룹에 작업을 추가
            for aTodoId in selectedTodosId {
                group.addTask(operation: {
                    let childTaskResult = try await self.deleteTodo(id: aTodoId)
                    return childTaskResult.data
                })
            }
            
            
            var deleteTodoIds: [Todo] = []
            
            // await 동기적 실행
            for try await singleValue in group {
                if let value = singleValue {
                    deleteTodoIds.append(value)
                }
            }
            
            return deleteTodoIds
        }
        
    }
    
    static func deleteTodosWithTaskGroup(selectedTodosId: [Int]) async -> [Todo] {
        
        // return에 error가 없는 타입
        await withTaskGroup(of: Todo?.self) { (group: inout TaskGroup<Todo?>) -> [Todo] in
            
            // 그룹에 작업을 추가
            for aTodoId in selectedTodosId {
                group.addTask(operation: {
                    do {
                        let childTaskResult = try await self.deleteTodo(id: aTodoId)
                        return childTaskResult.data
                    } catch {
                        return nil
                    }
                })
            }
            
            
            var deleteTodoIds: [Todo] = []
            
            // await 동기적 실행
            for await singleValue in group {
                if let value = singleValue {
                    deleteTodoIds.append(value)
                }
            }
            
            return deleteTodoIds
        }
    }
    
    static func searchTodosTaskGroupWithError(todosId: [Int]) async throws -> [Todo] {
        
        try await withThrowingTaskGroup(of: Todo?.self) { (group: inout ThrowingTaskGroup<Todo?, any Error>) in
            
            for atodoId in todosId {
                group.addTask(operation: {
                    let result = try await self.searchTodo(id: atodoId).data
                    return result
                })
            }
            
            var searchTodos: [Todo] = []
            
            for try await singleValue in group {
                if let value = singleValue {
                    searchTodos.append(value)
                }
            }
            
            return searchTodos
        }
    }
    
    static func searchTodosTaskGroupNoError(todosId: [Int]) async -> [Todo] {
        
        await withTaskGroup(of: Todo?.self) { (group: inout TaskGroup<Todo?>) in
            
            for atodoId in todosId {
                group.addTask(operation: {
                    do {
                        let result = try await self.searchTodo(id: atodoId).data
                        return result
                    } catch {
                        return nil
                    }
                })
            }
            
            var searchTodos: [Todo] = []
            
            for await singleValue in group {
                if let value = singleValue {
                    searchTodos.append(value)
                }
            }
            
            return searchTodos
        }
    }
    
}

// MARK: - Hepler
extension TodosAPI_Async {

    private static func executeRequest<T: Decodable>(_ urlRequest: URLRequest, _ type: T.Type) async throws -> T {
        do {
            let (data, response) = try await URLSession.shared.data(for: urlRequest)
            
            if let err = checkResponse(response) {
                throw err
            }
            
            let decoded = try JSONDecoder().decode(type.self, from: data)
            let responseData = try checkResponseType(decoded)
            return responseData
        } catch {
            throw handleError(error)
        }
    }
    
    private static func checkResponse(_ response: URLResponse?) -> ApiError? {
        
        guard let httpResponse = response as? HTTPURLResponse else {
            return .unknown(nil)
        }
        
        switch httpResponse.statusCode {
        case 401:
            return .unauthorized
      
        case 204:
            return .noContent
            
        default: print("default")
        }
        
        if !(200...299).contains(httpResponse.statusCode) {
            return .badStatus(code: httpResponse.statusCode)
        }
        
        return nil
    }
    
    private static func checkResponseType<T:Decodable>(_ decoded: T) throws -> T {
        if let listData = decoded as? ListResponse {
            switch checkContent(response: listData) {
            case .success(_):
                return decoded
            case .failure(let err):
                throw err
            }
        } else {
            return decoded
        }
    }
    
    private static func checkContent(response: ListResponse) -> ResultListData {
        guard let todos = response.data,
              !todos.isEmpty else {
            return .failure(.noContent)
        }
        return .success(response)
    }
    
    private static func handleError(_ err: Error) -> ApiError {
        if let _ = err as? JSONSerialization {
            return ApiError.jsonEncoding
        }
        
        if let _ = err as? DecodingError {
            return ApiError.decodingError
        }
        
        if let err = err as? ApiError {
            return err
        }
        
        return ApiError.unknown(err)
    }
}

// MARK: - Async To Combine
extension TodosAPI_Async {
    static func fetchTodosAsyncToCombine() -> AnyPublisher<ListResponse, Error> {
        return Future { (promise: @escaping (Result<ListResponse, Error>) -> Void) in
            Task {
                do {
                    let listResponse = try await fetchTodos()
                    promise(.success(listResponse))
                } catch {
                    promise(.failure(error))
                }
            }
        }.eraseToAnyPublisher()
    }
    
    static func genericFetchTodosAsyncToCombine<T>(asyncTask: @escaping () async throws -> T) -> AnyPublisher<T, Error> {
        return Future { (promise: @escaping (Result<T, Error>) -> Void) in
            Task {
                do {
                    let listResponse = try await asyncTask()
                    promise(.success(listResponse))
                } catch {
                    promise(.failure(error))
                }
            }
        }.eraseToAnyPublisher()
    }
}

// MARK: - Async To Rx
extension TodosAPI_Async {
    static func fetchTodosAsyncToRx() -> Observable<ListResponse> {
        
        return Observable.create { (emitter:AnyObserver<ListResponse>) in
            Task {
                do {
                    let listResponse = try await fetchTodos()
                    emitter.onNext(listResponse)
                    emitter.onCompleted()
                } catch {
                    emitter.onError(error)
                }
            }
            return Disposables.create()
        }
    }
    
    static func genericFetchTodosAsyncToRx<T>(asyncTask: @escaping () async throws -> T) -> Observable<T> {
        
        return Observable.create { (emitter:AnyObserver<T>) in
            Task {
                do {
                    let listResponse = try await asyncTask()
                    emitter.onNext(listResponse)
                    emitter.onCompleted()
                } catch {
                    emitter.onError(error)
                }
            }
            return Disposables.create()
        }
    }
}







