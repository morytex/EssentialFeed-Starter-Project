//
//  CacheFeedUseCaseTests.swift
//  EssentialFeed
//
//  Created by Alessandro Moryta Suemasu on 09/04/26.
//

import XCTest
import EssentialFeed

final class CacheFeedUseCaseTests: XCTestCase {

    func test_init_shouldNotDeleteCacheUponCreation() {
        let (_, store) = makeSUT()

        XCTAssertEqual(store.receivedMessages, [])
    }

    func test_save_shouldRequestCacheDeletion() {
        let (sut, store) = makeSUT()

        sut.save(uniqueItems().models) { _ in }

        XCTAssertEqual(store.receivedMessages, [.deletion])
    }

    func test_save_withCacheDeletionError_shouldNotRequestCacheInsertion() {
        let (sut, store) = makeSUT()

        sut.save(uniqueItems().models) { _ in }
        store.completeDeletion(with: anyNSError())

        XCTAssertEqual(store.receivedMessages, [.deletion])
    }

    func test_save_withCacheDeletionSuccess_shouldInsertItemsAndTimestamp() {
        let timestamp = Date()
        let (items, localItems) = uniqueItems()
        let (sut, store) = makeSUT(currentDate: { timestamp })

        sut.save(items) { _ in }
        store.completeDeletionWithSuccess()

        XCTAssertEqual(store.receivedMessages, [.deletion, .insert(items: localItems, timestamp: timestamp)])
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

        expect(sut, toCompleteWith: nil) {
            store.completeDeletionWithSuccess()
            store.completeInsertionWithSuccess()
        }
    }

    func test_save_whenInstanceIsDeallocated_shouldNotDeliverDeletionError() {
        let store = FeedStoreSpy()
        var sut: LocalFeedLoader? = LocalFeedLoader(store: store, currentDate: Date.init)

        var receivedResults = [LocalFeedLoader.SaveResult]()
        sut?.save([uniqueItem()]) { result in
            receivedResults.append(result)
        }

        sut = nil
        store.completeDeletion(with: anyNSError())

        XCTAssertTrue(receivedResults.isEmpty)
    }

    func test_save_whenInstanceIsDeallocated_shouldNotDeliverInsertionError() {
        let store = FeedStoreSpy()
        var sut: LocalFeedLoader? = LocalFeedLoader(store: store, currentDate: Date.init)

        var receivedResults = [LocalFeedLoader.SaveResult]()
        sut?.save([uniqueItem()]) { result in
            receivedResults.append(result)
        }

        store.completeDeletionWithSuccess()
        sut = nil
        store.completeInsertion(with: anyNSError())

        XCTAssertTrue(receivedResults.isEmpty)
    }

    // MARK: - Helpers

    private func makeSUT(currentDate: @escaping () -> Date = Date.init, file: StaticString = #filePath, line: UInt = #line) -> (sut: LocalFeedLoader, store: FeedStoreSpy) {
        let store = FeedStoreSpy()
        let sut = LocalFeedLoader(store: store, currentDate: currentDate)

        trackForMemoryLeaks(on: store, file: file, line: line)
        trackForMemoryLeaks(on: sut, file: file, line: line)

        return (sut, store)
    }

    private func expect(_ sut: LocalFeedLoader, toCompleteWith error: NSError?, when action: () -> Void, file: StaticString = #filePath, line: UInt = #line) {
        let expectation = expectation(description: "Wait for completion")
        var receivedResults = [LocalFeedLoader.SaveResult]()
        sut.save([uniqueItem()]) { result in
            receivedResults.append(result)
            expectation.fulfill( )
        }

        action()
        wait(for: [expectation], timeout: 1)

        XCTAssertEqual(receivedResults.count, 1)
        XCTAssertEqual(receivedResults.first as? NSError, error)
    }

    private func uniqueItems() -> (models: [FeedImage], locals: [LocalFeedItem]) {
        let items = [uniqueItem()]
        let localItems = items.map { LocalFeedItem(id: $0.id, description: $0.description, location: $0.location, imageURL: $0.url) }

        return (items, localItems)
    }

    private func uniqueItem() -> FeedImage {
        return FeedImage(id: UUID(), description: nil, location: nil, url: anyURL())
    }

    private func anyURL() -> URL {
        return URL(string: "https://any-url.com")!
    }

    private func anyNSError() -> NSError {
        return NSError(domain: "an error", code: 1)
    }

    private class FeedStoreSpy: FeedStore {
        enum Messages: Equatable {
            case insert(items: [LocalFeedItem], timestamp: Date)
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

        func insert(_ items: [LocalFeedItem], timestamp: Date, completion: @escaping InsertCompletion) {
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
