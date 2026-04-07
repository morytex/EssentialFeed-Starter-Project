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

        expect(sut, toCompleteWith: failure(.connectivity)) {
            let clientError = NSError(domain: "Test", code: 0)
            client.complete(with: clientError)
        }
    }

    func test_load_whenStatusCodeError_shouldReturnInvalidDataError() {
        let (sut, client) = makeSUT()

        let samples = [199, 201, 300, 400, 500]
        samples.enumerated().forEach { index, code in
            expect(sut, toCompleteWith: failure(.invalidData)) {
                client.complete(withStatus: 400, at: index)
            }
        }
    }

    func test_load_when200HTTPResponse_withInvalidJSON_shouldDeliversError() {
        let (sut, client) = makeSUT()

        expect(sut, toCompleteWith: failure(.invalidData)) {
            let invalidJSON = Data("Invalid JSON".utf8)
            client.complete(withStatus: 200, data: invalidJSON)
        }
    }

    func test_load_when200HTTPResponse_withEmptyList_shouldDeliversEmptyList() {
        let (sut, client) = makeSUT()

        expect(sut, toCompleteWith: LoadFeedResult.success([])) {
            let json = makeItemsJSON([])
            client.complete(withStatus: 200, data: json)
        }
    }

    func test_load_when200HTTPResponse_withValidData_shouldDeliversFeedItems() {
        let (sut, client) = makeSUT()

        let item1 = makeItem(
            id: UUID(),
            imageURL:  URL(string: "https://example.com")!
        )

        let item2 = makeItem(
            id: UUID(),
            description: "a description",
            location: "a location",
            imageURL:  URL(string: "https://example.com")!
        )

        let items = [item1.item, item2.item]

        expect(sut, toCompleteWith: .success(items)) {
            let json = makeItemsJSON([item1.json, item2.json])
            client.complete(withStatus: 200, data: json)
        }
    }

    func test_load_whenInstanceIsDeallocated_shouldNotDeliversResult() {
        let client = HTTPClientSpy()
        let url = URL(string: "https://example.com")!
        var sut: RemoteFeedLoader? = RemoteFeedLoader(client: client, url: url)

        var capturedResults = [RemoteFeedLoader.Result]()
        sut?.load { capturedResults.append($0) }

        sut = nil
        client.complete(withStatus: 200, data: makeItemsJSON([]))

        XCTAssertTrue(capturedResults.isEmpty)
    }

    // MARK: - Helpers

    private func expect(_ sut: RemoteFeedLoader, toCompleteWith expectedResult: RemoteFeedLoader.Result, when action: () -> Void, file: StaticString = #filePath, line: UInt = #line) {

        let expectation = expectation(description: "Wait load function to be completed")
        sut.load { receivedResult in
            switch (expectedResult, receivedResult) {
            case (.success(let lhs), .success(let rhs)):
                XCTAssertEqual(lhs, rhs, file: file, line: line)
            case let (.failure(lhs as RemoteFeedLoader.Error), .failure(rhs as RemoteFeedLoader.Error)):
                XCTAssertEqual(lhs, rhs, file: file, line: line)
            default:
                XCTFail("Expected result (\(expectedResult)), but got \(receivedResult)", file: file, line: line)
            }
            expectation.fulfill()
        }

        action()

        wait(for: [expectation], timeout: 1)
    }

    private func failure(_ error: RemoteFeedLoader.Error) -> RemoteFeedLoader.Result {
        return .failure(error)
    }

    private func makeSUT(url: URL = URL(string: "https://example.com")!, file: StaticString = #filePath, line: UInt = #line) -> (RemoteFeedLoader, HTTPClientSpy) {
        let client = HTTPClientSpy()
        let sut = RemoteFeedLoader(client: client, url: url)

        trackForMemoryLeaks(on: sut, file: file, line: line)
        trackForMemoryLeaks(on: client, file: file, line: line)

        return (sut, client)
    }

    private func makeItem(id: UUID, description: String? = nil, location: String? = nil, imageURL: URL) -> (item: FeedItem, json: [String: Any]) {
        let item = FeedItem(
            id: id,
            description: description,
            location: location,
            imageURL:  imageURL
        )

        let json = [
            "id": id.uuidString,
            "description": description,
            "location": location,
            "image":  imageURL.absoluteString
        ].compactMapValues { $0 }

        return (item, json)
    }

    private func makeItemsJSON(_ items: [[String: Any]]) -> Data {
        let json = ["items": items]
        let jsonData = try! JSONSerialization.data(withJSONObject: json)
        return jsonData
    }
}

final class HTTPClientSpy: HTTPClient {
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
