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

    public func get(from url: URL, completion: @escaping (HTTPClient.Result) -> Void) {
        session.dataTask(with: url) { data, response, error in
            completion(Result {
                if let error { throw error }

                guard let data, let response = response as? HTTPURLResponse else {
                    throw UnexpectedValueRepresentation()
                }

                return (data, response)
            })
        }.resume()
    }
}
