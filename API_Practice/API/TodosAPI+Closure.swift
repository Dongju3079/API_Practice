//
//  TodosAPI+Closure.swift
//  API_Practice
//
//  Created by CatSlave on 6/4/24.
//

import Foundation
import MultipartForm

extension TodosAPI_Closure {
    
    static func fetchTodosClosure(page: Int = 1, completion: @escaping (Result<BaseListResponse<Todo>, ApiError>) -> Void) {
        
        guard let url = URL(baseUrl: baseUrl, optionUrl: "/todos", queryItems: ["page":"\(page)"]) else {
            completion(.failure(.unknown(nil)))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue("application/json", forHTTPHeaderField: "accept")
        
        URLSession.shared.dataTask(with: request) { data, response, err in
            if let err = err {
                return completion(.failure(.unknown(err)))
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                return completion(.failure(.unknown(nil)))
            }
            
            switch httpResponse.statusCode {
            case 401:
                return completion(.failure(.unknown(nil)))
            default:
                print("default")
            }
            
            if !(200...299).contains(httpResponse.statusCode) {
                return completion(.failure(ApiError.badStatus(code: httpResponse.statusCode)))
            }
            
            if let jsonData = data {
                switch self.parseJsonBaseList(data: jsonData) {
                case .success(let listData):
                    completion(.success(listData))
                case .failure(let err):
                    completion(.failure(err))
                }
            }
        }.resume()

    }
    
    static func addTodoClosureByMultipart(content: String,
                               isDone: Bool = false,
                               completion: @escaping (Result<BaseResponse<Todo>, ApiError>) -> Void) {
        
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
            if let err = err {
                return completion(.failure(.unknown(err)))
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                return completion(.failure(.unknown(nil)))
            }
            
            switch httpResponse.statusCode {
            case 401:
                return completion(.failure(.unknown(nil)))
            default:
                print("default")
            }
            
            if !(200...299).contains(httpResponse.statusCode) {
                return completion(.failure(ApiError.badStatus(code: httpResponse.statusCode)))
            }
            
            if let jsonData = data {
                switch self.parseJsonBase(data: jsonData) {
                case .success(let listData):
                    completion(.success(listData))
                case .failure(let err):
                    completion(.failure(err))
                }
            }
        }.resume()

    }
    
    static func addTodoClosureByJson(content: String,
                               isDone: Bool = false,
                               completion: @escaping (Result<BaseResponse<Todo>, ApiError>) -> Void) {
        
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
            if let err = err {
                return completion(.failure(.unknown(err)))
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                return completion(.failure(.unknown(nil)))
            }
            
            switch httpResponse.statusCode {
            case 401:
                return completion(.failure(.unknown(nil)))
            default:
                print("default")
            }
            
            if !(200...299).contains(httpResponse.statusCode) {
                return completion(.failure(ApiError.badStatus(code: httpResponse.statusCode)))
            }
            
            if let jsonData = data {
                switch self.parseJsonBase(data: jsonData) {
                case .success(let listData):
                    completion(.success(listData))
                case .failure(let err):
                    completion(.failure(err))
                }
            }
        }.resume()

    }
    
    static func searchTodosClosure(searchTerm: String,
                                   page: Int = 1,
                                   completion: @escaping (Result<BaseListResponse<Todo>, ApiError>) -> Void) {
        
        let queryItems = ["query": searchTerm, "page": "\(page)"]
        
        guard let url = URL(baseUrl: baseUrl, optionUrl: "/todos", queryItems: queryItems) else {
            completion(.failure(.unknown(nil)))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue("application/json", forHTTPHeaderField: "accept")
        
        
        URLSession.shared.dataTask(with: request) { data, response, err in
            if let err = err {
                return completion(.failure(.unknown(err)))
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                return completion(.failure(.unknown(nil)))
            }
            
            switch httpResponse.statusCode {
            case 401:
                return completion(.failure(.unknown(nil)))
            default:
                print("default")
            }
            
            if !(200...299).contains(httpResponse.statusCode) {
                return completion(.failure(ApiError.badStatus(code: httpResponse.statusCode)))
            }
            
            if let jsonData = data {
                switch self.parseJsonBaseList(data: jsonData) {
                case .success(let listData):
                    completion(.success(listData))
                case .failure(let err):
                    completion(.failure(err))
                }
            }
        }.resume()

    }
    
    static func searchTodoClosure(id: Int,
                                  completion: @escaping (Result<BaseResponse<Todo>, ApiError>) -> Void) {
        
        guard let url = URL(string: baseUrl + "/todos" + "/\(id)") else {
            return completion(.failure(.notAllowedUrl))
        }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "GET"
        urlRequest.addValue("application/json", forHTTPHeaderField: "accept")
        
        URLSession.shared.dataTask(with: urlRequest) { data, response, err in
            if let err = err {
                return completion(.failure(.unknown(err)))
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                return completion(.failure(.unknown(nil)))
            }
            
            switch httpResponse.statusCode {
            case 401:
                return completion(.failure(.unknown(nil)))
            default:
                print("default")
            }
            
            if !(200...299).contains(httpResponse.statusCode) {
                return completion(.failure(ApiError.badStatus(code: httpResponse.statusCode)))
            }
            
            if let jsonData = data {
                switch self.parseJsonBase(data: jsonData) {
                case .success(let listData):
                    completion(.success(listData))
                case .failure(let err):
                    completion(.failure(err))
                }
            }
        }.resume()

    }
    
    static func editTodoClosureEncoded(id: Int,
                                content: String,
                                isDone: Bool,
                                completion: @escaping (Result<BaseResponse<Todo>, ApiError>) -> Void) {
        
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
            if let err = err {
                return completion(.failure(.unknown(err)))
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                return completion(.failure(.unknown(nil)))
            }
            
            switch httpResponse.statusCode {
            case 401:
                return completion(.failure(.unknown(nil)))
            default:
                print("default")
            }
            
            if !(200...299).contains(httpResponse.statusCode) {
                return completion(.failure(ApiError.badStatus(code: httpResponse.statusCode)))
            }
            
            if let jsonData = data {
                switch self.parseJsonBase(data: jsonData) {
                case .success(let listData):
                    completion(.success(listData))
                case .failure(let err):
                    completion(.failure(err))
                }
            }
        }.resume()

    }
    
    static func editTodoClosureByJson(id: Int,
                                content: String,
                                isDone: Bool,
                                completion: @escaping (Result<BaseResponse<Todo>, ApiError>) -> Void) {
        
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
            if let err = err {
                return completion(.failure(.unknown(err)))
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                return completion(.failure(.unknown(nil)))
            }
            
            switch httpResponse.statusCode {
            case 401:
                return completion(.failure(.unknown(nil)))
            default:
                print("default")
            }
            
            if !(200...299).contains(httpResponse.statusCode) {
                return completion(.failure(ApiError.badStatus(code: httpResponse.statusCode)))
            }
            
            if let jsonData = data {
                switch self.parseJsonBase(data: jsonData) {
                case .success(let listData):
                    completion(.success(listData))
                case .failure(let err):
                    completion(.failure(err))
                }
            }
        }.resume()

    }
    
    static func deleteTodoClosure(id: Int,
                                  completion: @escaping (Result<BaseResponse<Todo>, ApiError>) -> Void) {
        
        guard let url = URL(string: baseUrl + "/todos" + "/\(id)") else {
            return completion(.failure(.notAllowedUrl))
        }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "DELETE"
        
        urlRequest.addValue("application/json", forHTTPHeaderField: "accept")
        
        URLSession.shared.dataTask(with: urlRequest) { data, response, err in
            if let err = err {
                return completion(.failure(.unknown(err)))
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                return completion(.failure(.unknown(nil)))
            }
            
            switch httpResponse.statusCode {
            case 401:
                return completion(.failure(.unknown(nil)))
            default:
                print("default")
            }
            
            if !(200...299).contains(httpResponse.statusCode) {
                return completion(.failure(ApiError.badStatus(code: httpResponse.statusCode)))
            }
            
            if let jsonData = data {
                switch self.parseJsonBase(data: jsonData) {
                case .success(let listData):
                    completion(.success(listData))
                case .failure(let err):
                    completion(.failure(err))
                }
            }
        }.resume()

    }
    
    static func deleteTodosClosure(id: [Int], completion: @escaping (Result<[Todo], ApiError>) -> Void) {
        
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
                case .failure(let failure):
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
