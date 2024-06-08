//
//  Url+Ext.swift
//  API_Practice
//
//  Created by CatSlave on 6/4/24.
//

import Foundation

extension URL {
    init?(baseUrl: String, optionUrl: String = "",  queryItems: [String: String]) {
        let url = baseUrl + optionUrl
        guard var urlComponents = URLComponents(string: url) else { return nil }
        urlComponents.queryItems = queryItems.map { URLQueryItem(name: $0.key, value: $0.value) }
        guard let finalUrlString = urlComponents.url?.absoluteString else { return nil }
        self.init(string: finalUrlString)
    }
}
