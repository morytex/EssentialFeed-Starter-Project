//
//  RemoteFeedLoaderTests.swift
//  EssentialFeed
//
//  Created by Alessandro Moryta Suemasu on 02/04/26.
//

import XCTest
import EssentialFeed

final class RemoteFeedLoaderTests: XCTestCase {

    func test_init_shouldNotRequestDataFromURL() {
        let (_, client) = makeSUT()

        XCTAssertEqual(client.requestedURLs, [])
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

    func test_load_whenClientError_shouldReturnConnectivityError() {
        let url = URL(string: "https://example.com")!
        let (sut, client) = makeSUT(url: url)

        var capturedErrors = [RemoteFeedLoader.Error]()
        sut.load { capturedErrors.append($0) }
        let clientError = NSError(domain: "Test", code: 0)
        client.complete(with: clientError)

        XCTAssertEqual(client.requestedURLs, [url])
        XCTAssertEqual(capturedErrors, [.connectivity])
    }

    // MARK: - Helpers

    private func makeSUT(url: URL = URL(string: "https://example.com")!) -> (RemoteFeedLoader, HTTPClientSpy) {
        let client = HTTPClientSpy()
        let sut = RemoteFeedLoader(client: client, url: url)

        return (sut, client)
    }
}

final class HTTPClientSpy: HTTPCLient {
    var completions = [(Error) -> Void]()
    var requestedURLs = [URL]()

    func get(from url: URL, completion: @escaping (Error) -> Void) {
        completions.append(completion)
        requestedURLs.append(url)
    }

    func complete(with error: Error) {
        completions.removeFirst()(error)
    }
}
