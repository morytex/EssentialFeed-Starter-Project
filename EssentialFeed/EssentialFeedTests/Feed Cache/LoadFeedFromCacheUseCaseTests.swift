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

    func test_load_shouldRequestCacheRetrieval() {
        let (sut, store) = makeSUT()

        sut.load { _ in }

        XCTAssertEqual(store.receivedMessages, [.retrieve])
    }

    func test_load_withCacheRetrievalError_shouldFailWithError() {
        let (sut, store) = makeSUT()
        let retrievalError = anyNSError()

        expect(sut, toCompleteWith: .failure(retrievalError)) {
            store.completeRetrieval(with: retrievalError)
        }
    }

    func test_load_withEmptyCache_shouldCompleteWithEmptyFeed() {
        let (sut, store) = makeSUT()

        expect(sut, toCompleteWith: .success([])) {
            store.completeRetrievalWithEmptyCache()
        }
    }

    func test_load_withLessThanSevenDaysOldCachedFeed_shouldDeliverFeedImages() {
        let fixedCurrentDate = Date()
        let (sut, store) = makeSUT { fixedCurrentDate }

        let feedImage = uniqueImageFeed()
        let lessThanSevenDaysOldTimestamp = fixedCurrentDate
            .adding(days: -7)
            .adding(seconds: 1)
        expect(sut, toCompleteWith: .success(feedImage.models)) {
            store.completeRetrieval(with: feedImage.locals, timestamp: lessThanSevenDaysOldTimestamp)
        }
    }

    func test_load_withSevenDaysOldCachedFeed_shouldNotDeliverFeedImages() {
        let fixedCurrentDate = Date()
        let (sut, store) = makeSUT { fixedCurrentDate }

        let sevenDaysOldTimestamp = fixedCurrentDate
            .adding(days: -7)
        expect(sut, toCompleteWith: .success([])) {
            store.completeRetrieval(with: uniqueImageFeed().locals, timestamp: sevenDaysOldTimestamp)
        }
    }

    func test_load_withMoreThanSevenDaysOldCachedFeed_shouldNotDeliverFeedImages() {
        let fixedCurrentDate = Date()
        let (sut, store) = makeSUT { fixedCurrentDate }

        let moreThanSevenDaysOldTimestamp = fixedCurrentDate
            .adding(days: -7)
            .adding(seconds: -1)
        expect(sut, toCompleteWith: .success([])) {
            store.completeRetrieval(with: uniqueImageFeed().locals, timestamp: moreThanSevenDaysOldTimestamp)
        }
    }

    func test_load_whenRetrievalError_shouldDeleteCachedFeed() {
        let (sut, store) = makeSUT()
        let retrievalError = anyNSError()

        expect(sut, toCompleteWith: .failure(retrievalError)) {
            store.completeRetrieval(with: retrievalError)
        }

        XCTAssertEqual(store.receivedMessages, [.retrieve, .deletion])
    }

    func test_load_withEmptyCache_shouldNotDeleteCachedFeed() {
        let (sut, store) = makeSUT()

        expect(sut, toCompleteWith: .success([])) {
            store.completeRetrievalWithEmptyCache()
        }

        XCTAssertEqual(store.receivedMessages, [.retrieve])
    }

    func test_load_withLessThanSevenDaysOldCachedFeed_shouldNotDeleteCachedFeed() {
        let fixedCurrentDate = Date()
        let (sut, store) = makeSUT { fixedCurrentDate }

        let feedImage = uniqueImageFeed()
        let lessThanSevenDaysOldTimestamp = fixedCurrentDate
            .adding(days: -7)
            .adding(seconds: 1)
        expect(sut, toCompleteWith: .success(feedImage.models)) {
            store.completeRetrieval(with: feedImage.locals, timestamp: lessThanSevenDaysOldTimestamp)
        }

        XCTAssertEqual(store.receivedMessages, [.retrieve])
    }

    func test_load_withSevenDaysOldCachedFeed_shouldDeleteCachedFeed() {
        let fixedCurrentDate = Date()
        let (sut, store) = makeSUT { fixedCurrentDate }

        let sevenDaysOldTimestamp = fixedCurrentDate
            .adding(days: -7)
        expect(sut, toCompleteWith: .success([])) {
            store.completeRetrieval(with: uniqueImageFeed().locals, timestamp: sevenDaysOldTimestamp)
        }

        XCTAssertEqual(store.receivedMessages, [.retrieve, .deletion])
    }

    func test_load_withMoreThanSevenDaysOldCachedFeed_shouldDeleteCachedFeed() {
        let fixedCurrentDate = Date()
        let (sut, store) = makeSUT { fixedCurrentDate }

        let moreThanSevenDaysOldTimestamp = fixedCurrentDate
            .adding(days: -7)
            .adding(seconds: -1)
        expect(sut, toCompleteWith: .success([])) {
            store.completeRetrieval(with: uniqueImageFeed().locals, timestamp: moreThanSevenDaysOldTimestamp)
        }

        XCTAssertEqual(store.receivedMessages, [.retrieve, .deletion])
    }

    func test_load_whenInstanceIsDeallocated_shouldNotDeliverLoadResult() {
        let store = FeedStoreSpy()
        var sut: LocalFeedLoader? = LocalFeedLoader(store: store, currentDate: Date.init)

        var receivedResults = [LocalFeedLoader.LoadResult]()
        sut?.load() { result in
            receivedResults.append(result)
        }

        sut = nil
        store.completeRetrievalWithEmptyCache()

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

    private func expect(_ sut: LocalFeedLoader, toCompleteWith expectedResult: LocalFeedLoader.LoadResult, when action: () -> Void, file: StaticString = #filePath, line: UInt = #line) {
        let expectation = expectation(description: "Wait for completion")
        sut.load { receivedResult in
            switch (receivedResult, expectedResult) {
            case let (.success(receivedImages), .success(expectedImages)):
                XCTAssertEqual(receivedImages, expectedImages, file: file, line: line)
            case let (.failure(receivedError as NSError), .failure(expectedError as NSError)):
                XCTAssertEqual(receivedError, expectedError, file: file, line: line)
            default:
                XCTFail("Expected \(expectedResult), but got \(receivedResult)", file: file, line: line)
            }
            expectation.fulfill()
        }

        action()

        wait(for: [expectation], timeout: 1.0)
    }

    private func uniqueImageFeed() -> (models: [FeedImage], locals: [LocalFeedImage]) {
        let items = [uniqueImage()]
        let localItems = items.map { LocalFeedImage(id: $0.id, description: $0.description, location: $0.location, url: $0.url) }

        return (items, localItems)
    }

    private func uniqueImage() -> FeedImage {
        return FeedImage(id: UUID(), description: nil, location: nil, url: anyURL())
    }

    private func anyURL() -> URL {
        return URL(string: "https://any-url.com")!
    }

    private func anyNSError() -> NSError {
        return NSError(domain: "an error", code: 1)
    }

}

private extension Date {
    func adding(days: Int) -> Date {
        return Calendar(identifier: .gregorian)
            .date(byAdding: .day, value: days, to: self)!
    }

    func adding(seconds: TimeInterval) -> Date {
        return self + seconds
    }
}
