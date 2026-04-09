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
        store.deleteCachedFeed { [unowned self] error in
            if error == nil {
                self.store.insert(items)
            }
        }
    }
}

final class FeedStore {
    typealias DeleteCompletion = (Error?) -> Void

    var deleteCachedFeedCallCount: Int = 0
    var insertCallCount: Int = 0

    var deleteCompletions = [DeleteCompletion]()

    func deleteCachedFeed(completion: @escaping DeleteCompletion) {
        deleteCachedFeedCallCount += 1
        deleteCompletions.append(completion)
    }

    func insert(_ items: [FeedItem]) {
        insertCallCount += 1
    }

    func completeDeletion(with error: NSError, at index: Int = 0) {
        deleteCompletions[index](error)
    }

    func completeDeletionWithSuccess(at index: Int = 0) {
        deleteCompletions[index](nil)
    }
}

final class CacheFeedUseCaseTests: XCTestCase {

    func test_init_shouldNotDeleteCacheUponCreation() {
        let (_, store) = makeSUT()

        XCTAssertEqual(store.deleteCachedFeedCallCount, 0)
    }

    func test_save_shouldRequestCacheDeletion() {
        let items = [uniqueItem()]
        let (sut, store) = makeSUT()

        sut.save(items)

        XCTAssertEqual(store.deleteCachedFeedCallCount, 1)
    }

    func test_save_withCacheDeletionError_shouldNotRequestCacheInsertion() {
        let items = [uniqueItem()]
        let (sut, store) = makeSUT()

        sut.save(items)
        store.completeDeletion(with: anyNSError())

        XCTAssertEqual(store.insertCallCount, 0)
    }

    func test_save_withCacheDeletionSuccess_shouldRequestNewCacheInsertion() {
        let items = [uniqueItem()]
        let (sut, store) = makeSUT()

        sut.save(items)
        store.completeDeletionWithSuccess()

        XCTAssertEqual(store.insertCallCount, 1)
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
