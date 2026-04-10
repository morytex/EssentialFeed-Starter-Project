//
//  LocalFeedLoader.swift
//  EssentialFeed
//
//  Created by Alessandro Moryta Suemasu on 10/04/26.
//

import Foundation

public final class LocalFeedLoader {
    public typealias SaveResult = Error?

    private let store: FeedStore
    private let currentDate: () -> Date

    public init(store: FeedStore, currentDate: @escaping () -> Date) {
        self.store = store
        self.currentDate = currentDate
    }

    public func save(_ items: [FeedItem], completion: @escaping (SaveResult) -> Void) {
        store.deleteCachedFeed { [weak self] deletionError in
            guard let self else { return }

            if let error = deletionError { return completion(error) }

            self.cache(items, completion: completion)
        }
    }

    public func cache(_ items: [FeedItem], completion: @escaping (SaveResult) -> Void) {
        store.insert(items, timestamp: currentDate()) { [weak self] error in
            guard self != nil else { return }
            completion(error)
        }
    }
}
