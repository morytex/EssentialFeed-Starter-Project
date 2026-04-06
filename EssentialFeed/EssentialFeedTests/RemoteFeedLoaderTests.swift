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

        sut.load { _ in }

        XCTAssertEqual(client.requestedURLs, [url])
    }

    func test_loadTwice_shouldRequestDataFromUrlTwice() {
        let url = URL(string: "https://example.com")!
        let (sut, client) = makeSUT(url: url)

        sut.load { _ in }
        sut.load { _ in }

        XCTAssertEqual(client.requestedURLs, [url, url])
    }

    func test_load_whenClientError_shouldReturnConnectivityError() {
        let (sut, client) = makeSUT()

        var capturedErrors = [RemoteFeedLoader.Error]()
        sut.load { capturedErrors.append($0) }
        let clientError = NSError(domain: "Test", code: 0)
        client.complete(with: clientError)

        XCTAssertEqual(capturedErrors, [.connectivity])
    }

    func test_load_whenStatusCodeError_shouldReturnInvalidDataError() {
        let (sut, client) = makeSUT()

        let samples = [199, 201, 300, 400, 500]
        samples.enumerated().forEach { index, code in
            var capturedErrors = [RemoteFeedLoader.Error]()
            sut.load { capturedErrors.append($0) }
            client.complete(withStatus: 400, at: index)

            XCTAssertEqual(capturedErrors, [.invalidData])
        }
    }

    func test_load_when200HTTPResponse_withInvalidJSON_shouldDeliversError() {
        let (sut, client) = makeSUT()

        var capturedErrors = [RemoteFeedLoader.Error]()
        sut.load { capturedErrors.append($0) }

        let invalidJSON = Data("Invalid JSON".utf8)
        client.complete(withStatus: 200, data: invalidJSON)

        XCTAssertEqual(capturedErrors, [.invalidData])
    }

    // MARK: - Helpers

    private func makeSUT(url: URL = URL(string: "https://example.com")!) -> (RemoteFeedLoader, HTTPClientSpy) {
        let client = HTTPClientSpy()
        let sut = RemoteFeedLoader(client: client, url: url)

        return (sut, client)
    }
}

final class HTTPClientSpy: HTTPCLient {
    var messages = [(url: URL, completion: (HTTPClientResult) -> Void)]()
    var requestedURLs: [URL] {
        messages.map { $0.url }
    }

    func get(from url: URL, completion: @escaping (HTTPClientResult) -> Void) {
        messages.append((url, completion))
    }

    func complete(with error: Error, at index: Int = 0) {
        messages[index].completion(.failure(error))
    }

    func complete(withStatus statusCode: Int, data: Data = Data(), at index: Int = 0) {
        let (url, completion) = messages[index]
        let response = HTTPURLResponse(
            url: url,
            statusCode: statusCode,
            httpVersion: nil,
            headerFields: nil
        )
        completion(.success(data, response!))
    }
}
