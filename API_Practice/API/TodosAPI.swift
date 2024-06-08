//
//  NetworkManager.swift
//  API_Practice
//
//  Created by CatSlave on 5/31/24.
//

import Foundation

enum TodosAPI_Closure {
    static let baseUrl = "https://phplaravel-574671-2962113.cloudwaysapps.com/api/v2"
    
    enum ApiError: Error {
        case noContent
        case decodingError
        case jsonEncoding
        case unauthorized
        case notAllowedUrl
        case badStatus(code: Int)
        case errResponseFromServer(_ errResponse: ErrorResponse?)
        case unknown(_ err: Error?)
        
        var info : String {
            switch self {
            case .noContent :           return "데이터가 없습니다."
            case .decodingError :       return "디코딩 에러입니다."
            case .jsonEncoding :        return "유효한 json 형식이 아닙니다."
            case .unauthorized :        return "인증되지 않은 사용자 입니다."
            case .notAllowedUrl :       return "올바른 URL 형식이 아닙니다."
            case let .badStatus(code):  return "에러 상태코드 : \(code)"
            case .errResponseFromServer(let errResponse): return errResponse?.message ?? ""
            case .unknown(let err):     return "알 수 없는 에러입니다 \n \(err)"
            }
        }
    }
    
}

enum TodosAPI_Rx {
    static let baseUrl = "https://phplaravel-574671-2962113.cloudwaysapps.com/api/v2"
    
    enum ApiError: Error {
        case noContent
        case decodingError
        case jsonEncoding
        case unauthorized
        case notAllowedUrl
        case badStatus(code: Int)
        case errResponseFromServer(_ errResponse: ErrorResponse?)
        case unknown(_ err: Error?)
        
        var info : String {
            switch self {
            case .noContent :           return "데이터가 없습니다."
            case .decodingError :       return "디코딩 에러입니다."
            case .jsonEncoding :        return "유효한 json 형식이 아닙니다."
            case .unauthorized :        return "인증되지 않은 사용자 입니다."
            case .notAllowedUrl :       return "올바른 URL 형식이 아닙니다."
            case let .badStatus(code):  return "에러 상태코드 : \(code)"
            case .errResponseFromServer(let errResponse): return errResponse?.message ?? ""
            case .unknown(let err):     return "알 수 없는 에러입니다 \n \(err)"
            }
        }
    }
    
}

enum TodosAPI_Combine {
    static let baseUrl = "https://phplaravel-574671-2962113.cloudwaysapps.com/api/v2"
    
    enum ApiError: Error {
        case noContent
        case decodingError
        case jsonEncoding
        case unauthorized
        case notAllowedUrl
        case badStatus(code: Int)
        case errResponseFromServer(_ errResponse: ErrorResponse?)
        case unknown(_ err: Error?)
        
        var info : String {
            switch self {
            case .noContent :           return "데이터가 없습니다."
            case .decodingError :       return "디코딩 에러입니다."
            case .jsonEncoding :        return "유효한 json 형식이 아닙니다."
            case .unauthorized :        return "인증되지 않은 사용자 입니다."
            case .notAllowedUrl :       return "올바른 URL 형식이 아닙니다."
            case let .badStatus(code):  return "에러 상태코드 : \(code)"
            case .errResponseFromServer(let errResponse): return errResponse?.message ?? ""
            case .unknown(let err):     return "알 수 없는 에러입니다 \n \(err)"
            }
        }
    }
    
}
