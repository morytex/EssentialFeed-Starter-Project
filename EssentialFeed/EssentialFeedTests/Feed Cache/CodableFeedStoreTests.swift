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

        assertThatRetrieveDeliversEmptyOnEmptyCache(on: sut)
    }

    func test_retrieveCachedFeed_withEmptyCache_shouldHaveNoSideEffect() {
        let sut = makeSUT()

        assertThatRetrieveHasNoSideEffectOnEmptyCache(on: sut)
    }

    func test_retrieveCachedFeed_withNonEmptyCache_shouldDeliverFoundResult() {
        let sut = makeSUT()

        assertThatRetrieveDeliversFoundResultOnNonEmptyCache(on: sut)
    }

    func test_retrieveCachedFeed_withNonEmptyCache_shouldHaveNoSideEffect() {
        let sut = makeSUT()

        assertThatRetrieveHasNoSideEffectOnNonEmptyCache(on: sut)
    }

    func test_retrieveCachedFeed_withInvalidData_shouldDeliverFailureResult() {
        let storeURL = testSpecificStoreURL()
        let sut = makeSUT(storeURL: storeURL)

        try! "invalid data".write(to: storeURL, atomically: false, encoding: .utf8)

        assertThatRetrieveDeliversFailureResultOnRetrievalError(on: sut)
    }

    func test_retrieveCachedFeed_withInvalidData_shouldHaveNoSideEffect() {
        let storeURL = testSpecificStoreURL()
        let sut = makeSUT(storeURL: storeURL)

        try! "invalid data".write(to: storeURL, atomically: false, encoding: .utf8)

        assertThatRetrieveHasNoSideEffectOnRetrievalError(on: sut)
    }

    func test_insert_withEmptyCache_shouldNotDeliverError() {
        let sut = makeSUT()

        assertThatInsertDoesNotReturnErrorOnEmptyCache(on: sut)
    }

    func test_insert_withPreviousInsertion_shouldOverridePreviousInsertion() {
        let sut = makeSUT()

        assertThatInsertOverridesPreviousInsertion(on: sut)
    }

    func test_insert_whenInvalidStoreURL_shouldDeliverFailureResult() {
        let invalidStoreURL = URL(string: "invalid://store-url")
        let sut = makeSUT(storeURL: invalidStoreURL)

        assertThatInsertDeliversFailureResultOnInsertionError(on: sut)
    }

    func test_insert_whenInvalidStoreURL_shouldHaveNoSideEffects() {
        let invalidStoreURL = URL(string: "invalid://store-url")
        let sut = makeSUT(storeURL: invalidStoreURL)

        assertThatInsertHasNoSideEffectOnInsertionError(on: sut)
    }

    func test_deleteCachedFeed_whenEmptyCache_shouldNotDeliverError() {
        let sut = makeSUT()

        assertThatDeleteDoesNotReturnErrorOnEmptyCache(on: sut)
    }

    func test_deleteCachedFeed_whenEmptyCache_shouldHaveNoSideEffect() {
        let sut = makeSUT()

        assertThatDeleteHasNoSideEffectOnEmptyCache(on: sut)
    }

    func test_deleteCachedFeed_whenNonEmptyCache_shouldNotResultInError() {
        let sut = makeSUT()

        assertThatDeleteDoesNotReturnErrorOnNonEmptyCache(on: sut)
    }

    func test_deleteCachedFeed_whenNonEmptyCache_shouldResultInEmptyCache() {
        let sut = makeSUT()

        assertThatDeleteEmptiesCacheOnNonEmptyCache(on: sut)
    }

    func test_deleteCachedFeed_whenNoDeletionPermissionURL_shouldDeliverFailureResult() {
        let noDeletionPermissionURL = cachesDirectory()
        let sut = makeSUT(storeURL: noDeletionPermissionURL)

        assertThatDeleteDeliversFailureResultOnDeletionError(on: sut)
    }

    func test_deleteCachedFeed_whenNoDeletionPermissionURL_shouldHaveNoSideEffects() {
        let noDeletionPermissionURL = cachesDirectory()
        let sut = makeSUT(storeURL: noDeletionPermissionURL)

        assertThatDeleteHasNoSideEffectOnDeletionError(on: sut)
    }

    func test_feedStore_shouldRunSideEffectsSerially() {
        let sut = makeSUT(storeURL: testSpecificStoreURL())

        assertThatSideEffectsRunSerially(on: sut)
    }

    // MARK: - Helpers

    private func makeSUT(storeURL: URL? = nil, file: StaticString = #filePath, line: UInt = #line) -> FeedStore {
        let sut = CodableFeedStore(storeURL: storeURL ?? testSpecificStoreURL())

        trackForMemoryLeaks(on: sut, file: file, line: line)

        return sut
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
