//
//  XCTestCase+FeedStoreSpecs.swift
//  EssentialFeed
//
//  Created by Alessandro Moryta Suemasu on 16/04/26.
//

import XCTest
import EssentialFeed

extension FeedStoreSpecs where Self: XCTestCase {
    func expect(_ sut: FeedStore, toRetrieveTwice result: RetrieveCachedFeedResult) {
        expect(sut, toRetrieve: result)
        expect(sut, toRetrieve: result)
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
}
