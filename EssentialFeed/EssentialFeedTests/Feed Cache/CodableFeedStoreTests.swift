//
//  CodableFeedStoreTests.swift
//  EssentialFeed
//
//  Created by Alessandro Moryta Suemasu on 15/04/26.
//

import XCTest
import EssentialFeed

private final class CodableFeedStore {
    func retrieveCachedFeed(completion: @escaping FeedStore.RetrieveCompletion) {
        completion(.empty)
    }
}

final class CodableFeedStoreTests: XCTestCase {
    func test_retrieveCachedFeed_whenEmptyStore_shouldDeliverEmptyResult() {
        let sut = CodableFeedStore()

        let expectation = expectation(description: "Wait for retrieval completion")
        sut.retrieveCachedFeed { result in
            switch result {
            case .empty:
                break
            default:
                XCTFail("Expected empty result")
            }

            expectation.fulfill( )
        }

        wait(for: [expectation], timeout: 1.0)
    }
}
