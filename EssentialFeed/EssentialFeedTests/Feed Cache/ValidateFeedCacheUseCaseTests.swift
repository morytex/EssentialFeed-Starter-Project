//
//  ValidateFeedCacheUseCaseTests.swift
//  EssentialFeed
//
//  Created by Alessandro Moryta Suemasu on 14/04/26.
//

import XCTest
import EssentialFeed

final class ValidateFeedCacheUseCaseTests: XCTestCase {

    func test_init_shouldNotValidateCacheUponCreation() {
        let (_, store) = makeSUT()

        XCTAssertEqual(store.receivedMessages, [])
    }

    func test_validateCache_whenRetrievalError_shouldDeleteCachedFeed() {
        let (sut, store) = makeSUT()
        let retrievalError = anyNSError()

        sut.validateCache()
        store.completeRetrieval(with: retrievalError)

        XCTAssertEqual(store.receivedMessages, [.retrieve, .deletion])
    }

    func test_validateCache_withEmptyCache_shouldNotDeleteCachedFeed() {
        let (sut, store) = makeSUT()

        sut.validateCache()
        store.completeRetrievalWithEmptyCache()

        XCTAssertEqual(store.receivedMessages, [.retrieve])
    }

    func test_validateCache_withLessThanSevenDaysOldCachedFeed_shouldNotDeleteCachedFeed() {
        let fixedCurrentDate = Date()
        let (sut, store) = makeSUT { fixedCurrentDate }

        let feedImage = uniqueImageFeed()
        let lessThanSevenDaysOldTimestamp = fixedCurrentDate
            .adding(days: -7)
            .adding(seconds: 1)

        sut.validateCache()
        store.completeRetrieval(with: feedImage.locals, timestamp: lessThanSevenDaysOldTimestamp)

        XCTAssertEqual(store.receivedMessages, [.retrieve])
    }

    func test_validateCache_withSevenDaysOldCachedFeed_shouldDeleteCachedFeed() {
        let fixedCurrentDate = Date()
        let (sut, store) = makeSUT { fixedCurrentDate }

        let sevenDaysOldTimestamp = fixedCurrentDate
            .adding(days: -7)

        sut.validateCache()
        store.completeRetrieval(with: uniqueImageFeed().locals, timestamp: sevenDaysOldTimestamp)

        XCTAssertEqual(store.receivedMessages, [.retrieve, .deletion])
    }

    func test_validateCache_withMoreThanSevenDaysOldCachedFeed_shouldDeleteCachedFeed() {
        let fixedCurrentDate = Date()
        let (sut, store) = makeSUT { fixedCurrentDate }

        let moreThanSevenDaysOldTimestamp = fixedCurrentDate
            .adding(days: -7)
            .adding(seconds: -1)

        sut.validateCache()
        store.completeRetrieval(with: uniqueImageFeed().locals, timestamp: moreThanSevenDaysOldTimestamp)

        XCTAssertEqual(store.receivedMessages, [.retrieve, .deletion])
    }

    func test_validateCache_whenInstanceIsDeallocated_withRetrievalError_shouldNotDeleteCachedFeed() {
        let store = FeedStoreSpy()
        var sut: LocalFeedLoader? = LocalFeedLoader(store: store, currentDate: Date.init)

        var receivedResults = [LocalFeedLoader.LoadResult]()
        sut?.validateCache()

        sut = nil
        store.completeRetrieval(with: anyNSError())

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

}
