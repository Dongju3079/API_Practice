//
//  TodosAPI+Rx.swift
//  API_Practice
//
//  Created by CatSlave on 6/4/24.
//

import Foundation
import MultipartForm
import RxSwift
import RxCocoa
import RxRelay

extension TodosAPI_Rx {
    
    typealias ListResponse = BaseListResponse<Todo>
    typealias TodoResponse = BaseResponse<Todo>
    typealias ResultListData = Result<ListResponse, ApiError>
    typealias ResultTodoData = Result<TodoResponse, ApiError>
    
    static func fetchTodosRxAddErrorTask(page: Int = 1) -> Observable<ListResponse> {
        
        guard let url = URL(baseUrl: baseUrl, optionUrl: "/todos", queryItems: ["page":"\(page)"]) else {
            return .error(ApiError.notAllowedUrl)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue("application/json", forHTTPHeaderField: "accept")
        
        return URLSession.shared.rx
            .response(request: request)
            .map { (response: HTTPURLResponse, data: Data) -> Data in
                return data//try JSONDecoder().decode(ListResponse.self, from: data)
            }
            .decode(type: ListResponse.self, decoder: JSONDecoder())
            .map({ response in
                guard let todos = response.data,
                      !todos.isEmpty else {
                    throw ApiError.noContent
                }
                return response
            })
            .catch { err in
                if let err = err as? DecodingError {
                    throw err
                }
                
                if let error = err as? ApiError {
                    throw error
                }
                
                throw ApiError.unknown(err)
            }
    }
    
    static func fetchTodosRx(page: Int = 1) -> Observable<ResultListData> {
        
        guard let url = URL(baseUrl: baseUrl, optionUrl: "/todos", queryItems: ["page":"\(page)"]) else {
            return .just(.failure(.notAllowedUrl))
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue("application/json", forHTTPHeaderField: "accept")
        
        return getBaseResponseResultType(request, ListResponse.self)
    }
    
    static func addTodoRxByMultipart(content: String, isDone: Bool = false) -> Observable<ResultTodoData> {
        
        guard let url = URL(string: baseUrl + "/todos") else {
            return .just(.failure(.notAllowedUrl))
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
        
        return getBaseResponseResultType(urlRequest, TodoResponse.self)
    }
    
    static func addTodoRxByJson(content: String, isDone: Bool = false) -> Observable<ResultTodoData> {
        
        guard let url = URL(string: baseUrl + "/todos-json") else {
            return .just(.failure(.notAllowedUrl))
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
            
            return .just(.failure(.jsonEncoding))
        }
        
        return getBaseResponseResultType(urlRequest, TodoResponse.self)
    }
    
    static func searchTodosRx(searchTerm: String, page: Int = 1) -> Observable<ListResponse> {
        
        print("테스트 searchTerm_api : \(searchTerm)")
        
        let queryItems = ["query": searchTerm, "page": "\(page)"]
        
        guard let url = URL(baseUrl: baseUrl, optionUrl: "/todos/search", queryItems: queryItems) else {
            return .error(ApiError.notAllowedUrl)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue("application/json", forHTTPHeaderField: "accept")
        
        
        return getBaseResponse(request, ListResponse.self)
    }
    
    static func searchTodoRx(id: Int) -> Observable<TodoResponse> {
        
        guard let url = URL(string: baseUrl + "/todos" + "/\(id)") else {
            return .error(ApiError.notAllowedUrl)
        }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "GET"
        urlRequest.addValue("application/json", forHTTPHeaderField: "accept")
        
        return URLSession.shared.rx
            .response(request: urlRequest)
            .map { (response: HTTPURLResponse, data: Data) in
                do {
                    let todoData = try JSONDecoder().decode(TodoResponse.self, from: data)
                    return todoData
                } catch {
                    throw ApiError.decodingError
                }
            }
    }
    
    static func editTodoRxEncoded(id: Int, content: String, isDone: Bool) -> Observable<TodoResponse> {
        
        guard let url = URL(string: baseUrl + "/todos" + "/\(id)") else {
            return .error(ApiError.notAllowedUrl)
        }
        
        let requestParams = ["title" : content, "is_done" : "\(isDone)"]
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "PUT"
        urlRequest.addValue("application/json", forHTTPHeaderField: "accept")
        urlRequest.addValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        urlRequest.percentEncodeParameters(parameters: requestParams)
        
        return getBaseResponse(urlRequest, TodoResponse.self)
    }
    
    static func editTodoRxByJson(id: Int, content: String, isDone: Bool) -> Observable<ResultTodoData> {
        
        guard let url = URL(string: baseUrl + "/todos-json" + "/\(id)") else {
            return .just(.failure(.notAllowedUrl))
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
            return Observable.just(.failure(.jsonEncoding))
        }
        
        return getBaseResponseResultType(urlRequest, TodoResponse.self)
    }
    
    static func deleteTodoRx(id: Int) -> Observable<TodoResponse> {
        
        guard let url = URL(string: baseUrl + "/todos" + "/\(id)") else {
            return Observable.error(ApiError.notAllowedUrl)
        }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "DELETE"
        
        urlRequest.addValue("application/json", forHTTPHeaderField: "accept")
        
        return URLSession.shared.rx
            .response(request: urlRequest)
            .map { (response: HTTPURLResponse, data: Data) in
                if let err = checkResponse(data, response) {
                    throw err
                }
                
                return data
            }
            .decode(type: TodoResponse.self, decoder: JSONDecoder())
            .catch { err in
                if let apiError = err as? ApiError {
                    throw apiError
                }
                
                if let decodingError = err as? DecodingError {
                    throw decodingError
                }
                
                throw err
            }
    }
    
    // MARK: - API 연쇄 호출
    static func addTodoAndFetchTodos(content: String, isDone: Bool = false) -> Observable<ListResponse> {
        
        return addTodoRxByJson(content: content, isDone: isDone)
            .flatMapLatest { _ in
                fetchTodosRxAddErrorTask()
            }
            .share(replay: 1)
    }
    
    // MARK: - API 동시 호출
    
    static func deleteTodosRxZip(selectedTodos: [Int]) -> Observable<[Int]> {
        
        let apiCallObservables = selectedTodos.map { id -> Observable<Int?> in
            return self.deleteTodoRx(id: id)
                .map { $0.data?.id }
                .catchAndReturn(nil)
        }
        
        return Observable.zip(apiCallObservables)
            .map { $0.compactMap { $0 } }
    }
    
    static func deleteTodosRxMerge(selectedTodos: [Int]) -> Observable<Int> {
        
        let apiCallObservables = selectedTodos.map { id -> Observable<Int?> in
            return self.deleteTodoRx(id: id)
                .map { $0.data?.id }
                .catchAndReturn(nil)
        }
        
        return Observable.merge(apiCallObservables)
            .compactMap { $0 }
    }
    
    static func searchTodosRx(todosId: [Int]) -> Observable<[Todo]> {
        
        let apiCallObservables = todosId.map { id -> Observable<Todo?> in
            
            return self.searchTodoRx(id: id)
                .map { $0.data }
                .catchAndReturn(nil)
        }
        
        return Observable.zip(apiCallObservables)
            .map { $0.compactMap { $0 } }
    }
    
}

// MARK: - Rx To Async
extension TodosAPI_Rx {
    static func fetchTodosWithErrorRxToAsync() async throws -> ListResponse {
        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<ListResponse, Error>) in
            
            var disposable : Disposable? = nil
            
            disposable = fetchTodosRxAddErrorTask()
                .subscribe(
                    onNext: { data in
                        continuation.resume(returning: data)
                    },
                    onError: { err in
                        print("onError")
                        continuation.resume(throwing: err)
                    },
                    onCompleted: {
                        print("onCompleted")
                        disposable?.dispose()
                    },
                    onDisposed: {
                        print("onDisposed")
                    }
                )
        }
    }
}

// MARK: - Hepler
extension TodosAPI_Rx {
    
    // MARK: - Return Result Type
    /// UrlSession을 통해서 받은 데이터 값을 T 모델로 파싱
    /// - Parameters:
    ///   - request: 요청 값
    ///   - type: 파싱하고자 하는 모델
    /// - Returns: Observable<T, Error>
    private static func getBaseResponseResultType<T: Decodable>(_ request: URLRequest, _ type: T.Type) -> Observable<Result<T, ApiError>> {
        return URLSession.shared.rx
            .response(request: request)
            .map { (response: HTTPURLResponse, data: Data) -> Data in//-> Result<T, ApiError> in
                if let err = checkResponse(data, response) {
                    throw err// return .failure(err)
                }
                
                return data // self.parseJsonBase(data, type)
            }
            .decode(type: type, decoder: JSONDecoder())
            .map { .success($0) }
            .catch { err -> Observable<Result<T, ApiError>> in
                if let _ = err as? DecodingError {
                    return .just(.failure(.decodingError))
                }
                
                if let error = err as? ApiError {
                    return .just(.failure(error))
                }
                
                return .just(.failure(.unknown(err)))
            }
    }
    
    // MARK: - Return Single Type
    private static func getBaseResponse<T: Decodable>(_ request: URLRequest, _ type: T.Type) -> Observable<T> {
        return URLSession.shared.rx
            .response(request: request)
            .map { (response: HTTPURLResponse, data: Data) -> Data in//-> Result<T, ApiError> in
                if let err = checkResponse(data, response) {
                    throw err
                }
                
                return data
            }
            .decode(type: type, decoder: JSONDecoder())
            .catch { err in
                if let _ = err as? DecodingError {
                    throw TodosAPI_Rx.ApiError.decodingError
                }
                
                if let _ = err as? ApiError {
                    throw err
                }
                
                throw TodosAPI_Rx.ApiError.unknown(err)
            }
    }
    
    /// 응답결과를 내부 조건에 따라서 ApiError로 return
    /// - Parameter response: UrlSession 응답값
    /// - Returns: ApiError?
    private static func checkResponse(_ data: Data, _ response: URLResponse) -> ApiError? {
        
        guard let httpResponse = response as? HTTPURLResponse else {
            return .unknown(nil)
        }
        
        switch httpResponse.statusCode {
        case 401:
            return .unauthorized
        case 422:
            guard let responseError = try? JSONDecoder().decode(ErrorResponse.self, from: data) else {
                
                return ApiError.decodingError
            }
            return ApiError.errResponseFromServer(responseError)
      
        case 204:
            return .noContent
            
        default: print("default")
        }
        
        if !(200...299).contains(httpResponse.statusCode) {
            return .badStatus(code: httpResponse.statusCode)
        }
        
        return nil
    }
}


