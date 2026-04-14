//
//  LocalFeedLoader.swift
//  EssentialFeed
//
//  Created by Alessandro Moryta Suemasu on 10/04/26.
//

import Foundation

public final class LocalFeedLoader {
    private let store: FeedStore
    private let currentDate: () -> Date
    private let calendar = Calendar(identifier: .gregorian)

    public init(store: FeedStore, currentDate: @escaping () -> Date) {
        self.store = store
        self.currentDate = currentDate
    }

    private var maxCacheAgeInDays: Int { 7 }

    private func hasValid(_ timestamp: Date) -> Bool {
        guard let maxCacheAge = calendar.date(byAdding: .day, value: maxCacheAgeInDays, to: timestamp) else {
            return false
        }

        return currentDate() < maxCacheAge
    }
}

extension LocalFeedLoader {
    public typealias SaveResult = Error?

    public func save(_ feed: [FeedImage], completion: @escaping (SaveResult) -> Void) {
        store.deleteCachedFeed { [weak self] deletionError in
            guard let self else { return }

            if let error = deletionError { return completion(error) }

            self.cache(feed, completion: completion)
        }
    }

    private func cache(_ feed: [FeedImage], completion: @escaping (SaveResult) -> Void) {
        store.insert(feed.toLocal(), timestamp: currentDate()) { [weak self] error in
            guard self != nil else { return }
            completion(error)
        }
    }
}

extension LocalFeedLoader: FeedLoader {
    public typealias LoadResult = LoadFeedResult

    public func load(completion: @escaping (LoadResult) -> Void) {
        store.retrieveCachedFeed { [weak self] result in
            guard let self else { return }
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
}

extension LocalFeedLoader {
    public func validateCache() {
        store.retrieveCachedFeed { [weak self] result in
            guard let self else { return }
            switch result {
            case let .found(_, timestamp) where !self.hasValid(timestamp):
                self.store.deleteCachedFeed { _ in }
            case .failure:
                self.store.deleteCachedFeed { _ in }
            case .found, .empty:
                break
            }
        }
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
