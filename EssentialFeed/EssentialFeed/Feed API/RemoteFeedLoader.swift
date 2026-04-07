//
//  RemoteFeedLoader.swift
//  EssentialFeed
//
//  Created by Alessandro Moryta Suemasu on 03/04/26.
//

import Foundation

public final class RemoteFeedLoader {
    private let client: HTTPCLient
    private let url: URL

    public enum Error: Swift.Error {
        case connectivity
        case invalidData
    }

    public typealias Result = LoadFeedResult<Error>

    public init (client: HTTPCLient, url: URL) {
        self.client = client
        self.url = url
    }

    public func load(completion: @escaping (Result) -> Void) {
        client.get(from: url) { [weak self] result in
            guard self != nil else { return }

            switch result {
            case let .success(data, response):
                completion(FeedItemMapper.map(data, response))
            case .failure:
                completion(.failure(RemoteFeedLoader.Error.connectivity))
            }
        }
    }
}
