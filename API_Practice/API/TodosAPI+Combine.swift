//
//  TodosAPI+Combine.swift
//  API_Practice
//
//  Created by CatSlave on 6/6/24.
//

import Foundation
import MultipartForm
import Combine

extension TodosAPI_Combine {
    
    typealias ListResponse = BaseListResponse<Todo>
    typealias TodoResponse = BaseResponse<Todo>
    typealias ResultListData = Result<ListResponse, ApiError>
    typealias ResultTodoData = Result<TodoResponse, ApiError>
    
    static func fetchTodosResultType(page: Int = 1) -> AnyPublisher<ResultListData, Never> {
        
        guard let url = URL(baseUrl: baseUrl, optionUrl: "/todos", queryItems: ["page":"\(page)"]) else {
            // eraseToAnyPublisher : Publisher wrapping
            return Just(.failure(ApiError.notAllowedUrl)).eraseToAnyPublisher()
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue("application/json", forHTTPHeaderField: "accept") 
        
        return URLSession.shared.dataTaskPublisher(for: request)
            .map { (data: Data, response: URLResponse) -> ResultListData in
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    return .failure(.unknown(nil))
                }
                
                switch httpResponse.statusCode {
                case 401:
                    return .failure(.unauthorized)
              
                case 204:
                    return .failure(.noContent)
                    
                default: print("default")
                }
                
                if !(200...299).contains(httpResponse.statusCode) {
                    return .failure(.badStatus(code: httpResponse.statusCode))
                }
                
                do {
                    let listData = try JSONDecoder().decode(ListResponse.self, from: data)
                    
                    guard let todos = listData.data,
                          !todos.isEmpty else {
                        return .failure(ApiError.noContent)
                    }
                    
                    return .success(listData)
                } catch {
                    return .failure(ApiError.decodingError)
                }
            }
            .replaceError(with: .failure(ApiError.unknown(nil)))
            .eraseToAnyPublisher()
    }
    
    static func fetchTodos(page: Int = 1) -> AnyPublisher<ListResponse, ApiError> {
        
        guard let url = URL(baseUrl: baseUrl, optionUrl: "/todos", queryItems: ["page":"\(page)"]) else {
            // eraseToAnyPublisher : Publisher wrapping
            return Fail(error: ApiError.notAllowedUrl).eraseToAnyPublisher()
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue("application/json", forHTTPHeaderField: "accept")
        
        return URLSession.shared.dataTaskPublisher(for: request)
            .tryMap(checkResponse(task:))
            .decode(type: ListResponse.self, decoder: JSONDecoder())
            .tryMap(checkResponseType(decoded: ))
            .mapError(checkError(err:))
            .eraseToAnyPublisher()
    }
    
    static func addTodoByMultipart(content: String, isDone: Bool = false) -> AnyPublisher<TodoResponse, ApiError> {
        
        guard let url = URL(string: baseUrl + "/todos") else {
            return Fail(error: ApiError.notAllowedUrl).eraseToAnyPublisher()
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
        
        return getBaseResponse(urlRequest, TodoResponse.self)
    }
    
    static func addTodoByJson(content: String, isDone: Bool = false) -> AnyPublisher<TodoResponse, ApiError> {
        
        guard let url = URL(string: baseUrl + "/todos-json") else {
            return Fail(error: ApiError.notAllowedUrl).eraseToAnyPublisher()
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
            
            return Fail(error: ApiError.jsonEncoding).eraseToAnyPublisher()
        }
        
        return getBaseResponse(urlRequest, TodoResponse.self)
    }
    
    static func searchTodos(searchTerm: String, page: Int = 1) -> AnyPublisher<ListResponse, ApiError>{
        
        let queryItems = ["query": searchTerm, "page": "\(page)"]
        
        guard let url = URL(baseUrl: baseUrl, optionUrl: "/todos", queryItems: queryItems) else {
            return Fail(error: ApiError.notAllowedUrl).eraseToAnyPublisher()
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue("application/json", forHTTPHeaderField: "accept")
        
        
        return getBaseResponse(request, ListResponse.self)
    }

    static func searchTodo(id: Int) -> AnyPublisher<TodoResponse, ApiError> {
        
        guard let url = URL(string: baseUrl + "/todos" + "/\(id)") else {
            return Fail(error: ApiError.notAllowedUrl).eraseToAnyPublisher()
        }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "GET"
        urlRequest.addValue("application/json", forHTTPHeaderField: "accept")
        
        return getBaseResponse(urlRequest, TodoResponse.self)
    }
    
    static func editTodoEncoded(id: Int, content: String, isDone: Bool) -> AnyPublisher<TodoResponse, ApiError> {
        
        guard let url = URL(string: baseUrl + "/todos" + "/\(id)") else {
            return Fail(error: ApiError.notAllowedUrl).eraseToAnyPublisher()
        }
        
        let requestParams = ["title" : content, "is_done" : "\(isDone)"]
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "PUT"
        urlRequest.addValue("application/json", forHTTPHeaderField: "accept")
        urlRequest.addValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        urlRequest.percentEncodeParameters(parameters: requestParams)
        
        return getBaseResponse(urlRequest, TodoResponse.self)
    }
    
    static func editTodoByJson(id: Int, content: String, isDone: Bool) -> AnyPublisher<TodoResponse, ApiError> {
        
        guard let url = URL(string: baseUrl + "/todos-json" + "/\(id)") else {
            return Fail(error: ApiError.notAllowedUrl).eraseToAnyPublisher()
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
            return Fail(error: ApiError.jsonEncoding).eraseToAnyPublisher()
        }
        
        return getBaseResponse(urlRequest, TodoResponse.self)
    }
    
    static func deleteTodo(id: Int) -> AnyPublisher<TodoResponse, ApiError> {
        
        guard let url = URL(string: baseUrl + "/todos" + "/\(id)") else {
            return Fail(error: ApiError.notAllowedUrl).eraseToAnyPublisher()
        }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "DELETE"
        
        urlRequest.addValue("application/json", forHTTPHeaderField: "accept")
        
        return getBaseResponse(urlRequest, TodoResponse.self)
    }

    // MARK: - API 연쇄호출
    
    // failure이 있는 경우
    // 에러를 받아서 처리하는 메서드 추가
    static func addTodoAndFetchTodos(content: String, isDone: Bool = false) -> AnyPublisher<ListResponse, ApiError> {
        
        return self.addTodoByJson(content: content, isDone: isDone)
            .flatMap { _ in
                fetchTodos()
            }
            .mapError(checkError(err:))
            .eraseToAnyPublisher()
    }
    
    // failure이 없는 경우
    // 에러가 발생한 경우 내릴 값을 정해줌
    // flatMap : 1번 퍼블리셔에서 2번 퍼블리셔로 변경됨
    static func addTodoAndFetchTodosNoError(content: String, isDone: Bool = false) -> AnyPublisher<[Todo], Never> {
        
        return self.addTodoByJson(content: content, isDone: isDone)
            .flatMap { _ in
                fetchTodos()
            }
            // $0은 BaseListResponse<Todo>
            .compactMap({ $0.data })
            .replaceError(with: [])
            .eraseToAnyPublisher()
    }
    
    // SwitchToLatest
    // 스트림을 통해서 보내지는 값 중 마지막 값만 받고 싶을 때
    // switchToLatest : 가장 최근에 수신한 퍼블리셔를 받음
    // 헷갈린 점 : 단순 map을 통해서 내려갔으면 BaseResponse가 아닌가?
    // switchToLatest를 통해서 가장 최근에 수신한 퍼블리셔 BaseListResponse를 내려보냄
    static func addTodoAndFetchTodosNoErrorSwitchToLatest(content: String, isDone: Bool = false) -> AnyPublisher<[Todo], Never> {
        
        return self.addTodoByJson(content: content, isDone: isDone)
            .map { _ in
                fetchTodos()
            }
            .switchToLatest()
            .compactMap({ $0.data })
            .replaceError(with: [])
            .eraseToAnyPublisher()
    }
    
    static func addTodoAndFetchTodosSwitchToLatest(content: String, isDone: Bool = false) -> AnyPublisher<[Todo], ApiError> {
        
        return self.addTodoByJson(content: content, isDone: isDone)
            .map { _ in
                fetchTodos()
            }
            .switchToLatest()
            .compactMap({ $0.data })
            .mapError(checkError(err:))
            .eraseToAnyPublisher()
    }
    
    // MARK: - API 동시호출
    
    // Merge
    // 여러개의 퍼블리셔의 값을 각각 내려줌 (return type 단일 요소)
    static func deleteTodosMerge(selectedTodos: [Int]) -> AnyPublisher<Int, ApiError> {

        let apiCallObservables = selectedTodos.map { id -> AnyPublisher<Int?, ApiError> in
            return self.deleteTodo(id: id)
                .map { $0.data?.id }
                .eraseToAnyPublisher()
        }
        
        return Publishers.MergeMany(apiCallObservables)
            .compactMap { $0 }
            .eraseToAnyPublisher()
    }
    
    static func deleteTodosMergeNoError(selectedTodos: [Int]) -> AnyPublisher<Int, Never> {

        let apiCallObservables = selectedTodos.map { id -> AnyPublisher<Int?, Never> in
            return self.deleteTodo(id: id)
                .map { $0.data?.id }
                .replaceError(with: nil)
                .eraseToAnyPublisher()
        }
        
        return Publishers.MergeMany(apiCallObservables)
            .compactMap { $0 }
            .eraseToAnyPublisher()
    }
    
    // Zip
    // combine에서도 zip 기능이 있지만 매개변수로 받을 수 있는 최대 갯수는 4개
    // 초과되는 경우 해결방법은 zip을 중첩시켜서 사용하면 해결할 수 있다.
    // 예시 : zip3(zip1(publisher1, publisher2, publisher3), zip2(publisher4, publisher5, publisher6))
    // CombineExt 라이브러리에 있는 zip을 사용해서 편리하게 이용가능
    // 여러개의 퍼블리셔의 값을 하나로 내려줌 (return type 배열 요소)
    static func deleteTodosZip(selectedTodos: [Int]) -> AnyPublisher<[Int], ApiError> {

        let apiCallPublishers = selectedTodos.map { id -> AnyPublisher<Int?, ApiError> in
            return self.deleteTodo(id: id)
                .map { $0.data?.id }
                .eraseToAnyPublisher()
        }
        
        return apiCallPublishers.zip()
            .map({ $0.compactMap { $0 } })
            .eraseToAnyPublisher()
    }
    
    static func deleteTodosZipNoError(selectedTodos: [Int]) -> AnyPublisher<[Int], Never> {

        let apiCallPublishers = selectedTodos.map { id -> AnyPublisher<Int?, Never> in
            return self.deleteTodo(id: id)
                .map { $0.data?.id }
                .replaceError(with: nil)
                .eraseToAnyPublisher()
        }
        
        return apiCallPublishers.zip()
            .map({ $0.compactMap { $0 } })
            .eraseToAnyPublisher()
    }
    
    static func searchTodosMerge(todosId: [Int]) -> AnyPublisher<Todo, ApiError> {
        
        let apiCallPublishers = todosId.map { id -> AnyPublisher<Todo?, ApiError> in
            return searchTodo(id: id)
                .map { $0.data }
                .eraseToAnyPublisher()
        }
        
        return Publishers.MergeMany(apiCallPublishers)
            .compactMap { $0 }
            .eraseToAnyPublisher()
    }
    
    static func searchTodosMergeNoError(todosId: [Int]) -> AnyPublisher<Todo, Never> {
        
        let apiCallPublishers = todosId.map { id -> AnyPublisher<Todo?, Never> in
            return searchTodo(id: id)
                .map { $0.data }
                .replaceError(with: nil)
                .eraseToAnyPublisher()
        }
        
        return Publishers.MergeMany(apiCallPublishers)
            .compactMap { $0 }
            .eraseToAnyPublisher()
    }
    
    static func searchTodosZip(todosId: [Int]) -> AnyPublisher<[Todo], ApiError> {
        
        let apiCallPublishers = todosId.map { id -> AnyPublisher<Todo?, ApiError> in
            return searchTodo(id: id)
                .map { $0.data }
                .eraseToAnyPublisher()
        }
        
        return apiCallPublishers.zip()
            .map { $0.compactMap { $0 } }
            .eraseToAnyPublisher()
    }
    
    static func searchTodosZipNoError(todosId: [Int]) -> AnyPublisher<[Todo], Never> {
        
        let apiCallPublishers = todosId.map { id -> AnyPublisher<Todo?, Never> in
            return searchTodo(id: id)
                .map { $0.data }
                .replaceError(with: nil)
                .eraseToAnyPublisher()
        }
        
        return apiCallPublishers.zip()
            .map { $0.compactMap { $0 } }
            .eraseToAnyPublisher()
    }
    
}

// MARK: - Hepler
extension TodosAPI_Combine {
    
    private static func getBaseResponse<T:Decodable>(_ request: URLRequest,_ type: T.Type) -> AnyPublisher<T, ApiError> {
        return URLSession.shared.dataTaskPublisher(for: request)
            .tryMap(checkResponse(task:))
            .decode(type: T.self, decoder: JSONDecoder())
            .tryMap(checkResponseType(decoded: ))
            .mapError(checkError(err:))
            .eraseToAnyPublisher()
    }
    
    private static func checkResponse(task: (data: Data, response: URLResponse)) throws -> Data {
        
        guard let httpResponse = task.response as? HTTPURLResponse else {
            throw ApiError.unknown(nil)
        }
        
        switch httpResponse.statusCode {
        case 401:
            throw ApiError.unauthorized
      
        case 204:
            throw ApiError.noContent
            
        default: print("default")
        }
        
        if !(200...299).contains(httpResponse.statusCode) {
            throw ApiError.badStatus(code: httpResponse.statusCode)
        }
        
        return task.data
    }
    
    private static func checkResponseType<T:Decodable>(decoded: T) throws -> T {
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
    
    private static func checkError(err: Error) -> ApiError {
        if let apiError = err as? ApiError {
            return apiError
        }
        
        if let _ = err as? DecodingError {
            return ApiError.decodingError
        }
        
        return ApiError.unknown(err)
    }
    
    private static func checkContent(response: ListResponse) -> ResultListData {
        guard let todos = response.data,
              !todos.isEmpty else {
            return .failure(.noContent)
        }
        return .success(response)
    }
}






