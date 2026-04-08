//
//  EssentialFeedAPIE2ETests.swift
//  EssentialFeedAPIE2ETests
//
//  Created by Alessandro Moryta Suemasu on 08/04/26.
//

import XCTest
import EssentialFeed

final class EssentialFeedAPIE2ETests: XCTestCase {

    func test_e2eTestServerGETFeedResult_matchesFixedTestAccountData() throws {
        let testServerURL = URL(string: "https://essentialdeveloper.com/feed-case-study/test-api/feed")!
        let client = URLSessionHTTPClient()
        let loader = RemoteFeedLoader(client: client, url: testServerURL)

        let expectation = expectation(description: "Wait loader to complete")
        loader.load { result in
            switch result {
            case .success(let feeds):
                let expectedCount = 8
                XCTAssertEqual(feeds.count, expectedCount, "Expected \(expectedCount) feed items, but got \(feeds.count)")
            default:
                XCTFail("Expected to succeed.")
            }
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 5.0)
    }

}
