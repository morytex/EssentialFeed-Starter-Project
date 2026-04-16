//
//  CodableFeedStoreTests.swift
//  EssentialFeed
//
//  Created by Alessandro Moryta Suemasu on 15/04/26.
//

import XCTest
import EssentialFeed

final class CodableFeedStoreTests: XCTestCase, FailableFeedStoreSpecs {

    override func setUp() {
        super.setUp()
        setupEmptyStoreState()
    }

    override func tearDown() {
        undoStoreSideEffects()
        super.tearDown()
    }

    func test_retrieveCachedFeed_withEmptyCache_shouldDeliverEmptyResult() {
        let sut = makeSUT()

        expect(sut, toRetrieve: .empty)
    }

    func test_retrieveCachedFeed_withEmptyCache_whenCalledTwice_shouldHaveNoSideEffect() {
        let sut = makeSUT()

        expect(sut, toRetrieveTwice: .empty)
    }

    func test_retrieveCachedFeed_withNonEmptyCache_shouldDeliverFoundResult() {
        let cache = uniqueCache()
        let sut = makeSUT()

        insert(cache, to: sut)

        expect(sut, toRetrieve: .found(feed: cache.feed, timestamp: cache.timestamp))
    }

    func test_retrieveCachedFeed_withNonEmptyCache_whenCalledTwice_shouldHaveNoSideEffect() {
        let cache = uniqueCache()
        let sut = makeSUT()

        insert(cache, to: sut)

        expect(sut, toRetrieveTwice: .found(feed: cache.feed, timestamp: cache.timestamp))
    }

    func test_retrieveCachedFeed_withInvalidData_shouldDeliverFailureResult() {
        let storeURL = testSpecificStoreURL()
        let sut = makeSUT(storeURL: storeURL)

        try! "invalid data".write(to: storeURL, atomically: false, encoding: .utf8)

        expect(sut, toRetrieve: .failure(anyNSError()))
    }

    func test_retrieveCachedFeed_withInvalidData_shouldHaveNoSideEffect() {
        let storeURL = testSpecificStoreURL()
        let sut = makeSUT(storeURL: storeURL)

        try! "invalid data".write(to: storeURL, atomically: false, encoding: .utf8)

        expect(sut, toRetrieveTwice: .failure(anyNSError()))
    }

    func test_insert_withPreviousInsertion_shouldOverridePreviousInsertion() {
        let sut = makeSUT()

        let firstInsertionError = insert(uniqueCache(), to: sut)
        XCTAssertNil(firstInsertionError)

        let latestCache = uniqueCache()
        let latestInsertionError = insert(latestCache, to: sut)

        XCTAssertNil(latestInsertionError)
        expect(sut, toRetrieve: .found(feed: latestCache.feed, timestamp: latestCache.timestamp))
    }

    func test_insert_whenInvalidStoreURL_shouldDeliverError() {
        let invalidStoreURL = URL(string: "invalid://store-url")
        let cache = uniqueCache()
        let sut = makeSUT(storeURL: invalidStoreURL)

        let insertionError = insert(cache, to: sut)

        XCTAssertNotNil(insertionError)
    }

    func test_insert_whenInvalidStoreURL_shouldHaveNoSideEffects() {
        let invalidStoreURL = URL(string: "invalid://store-url")
        let cache = uniqueCache()
        let sut = makeSUT(storeURL: invalidStoreURL)

        insert(cache, to: sut)

        expect(sut, toRetrieve: .empty)
    }

    func test_deleteCachedFeed_whenEmptyCache_shouldHaveNoSideEffect() {
        let sut = makeSUT()

        let receivedError = deleteCache(from: sut)
        XCTAssertNil(receivedError)

        expect(sut, toRetrieve: .empty)
    }

    func test_deleteCachedFeed_whenNonEmptyCache_shouldResultInEmptyCache() {
        let sut = makeSUT()
        insert(uniqueCache(), to: sut)

        let receivedError = deleteCache(from: sut)
        XCTAssertNil(receivedError)

        expect(sut, toRetrieve: .empty)
    }

    func test_deleteCachedFeed_whenNoDeletionPermissionURL_shouldDeliverError() {
        let noDeletionPermissionURL = cachesDirectory()
        let sut = makeSUT(storeURL: noDeletionPermissionURL)

        let receivedError = deleteCache(from: sut)

        XCTAssertNotNil(receivedError)
    }

    func test_deleteCachedFeed_whenNoDeletionPermissionURL_shouldHaveNoSideEffects() {
        let noDeletionPermissionURL = cachesDirectory()
        let sut = makeSUT(storeURL: noDeletionPermissionURL)

        deleteCache(from: sut)

        expect(sut, toRetrieve: .empty)
    }

    func test_feedStore_whenSideEffectsRunSerially_shouldExecuteInCallOrder() {
        let cache = uniqueCache()
        let sut = makeSUT(storeURL: testSpecificStoreURL())

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

    // MARK: - Helpers

    private func makeSUT(storeURL: URL? = nil, file: StaticString = #filePath, line: UInt = #line) -> FeedStore {
        let sut = CodableFeedStore(storeURL: storeURL ?? testSpecificStoreURL())

        trackForMemoryLeaks(on: sut, file: file, line: line)

        return sut
    }

    private func uniqueCache() -> (feed: [LocalFeedImage], timestamp: Date) {
        let feed = uniqueImageFeed()
        let timestamp = Date()
        return (feed: feed.locals, timestamp: timestamp)
    }

    private func testSpecificStoreURL() -> URL {
        return cachesDirectory()
            .appendingPathComponent("\(type(of: self)).cache")
    }

    private func cachesDirectory() -> URL {
        return FileManager.default
            .urls(for: .cachesDirectory, in: .userDomainMask).first!
    }

    private func setupEmptyStoreState() {
        deleteStoreArtifacts()
    }

    private func undoStoreSideEffects() {
        deleteStoreArtifacts()
    }

    private func deleteStoreArtifacts() {
        try? FileManager.default.removeItem(at: testSpecificStoreURL())
    }
}
