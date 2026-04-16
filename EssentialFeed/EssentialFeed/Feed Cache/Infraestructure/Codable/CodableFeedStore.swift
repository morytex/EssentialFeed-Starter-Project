//
//  CodableFeedStore.swift
//  EssentialFeed
//
//  Created by Alessandro Moryta Suemasu on 15/04/26.
//

import Foundation

public final class CodableFeedStore: FeedStore {

    private struct Cache: Codable {
        let feed: [CodableFeedImage]
        let timestamp: Date

        var localFeed: [LocalFeedImage] {
            feed.map(\.local)
        }
    }

    private struct CodableFeedImage: Codable {
        private let id: UUID
        private let description: String?
        private let location: String?
        private let url: URL

        init(_ image: LocalFeedImage) {
            self.id = image.id
            self.description = image.description
            self.location = image.location
            self.url = image.url
        }

        var local: LocalFeedImage {
            .init(id: id, description: description, location: location, url: url)
        }
    }

    private let storeURL: URL

    private let queue = DispatchQueue(label: "\(CodableFeedStore.self )Queue", qos: .userInitiated, attributes: .concurrent)

    public init(storeURL: URL) {
        self.storeURL = storeURL
    }

    public func deleteCachedFeed(completion: @escaping DeleteCompletion) {
        let storeURL = self.storeURL
        queue.async(flags: .barrier) {
            guard FileManager.default.fileExists(atPath: storeURL.path) else {
                return completion(nil)
            }
            
            do {
                try FileManager.default.removeItem(at: storeURL)
                completion(nil)
            } catch {
                completion(error)
            }
        }
    }

    public func insert(_ feed: [LocalFeedImage], timestamp: Date, completion: @escaping InsertCompletion) {
        let storeURL = self.storeURL
        queue.async(flags: .barrier) {
            let encoder = JSONEncoder()
            do {
                let encoded = try encoder.encode(Cache(feed: feed.map(CodableFeedImage.init), timestamp: timestamp))
                try encoded.write(to: storeURL)
                completion(nil)
            } catch {
                completion(error)
            }
        }
    }

    public func retrieveCachedFeed(completion: @escaping RetrieveCompletion) {
        let storeURL = self.storeURL
        queue.async {
            guard let data = try? Data(contentsOf: storeURL) else {
                return completion(.empty)
            }

            let decoder = JSONDecoder()
            do {
                let cache = try decoder.decode(Cache.self, from: data)
                completion(.found(feed: cache.localFeed, timestamp: cache.timestamp))
            } catch {
                completion(.failure(error))
            }
        }
    }
}
