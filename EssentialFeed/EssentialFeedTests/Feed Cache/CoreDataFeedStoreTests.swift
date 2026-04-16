//
//  CoreDataFeedStoreTests.swift
//  EssentialFeed
//
//  Created by Alessandro Moryta Suemasu on 16/04/26.
//

import XCTest
import EssentialFeed

final class CoreDataFeedStoreTests: XCTestCase, FeedStoreSpecs {
    func test_retrieveCachedFeed_withEmptyCache_shouldDeliverEmptyResult() {
        let sut = makeSUT()

        assertThatRetrieveDeliversEmptyOnEmptyCache(on: sut)
    }

    func test_retrieveCachedFeed_withEmptyCache_shouldHaveNoSideEffect() {
        let sut = makeSUT()

        assertThatRetrieveDeliversEmptyOnEmptyCache(on: sut)
    }

    func test_retrieveCachedFeed_withNonEmptyCache_shouldDeliverFoundResult() {
        let sut = makeSUT()

        assertThatRetrieveDeliversFoundResultOnNonEmptyCache(on: sut)
    }

    func test_retrieveCachedFeed_withNonEmptyCache_shouldHaveNoSideEffect() {
        let sut = makeSUT()

        assertThatRetrieveHasNoSideEffectOnNonEmptyCache(on: sut)
    }

    func test_insert_withPreviousInsertion_shouldOverridePreviousInsertion() {

    }

    func test_deleteCachedFeed_whenEmptyCache_shouldNotDeliverError() {

    }

    func test_deleteCachedFeed_whenEmptyCache_shouldHaveNoSideEffect() {

    }

    func test_deleteCachedFeed_whenNonEmptyCache_shouldNotResultInError() {

    }

    func test_deleteCachedFeed_whenNonEmptyCache_shouldResultInEmptyCache() {

    }

    func test_feedStore_shouldRunSideEffectsSerially() {

    }

    // MARK: - Helpers

    private func makeSUT(file: StaticString = #filePath, line: UInt = #line) -> FeedStore {
        let storeBundle = Bundle(for: CoreDataFeedStore.self)
        let storeURL = URL(fileURLWithPath: "/dev/null")
        let sut = try! CoreDataFeedStore(storeURL: storeURL, bundle: storeBundle)

        trackForMemoryLeaks(on: sut, file: file, line: line)

        return sut
    }
}
