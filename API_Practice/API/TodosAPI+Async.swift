//
//  TodosAPI+Async.swift
//  API_Practice
//
//  Created by CatSlave on 6/10/24.
//

import Foundation
import MultipartForm
import Combine



extension TodosAPI_Async {
    
    typealias ListResponse = BaseListResponse<Todo>
    typealias TodoResponse = BaseResponse<Todo>
    typealias ResultListData = Result<ListResponse, ApiError>
    typealias ResultTodoData = Result<TodoResponse, ApiError>
    
    static func fetchTodosResultType(page: Int = 1) async -> ResultListData {
        
        guard let url = URL(baseUrl: baseUrl, optionUrl: "/todos", queryItems: ["page":"\(page)"]) else {
            // eraseToAnyPublisher : Publisher wrapping
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
    
        // 리턴 앞에 throws가 있어서 do, catch 없이 사용하더라도 에러가 던져짐
        // 단, 단순 에러를 던질 때 사용
        // 에러를 가공해서 보내야 한다면 do, catch 를 사용해야 함
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
    
//    private static func decodeResponse
    
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
        
        let addTodoResponse = try await addTodoByJson(content: content)
        let fetchTodoResponse = try await fetchTodos()
        
        guard let todos = fetchTodoResponse.data else {
            throw ApiError.noContent
        }
        
        return todos
    }
    
    static func addTodoAndFetchTodosNoError(content: String) async -> [Todo] {
        
        do {
            let addTodoResponse = try await addTodoByJson(content: content)
            let fetchTodoResponse = try await fetchTodos()
            
            guard let todos = fetchTodoResponse.data else {
                return []
            }
            return todos
        } catch {
            return []
        }
    }

    // Merge
    // 여러개의 퍼블리셔의 값을 각각 내려줌 (return type 단일 요소)
//    static func deleteTodosMerge(selectedTodos: [Int]) -> AnyPublisher<Int, ApiError> {
//
//        let apiCallObservables = selectedTodos.map { id -> AnyPublisher<Int?, ApiError> in
//            return self.deleteTodo(id: id)
//                .map { $0.data?.id }
//                .eraseToAnyPublisher()
//        }
//        
//        return Publishers.MergeMany(apiCallObservables)
//            .compactMap { $0 }
//            .eraseToAnyPublisher()
//    }
//    
//    static func deleteTodosMergeNoError(selectedTodos: [Int]) -> AnyPublisher<Int, Never> {
//
//        let apiCallObservables = selectedTodos.map { id -> AnyPublisher<Int?, Never> in
//            return self.deleteTodo(id: id)
//                .map { $0.data?.id }
//                .replaceError(with: nil)
//                .eraseToAnyPublisher()
//        }
//        
//        return Publishers.MergeMany(apiCallObservables)
//            .compactMap { $0 }
//            .eraseToAnyPublisher()
//    }
    
    // Zip
    // combine에서도 zip 기능이 있지만 매개변수로 받을 수 있는 최대 갯수는 4개
    // 초과되는 경우 해결방법은 zip을 중첩시켜서 사용하면 해결할 수 있다.
    // 예시 : zip3(zip1(publisher1, publisher2, publisher3), zip2(publisher4, publisher5, publisher6))
    // CombineExt 라이브러리에 있는 zip을 사용해서 편리하게 이용가능
    // 여러개의 퍼블리셔의 값을 하나로 내려줌 (return type 배열 요소)
//    static func deleteTodosZip(selectedTodos: [Int]) -> AnyPublisher<[Int], ApiError> {
//
//        let apiCallPublishers = selectedTodos.map { id -> AnyPublisher<Int?, ApiError> in
//            return self.deleteTodo(id: id)
//                .map { $0.data?.id }
//                .eraseToAnyPublisher()
//        }
//        
//        return apiCallPublishers.zip()
//            .map({ $0.compactMap { $0 } })
//            .eraseToAnyPublisher()
//    }
//    
//    static func deleteTodosZipNoError(selectedTodos: [Int]) -> AnyPublisher<[Int], Never> {
//
//        let apiCallPublishers = selectedTodos.map { id -> AnyPublisher<Int?, Never> in
//            return self.deleteTodo(id: id)
//                .map { $0.data?.id }
//                .replaceError(with: nil)
//                .eraseToAnyPublisher()
//        }
//        
//        return apiCallPublishers.zip()
//            .map({ $0.compactMap { $0 } })
//            .eraseToAnyPublisher()
//    }
//    
//    static func searchTodosMerge(todosId: [Int]) -> AnyPublisher<Todo, ApiError> {
//        
//        let apiCallPublishers = todosId.map { id -> AnyPublisher<Todo?, ApiError> in
//            return searchTodo(id: id)
//                .map { $0.data }
//                .eraseToAnyPublisher()
//        }
//        
//        return Publishers.MergeMany(apiCallPublishers)
//            .compactMap { $0 }
//            .eraseToAnyPublisher()
//    }
//    
//    static func searchTodosMergeNoError(todosId: [Int]) -> AnyPublisher<Todo, Never> {
//        
//        let apiCallPublishers = todosId.map { id -> AnyPublisher<Todo?, Never> in
//            return searchTodo(id: id)
//                .map { $0.data }
//                .replaceError(with: nil)
//                .eraseToAnyPublisher()
//        }
//        
//        return Publishers.MergeMany(apiCallPublishers)
//            .compactMap { $0 }
//            .eraseToAnyPublisher()
//    }
//    
//    static func searchTodosZip(todosId: [Int]) -> AnyPublisher<[Todo], ApiError> {
//        
//        let apiCallPublishers = todosId.map { id -> AnyPublisher<Todo?, ApiError> in
//            return searchTodo(id: id)
//                .map { $0.data }
//                .eraseToAnyPublisher()
//        }
//        
//        return apiCallPublishers.zip()
//            .map { $0.compactMap { $0 } }
//            .eraseToAnyPublisher()
//    }
//    
//    static func searchTodosZipNoError(todosId: [Int]) -> AnyPublisher<[Todo], Never> {
//        
//        let apiCallPublishers = todosId.map { id -> AnyPublisher<Todo?, Never> in
//            return searchTodo(id: id)
//                .map { $0.data }
//                .replaceError(with: nil)
//                .eraseToAnyPublisher()
//        }
//        
//        return apiCallPublishers.zip()
//            .map { $0.compactMap { $0 } }
//            .eraseToAnyPublisher()
//    }
    
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




