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

        let expectation = expectation(description: "Wait for completion")
        sut.load { result in
            switch result {
            case let .failure(error):
                XCTAssertEqual(error as NSError, retrievalError)
            default:
                XCTFail("Expected failure, got success")
            }
            expectation.fulfill()
        }
        store.completeRetrieval(with: retrievalError)

        wait(for: [expectation], timeout: 1.0)
    }


    // MARK: - Helpers

    private func makeSUT(currentDate: @escaping () -> Date = Date.init, file: StaticString = #filePath, line: UInt = #line) -> (sut: LocalFeedLoader, store: FeedStoreSpy) {
        let store = FeedStoreSpy()
        let sut = LocalFeedLoader(store: store, currentDate: currentDate)

        trackForMemoryLeaks(on: store, file: file, line: line)
        trackForMemoryLeaks(on: sut, file: file, line: line)

        return (sut, store)
    }

    private func anyNSError() -> NSError {
        return NSError(domain: "an error", code: 1)
    }

}
