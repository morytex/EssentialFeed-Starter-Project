//
//  XCTestCase+FeedStoreSpecs.swift
//  EssentialFeed
//
//  Created by Alessandro Moryta Suemasu on 16/04/26.
//

import XCTest
import EssentialFeed

extension FeedStoreSpecs where Self: XCTestCase {
    func assertThatRetrieveDeliversEmptyOnEmptyCache(on sut: FeedStore, file: StaticString = #filePath, line: UInt = #line) {
        expect(sut, toRetrieve: .empty, file: file, line: line)
    }

    func assertThatRetrieveHasNoSideEffectOnEmptyCache(on sut: FeedStore, file: StaticString = #filePath, line: UInt = #line) {
        expect(sut, toRetrieveTwice: .empty, file: file, line: line)
    }

    func assertThatRetrieveDeliversFoundResultOnNonEmptyCache(on sut: FeedStore, file: StaticString = #filePath, line: UInt = #line) {
        let cache = uniqueCache()

        insert(cache, to: sut)

        expect(sut, toRetrieve: .found(feed: cache.feed, timestamp: cache.timestamp), file: file, line: line)
    }

    func assertThatRetrieveHasNoSideEffectOnNonEmptyCache(on sut: FeedStore, file: StaticString = #filePath, line: UInt = #line) {
        let cache = uniqueCache()

        insert(cache, to: sut)

        expect(sut, toRetrieveTwice: .found(feed: cache.feed, timestamp: cache.timestamp), file: file, line: line)
    }

    func assertThatInsertDoesNotReturnErrorOnEmptyCache(on sut: FeedStore, file: StaticString = #filePath, line: UInt = #line) {
        let cache = uniqueCache()

        let receivedError = insert(cache, to: sut)

        XCTAssertNil(receivedError, file: file, line: line)
    }

    func assertThatInsertOverridesPreviousInsertion(on sut: FeedStore, file: StaticString = #filePath, line: UInt = #line) {
        let firstInsertionError = insert(uniqueCache(), to: sut)
        XCTAssertNil(firstInsertionError, file: file, line: line)

        let latestCache = uniqueCache()
        let latestInsertionError = insert(latestCache, to: sut)

        XCTAssertNil(latestInsertionError, file: file, line: line)
        expect(sut, toRetrieve: .found(feed: latestCache.feed, timestamp: latestCache.timestamp), file: file, line: line)
    }

    func assertThatDeleteDoesNotReturnErrorOnEmptyCache(on sut: FeedStore, file: StaticString = #filePath, line: UInt = #line) {
        let receivedError = deleteCache(from: sut)

        XCTAssertNil(receivedError, file: file, line: line)
    }

    func assertThatDeleteHasNoSideEffectOnEmptyCache(on sut: FeedStore, file: StaticString = #filePath, line: UInt = #line) {
        deleteCache(from: sut)

        expect(sut, toRetrieve: .empty, file: file, line: line)
    }

    func assertThatDeleteDoesNotReturnErrorOnNonEmptyCache(on sut: FeedStore, file: StaticString = #filePath, line: UInt = #line) {
        insert(uniqueCache(), to: sut)

        let receivedError = deleteCache(from: sut)

        XCTAssertNil(receivedError)
    }

    func assertThatDeleteEmptiesCacheOnNonEmptyCache(on sut: FeedStore, file: StaticString = #filePath, line: UInt = #line) {
        insert(uniqueCache(), to: sut)

        deleteCache(from: sut)

        expect(sut, toRetrieve: .empty)
    }

    func assertThatSideEffectsRunSerially(on sut: FeedStore, file: StaticString = #filePath, line: UInt = #line) {
        let cache = uniqueCache()

        let expectation1 = expectation(description: "Wait for first operation")
        sut.insert(cache.feed, timestamp: cache.timestamp) { _ in
            expectation1.fulfill()
        }

        let expectation2 = expectation(description: "Wait for second completion")
        sut.deleteCachedFeed { _ in
            expectation2.fulfill()
        }

        let expectation3 = expectation(description: "Wait for third operation")
        sut.insert(cache.feed, timestamp: cache.timestamp) { _ in
            expectation3.fulfill()
        }

        wait(for: [expectation1, expectation2, expectation3], timeout: 1.0, enforceOrder: true)
    }

    func expect(_ sut: FeedStore, toRetrieveTwice result: RetrieveCachedFeedResult, file: StaticString = #filePath, line: UInt = #line) {
        expect(sut, toRetrieve: result, file: file, line: line)
        expect(sut, toRetrieve: result, file: file, line: line)
    }

    func expect(_ sut: FeedStore, toRetrieve result: RetrieveCachedFeedResult, file: StaticString = #filePath, line: UInt = #line) {
        let expectation = expectation(description: "Wait for retrieval completion")
        sut.retrieveCachedFeed { receivedResult in
            switch (receivedResult, result) {
            case (.empty, .empty), (.failure, .failure):
                break
            case let (.found(receivedFeed, receivedTimestamp), .found(feed, timestamp)):
                XCTAssertEqual(receivedFeed, feed, file: file, line: line)
                XCTAssertEqual(receivedTimestamp, timestamp, file: file, line: line)
            default:
                XCTFail("Expected result to be \(result), but got \(receivedResult)", file: file, line: line)
            }
            expectation.fulfill( )
        }
        wait(for: [expectation], timeout: 1.0)
    }

    @discardableResult
    func insert(_ cache: (feed: [LocalFeedImage], timestamp: Date), to sut: FeedStore) -> Error? {
        var receiverError: Error?
        let expectation = expectation(description: "Wait for insertion completion")
        sut.insert(cache.feed, timestamp: cache.timestamp) { error in
            receiverError = error
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)

        return receiverError
    }

    @discardableResult
    func deleteCache(from sut: FeedStore) -> Error? {
        var receivedError: Error?
        let expectation = expectation(description: "Wait for deletion completion")
        sut.deleteCachedFeed { error in
            receivedError = error
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)

        return receivedError
    }

    func uniqueCache() -> (feed: [LocalFeedImage], timestamp: Date) {
        let feed = uniqueImageFeed()
        let timestamp = Date()
        return (feed: feed.locals, timestamp: timestamp)
    }
}
