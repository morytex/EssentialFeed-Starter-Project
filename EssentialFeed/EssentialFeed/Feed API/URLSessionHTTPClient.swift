//
//  URLSessionHTTPClient.swift
//  EssentialFeed
//
//  Created by Alessandro Moryta Suemasu on 07/04/26.
//

import Foundation

public final class URLSessionHTTPClient: HTTPClient {
    private let session: URLSession

    private struct UnexpectedValueRepresentation: Error {}

    public init(session: URLSession = .shared) {
        self.session = session
    }

    public func get(from url: URL, completion: @escaping (HTTPClientResult) -> Void) {
        session.dataTask(with: url) { data, response, error in
            if let error {
                completion(.failure(error))
                return
            }

            if let data, let response = response as? HTTPURLResponse {
                completion(.success((data, response)))
                return
            }

            completion(.failure(UnexpectedValueRepresentation()))
        }.resume()
    }
}
