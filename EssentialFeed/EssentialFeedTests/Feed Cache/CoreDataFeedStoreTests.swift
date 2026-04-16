//
//  CoreDataFeedStoreTests.swift
//  EssentialFeed
//
//  Created by Alessandro Moryta Suemasu on 16/04/26.
//

import XCTest
import EssentialFeed
import CoreData

private class ManagedCache: NSManagedObject {
    @NSManaged var timestamp: Date
    @NSManaged var feed: NSOrderedSet
}

private class ManagedFeedImage: NSManagedObject {
    @NSManaged var id: UUID
    @NSManaged var imageDescription: String?
    @NSManaged var location: String?
    @NSManaged var url: URL
    @NSManaged var cache: ManagedCache
}

private final class CoreDataFeedStore: FeedStore {
    func insert(_ feed: [LocalFeedImage], timestamp: Date, completion: @escaping InsertCompletion) {}

    func deleteCachedFeed(completion: @escaping DeleteCompletion) { }

    func retrieveCachedFeed(completion: @escaping RetrieveCompletion) {
        completion(.empty)
    }
}

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

    }

    func test_retrieveCachedFeed_withNonEmptyCache_shouldHaveNoSideEffect() {

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
        let sut = CoreDataFeedStore()

        trackForMemoryLeaks(on: sut, file: file, line: line)

        return sut
    }
}
