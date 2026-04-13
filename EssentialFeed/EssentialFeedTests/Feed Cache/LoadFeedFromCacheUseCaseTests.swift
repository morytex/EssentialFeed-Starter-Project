//
//  LoadFeedFromCacheUseCaseTests.swift
//  EssentialFeed
//
//  Created by Alessandro Moryta Suemasu on 13/04/26.
//

import XCTest
import EssentialFeed

final class LoadFeedFromCacheUseCaseTests: XCTestCase {

    func test_init_shouldNotRetrieveCacheUponCreation() {
        let (_, store) = makeSUT()

        XCTAssertEqual(store.receivedMessages, [])
    }

    // MARK: - Helpers

    private func makeSUT(currentDate: @escaping () -> Date = Date.init, file: StaticString = #filePath, line: UInt = #line) -> (sut: LocalFeedLoader, store: FeedStoreSpy) {
        let store = FeedStoreSpy()
        let sut = LocalFeedLoader(store: store, currentDate: currentDate)

        trackForMemoryLeaks(on: store, file: file, line: line)
        trackForMemoryLeaks(on: sut, file: file, line: line)

        return (sut, store)
    }

    private class FeedStoreSpy: FeedStore {
        enum Messages: Equatable {
            case insert(feed: [LocalFeedImage], timestamp: Date)
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

        func insert(_ feed: [LocalFeedImage], timestamp: Date, completion: @escaping InsertCompletion) {
            receivedMessages.append(.insert(feed: feed, timestamp: timestamp))
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
