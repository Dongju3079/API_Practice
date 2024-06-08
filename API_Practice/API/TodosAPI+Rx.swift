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
    
    static func fetchTodosRxAddErrorTask(page: Int = 1) -> Observable<BaseListResponse<Todo>> {
        
        guard let url = URL(baseUrl: baseUrl, optionUrl: "/todos", queryItems: ["page":"\(page)"]) else {
            return Observable.error(ApiError.notAllowedUrl)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue("application/json", forHTTPHeaderField: "accept")
        
        return URLSession.shared.rx
            .response(request: request)
            .map { (response: HTTPURLResponse, data: Data) -> BaseListResponse<Todo> in
                return try JSONDecoder().decode(BaseListResponse<Todo>.self, from: data)
            }
            .map({ response in
                guard let todos = response.data,
                      !todos.isEmpty else {
                    throw ApiError.noContent
                }
                return response
            })
            .catch { err in
                if let error = err as? ApiError {
                    throw error
                } else {
                    throw ApiError.unknown(err)
                }
            }
    }
    
    static func fetchTodosRx(page: Int = 1) -> Observable<Result<BaseListResponse<Todo>, ApiError>> {
        
        guard let url = URL(baseUrl: baseUrl, optionUrl: "/todos", queryItems: ["page":"\(page)"]) else {
            return Observable.just(.failure(.notAllowedUrl))
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue("application/json", forHTTPHeaderField: "accept")
        
        return getBaseListResponse(request)
    }
    
    static func addTodoAndFetchTodos(content: String, isDone: Bool = false) -> Observable<[Todo]> {
        
        return addTodoRxByJson(content: content, isDone: isDone)
            .flatMapLatest { _ in
                fetchTodosRxAddErrorTask()
            }
            .compactMap { $0.data }
            .catchAndReturn([])
            .share(replay: 1)
    }
    
    static func addTodoRxByMultipart(content: String, isDone: Bool = false) -> Observable<Result<BaseResponse<Todo>, ApiError>> {
        
        guard let url = URL(string: baseUrl + "/todos") else {
            return Observable.just(.failure(.notAllowedUrl))
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
        
        return getBaseResponse(urlRequest)
    }
    
    static func addTodoRxByJson(content: String, isDone: Bool = false) -> Observable<Result<BaseResponse<Todo>, ApiError>> {
        
        guard let url = URL(string: baseUrl + "/todos-json") else {
            return Observable.just(.failure(.notAllowedUrl))
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
            
            return Observable.just(.failure(.jsonEncoding))
        }
        
        return getBaseResponse(urlRequest)
    }
    
    static func searchTodosRx(searchTerm: String, page: Int = 1) -> Observable<Result<BaseResponse<Todo>, ApiError>> {
        
        let queryItems = ["query": searchTerm, "page": "\(page)"]
        
        guard let url = URL(baseUrl: baseUrl, optionUrl: "/todos", queryItems: queryItems) else {
            return Observable.just(.failure(.notAllowedUrl))
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue("application/json", forHTTPHeaderField: "accept")
        
        
        return getBaseResponse(request)
    }
    
    static func searchTodoRx(id: Int) -> Observable<BaseResponse<Todo>> {
        
        guard let url = URL(string: baseUrl + "/todos" + "/\(id)") else {
            return Observable.error(ApiError.notAllowedUrl)
        }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "GET"
        urlRequest.addValue("application/json", forHTTPHeaderField: "accept")
        
        return URLSession.shared.rx
            .response(request: urlRequest)
            .map { (response: HTTPURLResponse, data: Data) in
                do {
                    let todoData = try JSONDecoder().decode(BaseResponse<Todo>.self, from: data)
                    return todoData
                } catch {
                    throw ApiError.decodingError
                }
            }
    }
    
    
    static func editTodoRxEncoded(id: Int, content: String, isDone: Bool) -> Observable<Result<BaseResponse<Todo>, ApiError>> {
        
        guard let url = URL(string: baseUrl + "/todos" + "/\(id)") else {
            return Observable.just(.failure(.notAllowedUrl))
        }
        
        let requestParams = ["title" : content, "is_done" : "\(isDone)"]
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "PUT"
        urlRequest.addValue("application/json", forHTTPHeaderField: "accept")
        urlRequest.addValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        urlRequest.percentEncodeParameters(parameters: requestParams)
        
        return getBaseResponse(urlRequest)
    }
    
    static func editTodoRxByJson(id: Int, content: String, isDone: Bool) -> Observable<Result<BaseResponse<Todo>, ApiError>> {
        
        guard let url = URL(string: baseUrl + "/todos-json" + "/\(id)") else {
            return Observable.just(.failure(.notAllowedUrl))
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
        
        return getBaseResponse(urlRequest)
    }
    
    static func deleteTodoRx(id: Int) -> Observable<BaseResponse<Todo>> {
        
        guard let url = URL(string: baseUrl + "/todos" + "/\(id)") else {
            return Observable.error(ApiError.notAllowedUrl)
        }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "DELETE"
        
        urlRequest.addValue("application/json", forHTTPHeaderField: "accept")
        
        return URLSession.shared.rx
            .response(request: urlRequest)
            .map { (response: HTTPURLResponse, data: Data) in
                do {
                    let listData = try JSONDecoder().decode(BaseResponse<Todo>.self, from: data)
                    return listData
                } catch {
                    throw ApiError.decodingError
                }
            }
    }
    
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

// MARK: - Hepler
extension TodosAPI_Rx {
    static private func getBaseListResponse(_ request: URLRequest) -> Observable<Result<BaseListResponse<Todo>, ApiError>> {
        return URLSession.shared.rx
            .response(request: request)
            .map { (response: HTTPURLResponse, data: Data) in
                switch self.parseJsonBaseList(data: data) {
                case .success(let listData):
                    print("파싱 성공")
                        return .success(listData)
                case .failure(let err):
                    print("파싱 실패")
                        return .failure(err)
                }
            }
    }
    
    static private func getBaseResponse(_ request: URLRequest) -> Observable<Result<BaseResponse<Todo>, ApiError>> {
        return URLSession.shared.rx
            .response(request: request)
            .map { (response: HTTPURLResponse, data: Data) in
                switch self.parseJsonBase(data: data) {
                case .success(let listData):
                    print("파싱 성공")
                        return .success(listData)
                case .failure(let err):
                    print("파싱 실패")
                        return .failure(err)
                }
            }
    }
    
    private static func parseJsonBaseList(data: Data) -> Result<BaseListResponse<Todo>, ApiError> {
        do {
            let listData = try JSONDecoder().decode(BaseListResponse<Todo>.self, from: data)
            
            guard let todos = listData.data,
                  !todos.isEmpty else {
                return .failure(.noContent)
            }
            
            return .success(listData)
        } catch {
            return .failure(.decodingError)
        }
    }
    
    private static func parseJsonBase(data: Data) -> Result<BaseResponse<Todo>, ApiError> {
        do {
            let listData = try JSONDecoder().decode(BaseResponse<Todo>.self, from: data)
            return .success(listData)
        } catch {
            return .failure(.decodingError)
        }
    }
}


