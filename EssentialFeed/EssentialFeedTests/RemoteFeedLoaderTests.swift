//
//  RemoteFeedLoaderTests.swift
//  EssentialFeed
//
//  Created by Alessandro Moryta Suemasu on 02/04/26.
//

import XCTest
import EssentialFeed

final class HTTPClientSpy: HTTPCLient {
    var requestedURLs = [URL]()

    func get(from url: URL) {
        requestedURLs.append(url)
    }
}

final class RemoteFeedLoaderTests: XCTestCase {

    func test_init_shouldNotRequestDataFromURL() {
        let (_, client) = makeSUT()

        XCTAssertNil(client.requestedURL)
    }

    func test_load_shouldRequestDataFromUrl() {
        let url = URL(string: "https://example.com")!
        let (sut, client) = makeSUT(url: url)

        sut.load()

        XCTAssertEqual(client.requestedURLs, [url])
    }

    func test_loadTwice_shouldRequestDataFromUrlTwice() {
        let url = URL(string: "https://example.com")!
        let (sut, client) = makeSUT(url: url)

        sut.load()
        sut.load()

        XCTAssertEqual(client.requestedURLs, [url, url])
    }

    // MARK: - Helpers

    private func makeSUT(url: URL = URL(string: "https://example.com")!) -> (RemoteFeedLoader, HTTPClientSpy) {
        let client = HTTPClientSpy()
        let sut = RemoteFeedLoader(client: client, url: url)

        return (sut, client)
    }
}
