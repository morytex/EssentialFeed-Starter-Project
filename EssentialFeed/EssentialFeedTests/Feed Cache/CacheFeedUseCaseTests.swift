//
//  CacheFeedUseCaseTests.swift
//  EssentialFeed
//
//  Created by Alessandro Moryta Suemasu on 09/04/26.
//

import XCTest
import EssentialFeed

final class LocalFeedLoader {
    private let store: FeedStore

    init(store: FeedStore) {
        self.store = store
    }

    func save(_ items: [FeedItem]) {
        store.deleteCachedFeed()
    }
}

final class FeedStore {
    var deleteFeedCallCount: Int = 0
    var insertFeedCallCount: Int = 0

    func deleteCachedFeed() {
        deleteFeedCallCount += 1
    }

    func completeCacheDeletion(with error: NSError, at index: Int = 0) { }
}

final class CacheFeedUseCaseTests: XCTestCase {

    func test_init_shouldNotDeleteCacheUponCreation() {
        let (_, store) = makeSUT()

        XCTAssertEqual(store.deleteFeedCallCount, 0)
    }

    func test_save_shouldRequestCacheDeletion() {
        let items = [uniqueItem()]
        let (sut, store) = makeSUT()

        sut.save(items)

        XCTAssertEqual(store.deleteFeedCallCount, 1)
    }

    func test_save_withCacheDeletionError_shouldNotRequestCacheInsertion() {
        let items = [uniqueItem()]
        let (sut, store) = makeSUT()

        sut.save(items)
        store.completeCacheDeletion(with: anyNSError())

        XCTAssertEqual(store.insertFeedCallCount, 0)
    }

    // MARK: - Helpers

    private func makeSUT() -> (sut: LocalFeedLoader, store: FeedStore) {
        let store = FeedStore()
        let sut = LocalFeedLoader(store: store)

        trackForMemoryLeaks(on: store)
        trackForMemoryLeaks(on: sut)

        return (sut, store)
    }

    private func uniqueItem() -> FeedItem {
        return FeedItem(id: UUID(), description: nil, location: nil, imageURL: anyURL())
    }

    private func anyURL() -> URL {
        return URL(string: "https://any-url.com")!
    }

    private func anyNSError() -> NSError {
        return NSError(domain: "an error", code: 1)
    }
}
