//
//  CodableFeedStoreTests.swift
//  EssentialFeed
//
//  Created by Alessandro Moryta Suemasu on 15/04/26.
//

import XCTest
import EssentialFeed

private final class CodableFeedStore {

    private struct Cache: Codable {
        let feed: [CodableFeedImage]
        let timestamp: Date

        var localFeed: [LocalFeedImage] {
            feed.map(\.local)
        }
    }

    private struct CodableFeedImage: Codable {
        private let id: UUID
        private let description: String?
        private let location: String?
        private let url: URL

        init(_ image: LocalFeedImage) {
            self.id = image.id
            self.description = image.description
            self.location = image.location
            self.url = image.url
        }

        var local: LocalFeedImage {
            .init(id: id, description: description, location: location, url: url)
        }
    }

    private let storeURL: URL

    init(storeURL: URL) {
        self.storeURL = storeURL
    }

    func insert(_ feed: [LocalFeedImage], timestamp: Date, completion: @escaping FeedStore.InsertCompletion) {

        let encoder = JSONEncoder()
        let encoded = try! encoder.encode(Cache(feed: feed.map(CodableFeedImage.init), timestamp: timestamp))
        try! encoded.write(to: storeURL)

        completion(nil)
    }

    func retrieveCachedFeed(completion: @escaping FeedStore.RetrieveCompletion) {
        guard let data = try? Data(contentsOf: storeURL) else {
            return completion(.empty)
        }

        let decoder = JSONDecoder()
        let cache = try! decoder.decode(Cache.self, from: data)

        completion(.found(feed: cache.localFeed, timestamp: cache.timestamp))
    }
}

final class CodableFeedStoreTests: XCTestCase {

    override func setUp() {
        super.setUp()

        try? FileManager.default.removeItem(at: storeURL())
    }

    override func tearDown() {
        try? FileManager.default.removeItem(at: storeURL())

        super.tearDown()
    }

    func test_retrieveCachedFeed_withEmptyStore_shouldDeliverEmptyResult() {
        let sut = makeSUT()

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

    func test_retrieveCachedFeed_withEmptyStore_whenCalledTwice_shouldHaveNoSideEffect() {
        let sut = makeSUT()

        let expectation = expectation(description: "Wait for both retrieval completion")
        sut.retrieveCachedFeed { firstResult in
            sut.retrieveCachedFeed { secondResult in
                switch (firstResult, secondResult) {
                case (.empty, .empty):
                    break
                default:
                    XCTFail("Expected empty result on both calls")
                }

                expectation.fulfill( )
            }
        }

        wait(for: [expectation], timeout: 1.0)
    }

    func test_retrieveCachedFeed_withInsertedValue_shouldDeliverStoredValue() {
        let feed = uniqueImageFeed()
        let timestamp = Date()
        let sut = makeSUT()

        let expectation = expectation(description: "Wait for retrieval completion")
        sut.insert(feed.locals, timestamp: timestamp) { error in
            XCTAssertNil(error, "Expected feed to be inserted successfully")
            sut.retrieveCachedFeed { result in
                switch result {
                case let .found(receivedFeed, receivedTimestamp):
                    XCTAssertEqual(receivedFeed, feed.locals)
                    XCTAssertEqual(receivedTimestamp, timestamp)
                default:
                    XCTFail("Expected to retrieve \(feed) and \(timestamp), but got result \(result)")
                }

                expectation.fulfill( )
            }
        }

        wait(for: [expectation], timeout: 1.0)
    }

    // MARK: - Helpers

    private func makeSUT(file: StaticString = #filePath, line: UInt = #line) -> CodableFeedStore {
        let sut = CodableFeedStore(storeURL: storeURL())

        trackForMemoryLeaks(on: sut, file: file, line: line)

        return sut
    }

    private func storeURL() -> URL {
        return FileManager.default
            .urls(for: .documentDirectory, in: .userDomainMask)
            .first!
            .appendingPathComponent("image-feed.cache")
    }
}
