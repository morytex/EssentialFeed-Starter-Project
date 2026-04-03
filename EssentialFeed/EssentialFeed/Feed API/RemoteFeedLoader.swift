//
//  RemoteFeedLoader.swift
//  EssentialFeed
//
//  Created by Alessandro Moryta Suemasu on 03/04/26.
//

import Foundation

public protocol HTTPCLient {
    func get(from url: URL, completion: @escaping (Error) -> Void)
}

public final class RemoteFeedLoader {
    private let client: HTTPCLient
    private let url: URL

    public enum Error: Swift.Error {
        case connectivity
    }

    public init (client: HTTPCLient, url: URL) {
        self.client = client
        self.url = url
    }

    public func load(completion: @escaping (Error) -> Void = { _ in }) {
        client.get(from: url) { error in
            completion(.connectivity)
        }
    }
}
