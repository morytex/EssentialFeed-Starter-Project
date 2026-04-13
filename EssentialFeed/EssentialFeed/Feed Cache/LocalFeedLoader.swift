//
//  LocalFeedLoader.swift
//  EssentialFeed
//
//  Created by Alessandro Moryta Suemasu on 10/04/26.
//

import Foundation

public final class LocalFeedLoader {
    public typealias SaveResult = Error?
    public typealias LoadResult = LoadFeedResult

    private let store: FeedStore
    private let currentDate: () -> Date

    public init(store: FeedStore, currentDate: @escaping () -> Date) {
        self.store = store
        self.currentDate = currentDate
    }

    public func save(_ feed: [FeedImage], completion: @escaping (SaveResult) -> Void) {
        store.deleteCachedFeed { [weak self] deletionError in
            guard let self else { return }

            if let error = deletionError { return completion(error) }

            self.cache(feed, completion: completion)
        }
    }

    public func load(completion: @escaping (LoadResult) -> Void) {
        store.retrieveCachedFeed { [unowned self] result in
            switch result {
            case let .found(localFeed, timestamp) where self.hasValid(timestamp):
                completion(.success(localFeed.toModels()))
            case let .failure(error):
                completion(.failure(error))
            case .found, .empty:
                completion(.success([]))
            }
        }
    }

    private func cache(_ feed: [FeedImage], completion: @escaping (SaveResult) -> Void) {
        store.insert(feed.toLocal(), timestamp: currentDate()) { [weak self] error in
            guard self != nil else { return }
            completion(error)
        }
    }

    private var maxCacheAgeInDays: Int { 7 }
    private func hasValid(_ timestamp: Date) -> Bool {
        guard let maxCacheAge = Calendar(identifier: .gregorian).date(byAdding: .day, value: maxCacheAgeInDays, to: timestamp) else {
            return false
        }

        return currentDate() < maxCacheAge
    }
}

private extension Array where Element == FeedImage {
    func toLocal() -> [LocalFeedImage] {
        return map {
            LocalFeedImage(id: $0.id, description: $0.description, location: $0.location, url: $0.url)
        }
    }
}

private extension Array where Element == LocalFeedImage {
    func toModels() -> [FeedImage] {
        return map {
            FeedImage(id: $0.id, description: $0.description, location: $0.location, url: $0.url)
        }
    }
}
