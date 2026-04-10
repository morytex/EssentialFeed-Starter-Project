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

    func save(_ items: [FeedItem], completion: @escaping (Error?) -> Void) {
        store.deleteCachedFeed { [unowned self] deletionError in
            if let error = deletionError {
                return completion(error)
            }

            self.store.insert(items, timestamp: self.currentDate(), completion: completion)
        }
    }
}

protocol FeedStore {
    typealias DeleteCompletion = (Error?) -> Void
    typealias InsertCompletion = (Error?) -> Void

    func deleteCachedFeed(completion: @escaping DeleteCompletion)
    func insert(_ items: [FeedItem], timestamp: Date, completion: @escaping InsertCompletion)
}

final class CacheFeedUseCaseTests: XCTestCase {

    func test_init_shouldNotDeleteCacheUponCreation() {
        let (_, store) = makeSUT()

        XCTAssertEqual(store.receivedMessages, [])
    }

    func test_save_shouldRequestCacheDeletion() {
        let (sut, store) = makeSUT()

        sut.save([uniqueItem()]) { _ in }

        XCTAssertEqual(store.receivedMessages, [.deletion])
    }

    func test_save_withCacheDeletionError_shouldNotRequestCacheInsertion() {
        let (sut, store) = makeSUT()

        sut.save([uniqueItem()]) { _ in }
        store.completeDeletion(with: anyNSError())

        XCTAssertEqual(store.receivedMessages, [.deletion])
    }

    func test_save_withCacheDeletionSuccess_shouldInsertItemsAndTimestamp() {
        let timestamp = Date()
        let items = [uniqueItem()]
        let (sut, store) = makeSUT(currentDate: { timestamp })

        sut.save(items) { _ in }
        store.completeDeletionWithSuccess()

        XCTAssertEqual(store.receivedMessages, [.deletion, .insert(items: items, timestamp: timestamp)])
    }

    func test_save_withCacheDeletionError_shouldDeliverError() {
        let (sut, store) = makeSUT()
        let deletionError = anyNSError()

        expect(sut, toCompleteWith: deletionError) {
            store.completeDeletion(with: deletionError)
        }
    }

    func test_save_withCacheInsertError_shouldDeliverError() {
        let (sut, store) = makeSUT()
        let insertionError = anyNSError()

        expect(sut, toCompleteWith: insertionError) {
            store.completeDeletionWithSuccess()
            store.completeInsertion(with: insertionError)
        }
    }

    func test_save_withCacheInsertionSuccess_shouldNotDeliverError() {
        let (sut, store) = makeSUT()
        let expectation = expectation(description: "Wait for completion")

        var receivedError: Error?
        sut.save([uniqueItem()]) { error in
            receivedError = error
            expectation.fulfill( )
        }
        store.completeDeletionWithSuccess()
        store.completeInsertionWithSuccess()
        wait(for: [expectation], timeout: 1)

        XCTAssertNil(receivedError)
    }

    // MARK: - Helpers

    private func makeSUT(currentDate: @escaping () -> Date = Date.init, file: StaticString = #filePath, line: UInt = #line) -> (sut: LocalFeedLoader, store: FeedStoreSpy) {
        let store = FeedStoreSpy()
        let sut = LocalFeedLoader(store: store, currentDate: currentDate)

        trackForMemoryLeaks(on: store, file: file, line: line)
        trackForMemoryLeaks(on: sut, file: file, line: line)

        return (sut, store)
    }

    private func expect(_ sut: LocalFeedLoader, toCompleteWith error: NSError, when action: () -> Void, file: StaticString = #filePath, line: UInt = #line) {
        let expectation = expectation(description: "Wait for completion")
        var receivedError: Error?
        sut.save([uniqueItem()]) { error in
            receivedError = error
            expectation.fulfill( )
        }

        action()
        wait(for: [expectation], timeout: 1)

        XCTAssertEqual(receivedError as? NSError, error)
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

    private class FeedStoreSpy: FeedStore {
        enum Messages: Equatable {
            case insert(items: [FeedItem], timestamp: Date)
            case deletion
        }

        typealias Completion = (Error?) -> Void

        var receivedMessages = [Messages]()

        var deleteCompletions = [DeleteCompletion]()
        var insertCompletions = [InsertCompletion]()

        func deleteCachedFeed(completion: @escaping DeleteCompletion) {
            receivedMessages.append(.deletion)
            deleteCompletions.append(completion)
        }

        func insert(_ items: [FeedItem], timestamp: Date, completion: @escaping InsertCompletion) {
            receivedMessages.append(.insert(items: items, timestamp: timestamp))
            insertCompletions.append(completion)
        }

        func completeDeletion(with error: NSError, at index: Int = 0) {
            deleteCompletions[index](error)
        }

        func completeDeletionWithSuccess(at index: Int = 0) {
            deleteCompletions[index](nil)
        }

        func completeInsertion(with error: NSError, at index: Int = 0) {
            insertCompletions[index](error)
        }

        func completeInsertionWithSuccess(at index: Int = 0) {
            insertCompletions[index](nil)
        }
    }
}
