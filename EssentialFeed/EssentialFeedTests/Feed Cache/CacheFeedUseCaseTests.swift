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
    private let currentDate: () -> Date

    init(store: FeedStore, currentDate: @escaping () -> Date) {
        self.store = store
        self.currentDate = currentDate
    }

    func save(_ items: [FeedItem]) {
        store.deleteCachedFeed { [unowned self] error in
            if error == nil {
                self.store.insert(items, timestamp: self.currentDate())
            }
        }
    }
}

final class FeedStore {
    enum Messages: Equatable {
        case insert(items: [FeedItem], timestamp: Date)
        case deletion
    }

    typealias DeleteCompletion = (Error?) -> Void

    var insertedItems = [(items: [FeedItem], timestamp: Date)]()
    var receivedMessages = [Messages]()

    var deleteCompletions = [DeleteCompletion]()

    func deleteCachedFeed(completion: @escaping DeleteCompletion) {
        receivedMessages.append(.deletion)
        deleteCompletions.append(completion)
    }

    func insert(_ items: [FeedItem], timestamp: Date) {
        receivedMessages.append(.insert(items: items, timestamp: timestamp))
        insertedItems.append((items, timestamp))
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

        XCTAssertEqual(store.receivedMessages, [])
    }

    func test_save_shouldRequestCacheDeletion() {
        let items = [uniqueItem()]
        let (sut, store) = makeSUT()

        sut.save(items)

        XCTAssertEqual(store.receivedMessages, [.deletion])
    }

    func test_save_withCacheDeletionError_shouldNotRequestCacheInsertion() {
        let items = [uniqueItem()]
        let (sut, store) = makeSUT()

        sut.save(items)
        store.completeDeletion(with: anyNSError())

        XCTAssertEqual(store.receivedMessages, [.deletion])
    }

    func test_save_withCacheDeletionSuccess_shouldInsertItemsAndTimestamp() {
        let timestamp = Date()
        let items = [uniqueItem()]
        let (sut, store) = makeSUT(currentDate: { timestamp })

        sut.save(items)
        store.completeDeletionWithSuccess()

        XCTAssertEqual(store.receivedMessages, [.deletion, .insert(items: items, timestamp: timestamp)])
    }

    // MARK: - Helpers

    private func makeSUT(currentDate: @escaping () -> Date = Date.init, file: StaticString = #filePath, line: UInt = #line) -> (sut: LocalFeedLoader, store: FeedStore) {
        let store = FeedStore()
        let sut = LocalFeedLoader(store: store, currentDate: currentDate)

        trackForMemoryLeaks(on: store, file: file, line: line)
        trackForMemoryLeaks(on: sut, file: file, line: line)

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
