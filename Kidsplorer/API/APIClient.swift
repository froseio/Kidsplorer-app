//
//  APIClient.swift
//  
//
//  Created by Filip Růžička on 09.05.2023.
//

import Foundation
import Combine
import Shared

protocol ApiClient {
    var baseUrl: String { get }
    var baseHeaders: [String : String]? { get }
}

extension ApiClient {
    func load<T: Endpoint>(endpoint: T, urlSession: URLSession = URLSession.shared) async throws -> T.ResponseModelType {

        var url = endpoint.url(baseUrl: baseUrl)

        if T.path.httpMethod == .get, let parameters = endpoint.requestModel {
            url = url.appending(queryItems: parameters.queryItems)
        }

        var request = URLRequest(url: url)
        request.httpMethod = T.path.httpMethod.rawValue

        if let parameters = endpoint.requestModel, T.path.httpMethod != .get {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try JSONEncoder().encode(parameters)
        }

        baseHeaders?.forEach({ (key: String, value: String) in
            request.setValue(value, forHTTPHeaderField: key)
        })

        let (data, _) = try await urlSession.data(for: request)

        #if DEBUG
        if let stringData = String(data: data, encoding: .utf8) {
            logger.debug("\(stringData)")
        }
        #endif

        return try JSONDecoder().decode(T.ResponseModelType.self, from: data)
    }
}

extension Encodable {
    var queryItems: [URLQueryItem] {
        var items: [URLQueryItem] = []

        let encoder = JSONEncoder()
        guard let data = try? encoder.encode(self) else { return items }

        let json = (try? JSONSerialization.jsonObject(with: data, options: .allowFragments)) as? [String: Any]

        json?.forEach { key, value in
            if let arrayValue = value as? [Any] {
                let arrayString = arrayValue.map { "\($0)" }.joined(separator: ",")
                items.append(URLQueryItem(name: key, value: arrayString))
            } else {
                items.append(URLQueryItem(name: key, value: String(describing: value)))
            }
        }

        return items
    }
}


class CCAPIClient: ApiClient {

    static let shared = CCAPIClient()

    var baseUrl: String = "https://kidsplorer.frose.io"

//    #warning("Using local server")
//    var baseUrl: String = "http://127.0.0.1:8080"

    var baseHeaders: [String : String]? = [
        "RCID": GlobalEnvironment.shared.appUserID
    ]

    lazy var urlSession: URLSession = {
        let sessionConfig = URLSessionConfiguration.default
        sessionConfig.httpMaximumConnectionsPerHost = 1        
        return URLSession(configuration: sessionConfig)
    }()
}
 
