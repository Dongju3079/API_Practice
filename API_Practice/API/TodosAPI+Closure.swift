//
//  TodosAPI+Closure.swift
//  API_Practice
//
//  Created by CatSlave on 6/4/24.
//

import Foundation
import MultipartForm
import RxSwift
import Combine

extension TodosAPI_Closure {
    
    typealias ListResponse = BaseListResponse<Todo>
    typealias TodoResponse = BaseResponse<Todo>
    typealias ResultListData = Result<ListResponse, ApiError>
    typealias ResultTodoData = Result<TodoResponse, ApiError>
    typealias ResultTodos = Result<[Todo], ApiError>
    
    static func fetchTodosClosure(page: Int = 1, completion: @escaping (ResultListData) -> Void) {
        
        guard let url = URL(baseUrl: baseUrl, optionUrl: "/todos", queryItems: ["page":"\(page)"]) else {
            return completion(.failure(.unknown(nil)))
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue("application/json", forHTTPHeaderField: "accept")
        
        URLSession.shared.dataTask(with: request) { data, response, err in
            if let err = checkResponse(err, response) {
                return completion(.failure(err))
            }
            
            if let jsonData = data {
                switch self.parseJsonBaseData(data: jsonData, type: ListResponse.self) {
                case .success(let listData):
                    return completion(.success(listData))
                case .failure(let err):
                    return completion(.failure(err))
                }
            }
        }.resume()
    }
    
    static func addTodoClosureByMultipart(content: String,
                                          isDone: Bool = false,
                                          completion: @escaping (ResultTodoData) -> Void) {
        
        guard let url = URL(string: baseUrl + "/todos") else {
            return completion(.failure(.notAllowedUrl))
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
        
        URLSession.shared.dataTask(with: urlRequest) { data, response, err in
            if let err = checkResponse(err, response) {
                return completion(.failure(err))
            }
            
            if let jsonData = data {
                switch self.parseJsonBaseData(data: jsonData, type: TodoResponse.self) {
                case .success(let listData):
                    return completion(.success(listData))
                case .failure(let err):
                    return completion(.failure(err))
                }
            }
        }.resume()
        
    }
    
    static func addTodoClosureByJson(content: String,
                                     isDone: Bool = false,
                                     completion: @escaping (ResultTodoData) -> Void) {
        
        guard let url = URL(string: baseUrl + "/todos-json") else {
            return completion(.failure(.notAllowedUrl))
        }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.addValue("application/json", forHTTPHeaderField: "accept")
        urlRequest.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let requestParams : [String : Any] = ["title": content, "is_done" : "\(isDone)"]
        
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: requestParams, options: [.prettyPrinted])
            
            urlRequest.httpBody = jsonData
        } catch {
            
            return completion(.failure(ApiError.jsonEncoding))
        }
        
        URLSession.shared.dataTask(with: urlRequest) { data, response, err in
            if let err = checkResponse(err, response) {
                return completion(.failure(err))
            }
            
            if let jsonData = data {
                switch self.parseJsonBaseData(data: jsonData, type: TodoResponse.self) {
                case .success(let listData):
                    return completion(.success(listData))
                case .failure(let err):
                    return completion(.failure(err))
                }
            }
        }.resume()
        
    }
    
    static func searchTodosClosure(searchTerm: String,
                                   page: Int = 1,
                                   completion: @escaping (ResultListData) -> Void) {
        
        let queryItems = ["query": searchTerm, "page": "\(page)"]
        
        guard let url = URL(baseUrl: baseUrl, optionUrl: "/todos", queryItems: queryItems) else {
            completion(.failure(.unknown(nil)))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue("application/json", forHTTPHeaderField: "accept")
        
        
        URLSession.shared.dataTask(with: request) { data, response, err in
            if let err = checkResponse(err, response) {
                return completion(.failure(err))
            }
            
            if let jsonData = data {
                switch self.parseJsonBaseData(data: jsonData, type: ListResponse.self) {
                case .success(let listData):
                    return completion(.success(listData))
                case .failure(let err):
                    return completion(.failure(err))
                }
            }
        }.resume()
        
    }
    
    static func searchTodoClosure(id: Int,
                                  completion: @escaping (ResultTodoData) -> Void) {
        
        guard let url = URL(string: baseUrl + "/todos" + "/\(id)") else {
            return completion(.failure(.notAllowedUrl))
        }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "GET"
        urlRequest.addValue("application/json", forHTTPHeaderField: "accept")
        
        
        URLSession.shared.dataTask(with: urlRequest) { data, response, err in
            if let err = checkResponse(err, response) {
                return completion(.failure(err))
            }
            
            if let jsonData = data {
                switch self.parseJsonBaseData(data: jsonData, type: TodoResponse.self) {
                case .success(let listData):
                    return completion(.success(listData))
                case .failure(let err):
                    return completion(.failure(err))
                }
            }
        }.resume()
        
    }
    
    static func editTodoClosureEncoded(id: Int,
                                       content: String,
                                       isDone: Bool,
                                       completion: @escaping (ResultTodoData) -> Void) {
        
        guard let url = URL(string: baseUrl + "/todos" + "/\(id)") else {
            return completion(.failure(.notAllowedUrl))
        }
        
        let requestParams = ["title" : content, "is_done" : "\(isDone)"]
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "PUT"
        urlRequest.addValue("application/json", forHTTPHeaderField: "accept")
        urlRequest.addValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        urlRequest.percentEncodeParameters(parameters: requestParams)
        
        URLSession.shared.dataTask(with: urlRequest) { data, response, err in
            if let err = checkResponse(err, response) {
                return completion(.failure(err))
            }
            
            if let jsonData = data {
                switch self.parseJsonBaseData(data: jsonData, type: TodoResponse.self) {
                case .success(let listData):
                    return completion(.success(listData))
                case .failure(let err):
                    return completion(.failure(err))
                }
            }
        }.resume()
        
    }
    
    static func editTodoClosureByJson(id: Int,
                                      content: String,
                                      isDone: Bool,
                                      completion: @escaping (ResultTodoData) -> Void) {
        
        guard let url = URL(string: baseUrl + "/todos-json" + "/\(id)") else {
            return completion(.failure(.notAllowedUrl))
        }
        
        let requestParams = ["title" : content, "is_done" : "\(isDone)"]
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.addValue("application/json", forHTTPHeaderField: "accept")
        urlRequest.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: requestParams, options: [.prettyPrinted])
            urlRequest.httpBody = jsonData
        } catch {
            return completion(.failure(ApiError.jsonEncoding))
        }
        
        URLSession.shared.dataTask(with: urlRequest) { data, response, err in
            if let err = checkResponse(err, response) {
                return completion(.failure(err))
            }
            
            if let jsonData = data {
                switch self.parseJsonBaseData(data: jsonData, type: TodoResponse.self) {
                case .success(let listData):
                    return completion(.success(listData))
                case .failure(let err):
                    return completion(.failure(err))
                }
            }
        }.resume()
        
        
    }
    
    static func deleteTodoClosure(id: Int,
                                  completion: @escaping (ResultTodoData) -> Void) {
        
        guard let url = URL(string: baseUrl + "/todos" + "/\(id)") else {
            return completion(.failure(.notAllowedUrl))
        }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "DELETE"
        
        urlRequest.addValue("application/json", forHTTPHeaderField: "accept")
        
        URLSession.shared.dataTask(with: urlRequest) { data, response, err in
            if let err = checkResponse(err, response) {
                return completion(.failure(err))
            }
            
            if let jsonData = data {
                switch self.parseJsonBaseData(data: jsonData, type: TodoResponse.self) {
                case .success(let listData):
                    return completion(.success(listData))
                case .failure(let err):
                    return completion(.failure(err))
                }
            }
        }.resume()
        
        
    }
    
    // MARK: - API 연쇄 호출
    static func addATodoAndFetchTodos(title: String,
                                      isDone: Bool = false,
                                      completion: @escaping (Result<ListResponse, ApiError>) -> Void){
        self.addTodoClosureByJson(content: title, isDone: isDone) { result in
            switch result {
            case .success(_):
                self.fetchTodosClosure { result in
                    switch result {
                    case .success(let listResponse):
                        return completion(.success(listResponse))
                    case .failure(_):
                        print("목록 불러오기 실패")
                    }
                }
            case .failure(_):
                print("할 일 추가 실패")
            }
        }
    }
    
    // MARK: - API 동시 호출
    static func deleteTodosClosure(id: [Int], completion: @escaping (ResultTodos) -> Void) {
        
        let group = DispatchGroup()
        
        var deleteTodos = [Todo]()
        
        id.forEach { id in
            group.enter()
            self.deleteTodoClosure(id: id) { result in
                switch result {
                case .success(let todoData):
                    guard let todo = todoData.data else { return }
                    deleteTodos.append(todo)
                    group.leave()
                case .failure(_):
                    print("삭제 실패")
                }
            }
        }
        
        group.notify(queue: .main) {
            print("테스트 deleteTodo : \(deleteTodos)")
            
            completion(.success(deleteTodos))
        }
        
    }
}

// MARK: - Closure To Async
extension TodosAPI_Closure {
    
    static func fetchTodosClosureToAsync() async -> ResultListData {
        return await withCheckedContinuation { (continuation: CheckedContinuation<ResultListData, Never>) in
            fetchTodosClosure { result in
                continuation.resume(returning: result)
            }
        }
    }
    
    static func fetchTodosClosureToAsyncWithError() async throws -> ListResponse {
        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<ListResponse, Error>) in
            fetchTodosClosure { result in
                switch result {
                case .success(let data):
                    continuation.resume(returning: data)
                case .failure(let err):
                    continuation.resume(throwing: err)
                }
            }
        }
    }
    
    static func addTodosClosureToAsyncWithError(content: String, isDone: Bool = false) async throws -> TodoResponse {
        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<TodoResponse, Error>) in
            self.addTodoClosureByJson(content: content) { result in
                switch result {
                case .success(let todoData):
                    continuation.resume(returning: todoData)
                case .failure(let err):
                    continuation.resume(throwing: err)
                }
            }
        }
    }
    
    static func deleteTodoClosureToAsyncWithError(id: Int) async throws -> TodoResponse {
        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<TodoResponse, Error>) in
            self.deleteTodoClosure(id: id) { result in
                switch result {
                case .success(let todoData):
                    continuation.resume(returning: todoData)
                case .failure(let err):
                    continuation.resume(throwing: err)
                }
            }
        }
    }
    
    static func searchTodosClosureToAsyncWithError(id: Int) async throws -> TodoResponse {
        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<TodoResponse, Error>) in
            self.searchTodoClosure(id: id) { result in
                switch result {
                case .success(let todoData):
                    continuation.resume(returning: todoData)
                case .failure(let err):
                    continuation.resume(throwing: err)
                }
            }
        }
    }
    
    static func editTodosClosureToAsyncWithError(id: Int, content: String, isDone: Bool = false) async throws -> TodoResponse {
        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<TodoResponse, Error>) in
            self.editTodoClosureEncoded(id: id, content: content, isDone: isDone) { result in
                switch result {
                case .success(let todoData):
                    continuation.resume(returning: todoData)
                case .failure(let err):
                    continuation.resume(throwing: err)
                }
            }
        }
    }
    
    static func addTodoAndFetchListClosureToAsync(content: String, isDone: Bool = false) async throws -> ListResponse {
        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<ListResponse, Error>) in
            self.addATodoAndFetchTodos(title: content) { result in
                switch result {
                case .success(let success):
                    continuation.resume(returning: success)
                case .failure(let failure):
                    continuation.resume(throwing: failure)
                }
            }
        }
    }
    
    static func deleteTodosClosureToAsync(id: [Int]) async throws -> [Todo] {
        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<[Todo], Error>) in
            self.deleteTodosClosure(id: id) { result in
                switch result {
                case .success(let todos):
                    continuation.resume(returning: todos)
                case .failure(let err):
                    continuation.resume(throwing: err)
                }
            }
        }
    }
}

// MARK: - Closure To Rx
extension TodosAPI_Closure {
    
    static func fetchTodosClosureToRx() -> Observable<ResultListData> {
        return Observable.create { emitter in
            self.fetchTodosClosure { result in
                emitter.onNext(result)
                emitter.onCompleted()
            }
            return Disposables.create()
        }
    }
    
    static func fetchTodosClosureToRxWithError() -> Observable<ListResponse> {
        return Observable.create { emitter in
            fetchTodosClosure { result in
                switch result {
                case .success(let listData):
                    emitter.onNext(listData)
                    emitter.onCompleted()
                case .failure(let err):
                    emitter.onError(err)
                }
            }
            return Disposables.create()
        }
    }
    
    static func addTodosClosureToRxWithError(content: String, isDone: Bool = false) -> Observable<TodoResponse> {
        return Observable.create { emitter in
            self.addTodoClosureByJson(content: content) { result in
                switch result {
                case .success(let data):
                    emitter.onNext(data)
                    emitter.onCompleted()
                case .failure(let err):
                    emitter.onError(err)
                }
            }
            return Disposables.create()
        }
    }
    
    static func deleteTodoClosureToRxWithError(id: Int) -> Observable<TodoResponse> {
        return Observable.create { emitter in
            self.deleteTodoClosure(id: id) { result in
                switch result {
                case .success(let data):
                    emitter.onNext(data)
                    emitter.onCompleted()
                case .failure(let err):
                    emitter.onError(err)
                }
            }
            return Disposables.create()
        }
    }
    
    static func searchTodosClosureToRxWithError(id: Int) -> Observable<TodoResponse> {
        return Observable.create { emitter in
            self.searchTodoClosure(id: id) { result in
                switch result {
                case .success(let data):
                    emitter.onNext(data)
                    emitter.onCompleted()
                case .failure(let err):
                    emitter.onError(err)
                }
            }
            return Disposables.create()
        }
    }
    
    static func editTodosClosureToRxWithError(id: Int, content: String, isDone: Bool = false) -> Observable<Todo> {
        return Observable.create { (emitter: AnyObserver<TodoResponse>) in
            self.editTodoClosureByJson(id: id, content: content, isDone: isDone) { result in
                switch result {
                case .success(let data):
                    emitter.onNext(data)
                    emitter.onCompleted()
                case .failure(let err):
                    emitter.onError(err)
                }
            }
            return Disposables.create()
        }.compactMap { $0.data }
    }
    
    static func addTodoAndFetchListClosureToRx(content: String, isDone: Bool = false) -> Observable<[Todo]> {
        return Observable.create { (emitter: AnyObserver<ListResponse>) in
            self.addATodoAndFetchTodos(title: content) { result in
                switch result {
                case .success(let listData):
                    emitter.onNext(listData)
                    emitter.onCompleted()
                case .failure(let err):
                    emitter.onError(err)
                }
            }
            return Disposables.create()
        }
        .compactMap {
            guard let todos = $0.data else {
                throw ApiError.noContent
            }
            return $0.data
        }
        .catch { err in
            if let apiError = err as? ApiError {
                throw apiError
            } else {
                throw err
            }
        }
    }
    
    static func deleteTodosClosureToRx(id: [Int]) -> Observable<ResultTodos> {
        return Observable.create { emitter in
            self.deleteTodosClosure(id: id) { result in
                emitter.onNext(result)
            }
            return Disposables.create()
        }
    }
}

// MARK: - Closure To Combine
extension TodosAPI_Closure {
    
    // 에러 처리 O
    static func fetchTodosClosureToCombineWithError() -> AnyPublisher<ListResponse, ApiError> {
        return Future { (promise: @escaping (Result<ListResponse, ApiError>) -> Void) in
            fetchTodosClosure { result in
                
                // 1번
                promise(result)
                
                // 2번
//                switch result {
//                case .success(let listData):
//                    promise(.success(listData))
//                case .failure(let err):
//                    promise(.failure(err))
//                }
            }
        }.eraseToAnyPublisher()
    }
    
    // 에러 처리 O(형태 변경)
    static func fetchTodosClosureToCombineMapError() -> AnyPublisher<ListResponse, Error> {
        return Future { (promise: @escaping (Result<ListResponse, ApiError>) -> Void) in
            fetchTodosClosure { result in
                promise(result)
            }
        }
        .tryMap({ listResponse in
            guard let todos = listResponse.data else {
                throw ApiError.noContent
            }
            
            return listResponse
        })
        .mapError({ err in
            if let _ = err as? ApiError {
                return ApiError.unauthorized
            }
            
            return err
        })
        .eraseToAnyPublisher()
    }
    
    // 에러 처리 X
    static func fetchTodosClosureToCombineNoError() -> AnyPublisher<[Todo], Never> {
        return Future { (promise: @escaping (Result<ListResponse, ApiError>) -> Void) in
            fetchTodosClosure { result in
                promise(result)
            }
        }
        .map({ $0.data ?? [] })
        
        // 1번
//        .catch({ err in
//            return Just([])
//        })
        // 2번
        .replaceError(with: [])
        .eraseToAnyPublisher()
    }
    
    static func addTodosClosureToCombineWithError(content: String, isDone: Bool = false) -> AnyPublisher<TodoResponse, ApiError> {
        return Future { (promise: @escaping (Result<TodoResponse, ApiError>) -> Void) in
            addTodoClosureByJson(content: content) { result in
                promise(result)
            }
        }.eraseToAnyPublisher()
    }
    
    static func addTodosClosureToCombineNoError(content: String, isDone: Bool = false) -> AnyPublisher<Todo?, Never> {
        return Future { (promise: @escaping (Result<TodoResponse, ApiError>) -> Void) in
            addTodoClosureByJson(content: content) { result in
                promise(result)
            }
        }
        .map({ $0.data })
        .replaceError(with: nil)
        .eraseToAnyPublisher()
    }
    
    static func deleteTodoClosureToCombineWithError(id: Int)  -> AnyPublisher<TodoResponse, ApiError> {
        return Future { (promise: @escaping (Result<TodoResponse, ApiError>) -> Void) in
            deleteTodoClosure(id: id) { result in
                promise(result)
            }
        }.eraseToAnyPublisher()
    }
    
    static func searchTodosClosureToCombineWithError(id: Int)  -> AnyPublisher<TodoResponse, ApiError> {
        return Future { (promise: @escaping (Result<TodoResponse, ApiError>) -> Void) in
            searchTodoClosure(id: id) { result in
                promise(result)
            }
        }.eraseToAnyPublisher()
    }
    
    static func editTodosClosureToCombineWithError(id: Int, content: String, isDone: Bool = false)  -> AnyPublisher<Todo?, Error> {
        return Future { (promise: @escaping (Result<TodoResponse, ApiError>) -> Void) in
            editTodoClosureByJson(id: id, content: content, isDone: isDone) { result in
                promise(result)
            }
        }
        .tryMap({ todoResponse in
            guard let todo = todoResponse.data else {
                throw ApiError.noContent
            }
            
            return todo
        })
        .mapError({ err in
            if let apiError = err as? ApiError {
                return apiError
            }
            
            return ApiError.unknown(err)
        })
        .eraseToAnyPublisher()
    }
    
    static func editTodosClosureToCombineWithError(id: Int, content: String, isDone: Bool = false)  -> AnyPublisher<Todo?, Never> {
        return Future { (promise: @escaping (Result<TodoResponse, ApiError>) -> Void) in
            editTodoClosureByJson(id: id, content: content, isDone: isDone) { result in
                promise(result)
            }
        }
        .map({ $0.data })
        .replaceError(with: nil)
        .eraseToAnyPublisher()
    }
    
    static func addTodoAndFetchListClosureToCombine(content: String, isDone: Bool = false)  -> AnyPublisher<[Todo], Error> {
        return Future { (promise: @escaping (Result<ListResponse, ApiError>) -> Void) in
            addATodoAndFetchTodos(title: content) { result in
                promise(result)
            }
        }
        .tryMap({ todoResponse in
            guard let todo = todoResponse.data else {
                throw ApiError.noContent
            }
            
            return todo
        })
        .mapError({ err in
            if let apiError = err as? ApiError {
                return apiError
            }
            
            return ApiError.unknown(err)
        })
        .eraseToAnyPublisher()
    }
    
    static func addTodoAndFetchListClosureToCombineNoError(content: String, isDone: Bool = false)  -> AnyPublisher<[Todo], Never> {
        return Future { (promise: @escaping (Result<ListResponse, ApiError>) -> Void) in
            addATodoAndFetchTodos(title: content) { result in
                promise(result)
            }
        }
        .map({ $0.data ?? [] })
        .replaceError(with: [])
        .eraseToAnyPublisher()
    }
    
    static func deleteTodosClosureToCombine(id: [Int])  -> AnyPublisher<[Todo], ApiError> {
        return Future { (promise: @escaping (Result<[Todo], ApiError>) -> Void) in
            deleteTodosClosure(id: id) { result in
                promise(result)
            }
        }
        .tryMap({ result in
            if result.isEmpty {
                throw ApiError.noContent
            } else {
                return result
            }
        })
        .mapError({ err in
            if let apiError = err as? ApiError {
                return apiError
            }
            
            return ApiError.unknown(err)
        })
        .eraseToAnyPublisher()
    }
}

// MARK: - Hepler
extension TodosAPI_Closure {
    private static func checkResponse(_ err: Error?, _ response: URLResponse?) -> ApiError? {
        if let err = err {
            return .unknown(err)
        }
        
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
    
    private static func parseJsonBaseData<T: Decodable>(data: Data, type: T.Type) -> Result<T, ApiError> {
        do {
            let response = try JSONDecoder().decode(T.self, from: data)
            
            if let baseList = response as? BaseListResponse<Todo>,
               let todos = baseList.data,
               todos.isEmpty {
                return .failure(.noContent)
            }
            
            return .success(response)
        } catch {
            return .failure(.decodingError)
        }
    }
}

 


