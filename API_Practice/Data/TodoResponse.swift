//
//  ResponeModel.swift
//  API_Practice
//
//  Created by CatSlave on 5/31/24.
//

import Foundation

// MARK: - Base
struct BaseListResponse<T: Codable>: Codable {
    let data: [T]?
    let meta: Meta?
    let message: String?
//    let hey: String
}

struct BaseResponse<T: Codable>: Codable {
    let data: T?
    let message: String?
//    let hey: String
}

// MARK: - Todo
struct Todo: Codable {
    var id: Int?
    var title: String?
    var isDone: Bool?
    let createdAt, updatedAt: String?

    enum CodingKeys: String, CodingKey {
        case id, title
        case isDone = "is_done"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
    
}

// MARK: - Meta
struct Meta: Codable {
    let currentPage, from, lastPage, perPage: Int?
    let to, total: Int?

    enum CodingKeys: String, CodingKey {
        case currentPage = "current_page"
        case from
        case lastPage = "last_page"
        case perPage = "per_page"
        case to, total
    }
    
    func hasNext() -> Bool {
        guard let current = currentPage,
              let last = lastPage else {
            return true
        }
        
        return last > current
    }
}
