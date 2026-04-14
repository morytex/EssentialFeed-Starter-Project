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

    // MARK: - Helpers

    private func makeSUT(currentDate: @escaping () -> Date = Date.init, file: StaticString = #filePath, line: UInt = #line) -> (sut: LocalFeedLoader, store: FeedStoreSpy) {
        let store = FeedStoreSpy()
        let sut = LocalFeedLoader(store: store, currentDate: currentDate)

        trackForMemoryLeaks(on: store, file: file, line: line)
        trackForMemoryLeaks(on: sut, file: file, line: line)

        return (sut, store)
    }

}
