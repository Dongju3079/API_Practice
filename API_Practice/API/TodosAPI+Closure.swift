//
//  TodosAPI+Closure.swift
//  API_Practice
//
//  Created by CatSlave on 6/4/24.
//

import Foundation
import MultipartForm

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
                                      completion: @escaping (Result<BaseListResponse<Todo>, ApiError>) -> Void){
        self.addTodoClosureByJson(content: title, isDone: isDone) { result in
            switch result {
            case .success(let todoResponse):
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
