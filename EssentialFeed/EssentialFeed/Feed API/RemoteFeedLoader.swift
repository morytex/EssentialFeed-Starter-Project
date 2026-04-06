//
//  RemoteFeedLoader.swift
//  EssentialFeed
//
//  Created by Alessandro Moryta Suemasu on 03/04/26.
//

import Foundation

public enum HTTPClientResult {
    case success(Data, HTTPURLResponse)
    case failure(Error)
}

public protocol HTTPCLient {
    func get(from url: URL, completion: @escaping (HTTPClientResult) -> Void)
}

public final class RemoteFeedLoader {
    private let client: HTTPCLient
    private let url: URL

    public enum Error: Swift.Error {
        case connectivity
        case invalidData
    }

    public enum Result: Equatable {
        case success([FeedItem])
        case failure(Error)
    }

    public init (client: HTTPCLient, url: URL) {
        self.client = client
        self.url = url
    }

    public func load(completion: @escaping (RemoteFeedLoader.Result) -> Void) {
        client.get(from: url) { result in
            switch result {
            case let .success(data, response):
                if response.statusCode == 200, let items = try? FeedItemMapper.map(from: data) {
                    completion(.success(items))
                } else {
                    completion(.failure(.invalidData))
                }
            case .failure:
                completion(.failure(.connectivity))
            }
        }
    }
}

private class FeedItemMapper {
    private struct Root: Decodable {
        let items: [Item]
    }

    private struct Item: Decodable {
        let id: UUID
        let description: String?
        let location: String?
        let image: URL
    }

    static func map(from data: Data) throws -> [FeedItem] {
        let root = try JSONDecoder().decode(Root.self, from: data)
        return root.items.map { item in
            FeedItem(
                id: item.id,
                description: item.description,
                location: item.location,
                imageURL: item.image
            )
        }
    }
}
