//
//  FeedStore.swift
//  EssentialFeed
//
//  Created by Alessandro Moryta Suemasu on 10/04/26.
//

import Foundation

public struct CachedFeed {
    public let feed: [LocalFeedImage]
    public let timestamp: Date

    public init(feed: [LocalFeedImage], timestamp: Date) {
        self.feed = feed
        self.timestamp = timestamp
    }
}

public protocol FeedStore {
    typealias DeleteResult = Result<Void, Error>
    typealias DeleteCompletion = (DeleteResult) -> Void

    typealias InsertResult = Result<Void, Error>
    typealias InsertCompletion = (InsertResult) -> Void

    typealias RetrieveResult = Result<CachedFeed?, Error>
    typealias RetrieveCompletion = (RetrieveResult) -> Void

    /// Deletes the cached feed from the store.
    ///
    /// The completion handler can be invoked in any thread. Clients are responsible to dispatch to appropriate thread, if needed.
    /// - Parameter completion: It is invoked with an optional `Error`. If `nil`, the operation has succeeded. Otherwise, it failed.
    func deleteCachedFeed(completion: @escaping DeleteCompletion)

    /// Stores the feed and associates it to the informed timestamp.
    ///
    /// The completion handler can be invoked in any thread. Clients are responsible to dispatch to appropriate thread, if needed.
    /// - Parameter completion: It is invoked with an optional `Error`. If `nil`, the operation has succeeded. Otherwise, it failed.
    func insert(_ feed: [LocalFeedImage], timestamp: Date, completion: @escaping InsertCompletion)

    /// Retrieves the cached feed from the store.
    ///
    /// The completion handler can be invoked in any thread. Clients are responsible to dispatch to appropriate thread, if needed.
    /// - Parameter completion: It is invoked with ``RetrieveCachedFeedResult``.
    func retrieveCachedFeed(completion: @escaping RetrieveCompletion)
}

public struct LocalFeedImage: Equatable {
    public let id: UUID
    public let description: String?
    public let location: String?
    public let url: URL

    public init(id: UUID, description: String?, location: String?, url: URL) {
        self.id = id
        self.description = description
        self.location = location
        self.url = url
    }
}
