//
//  RemoteFeedLoader.swift
//  EssentialFeed
//
//  Created by Alessandro Moryta Suemasu on 03/04/26.
//

import Foundation

public protocol HTTPCLient {
    func get(from url: URL)
}

public final class RemoteFeedLoader {
    private let client: HTTPCLient
    private let url: URL
    
    public init (client: HTTPCLient, url: URL) {
        self.client = client
        self.url = url
    }

    public func load() {
        client.get(from: url)
    }
}
