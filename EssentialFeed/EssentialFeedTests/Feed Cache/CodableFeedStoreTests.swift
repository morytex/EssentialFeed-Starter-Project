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
        setupEmptyStoreState()
    }

    override func tearDown() {
        undoStoreSideEffects()
        super.tearDown()
    }

    func test_retrieveCachedFeed_withEmptyCache_shouldDeliverEmptyResult() {
        let sut = makeSUT()

        expect(sut, toRetrieve: .empty)
    }

    func test_retrieveCachedFeed_withEmptyCache_whenCalledTwice_shouldHaveNoSideEffect() {
        let sut = makeSUT()

        expect(sut, toRetrieveTwice: .empty)
    }

    func test_retrieveCachedFeed_withNonEmptyCache_shouldDeliverFoundResult() {
        let feed = uniqueImageFeed()
        let timestamp = Date()
        let cache = (feed: feed.locals, timestamp: timestamp)
        let sut = makeSUT()

        insert(cache, to: sut)

        expect(sut, toRetrieve: .found(feed: feed.locals, timestamp: timestamp))
    }

    func test_retrieveCachedFeed_withNonEmptyCache_whenCalledTwice_shouldHaveNoSideEffect() {
        let feed = uniqueImageFeed()
        let timestamp = Date()
        let cache = (feed: feed.locals, timestamp: timestamp)
        let sut = makeSUT()

        insert(cache, to: sut)

        expect(sut, toRetrieveTwice: .found(feed: feed.locals, timestamp: timestamp))
    }

    // MARK: - Helpers

    private func makeSUT(file: StaticString = #filePath, line: UInt = #line) -> CodableFeedStore {
        let sut = CodableFeedStore(storeURL: storeURL())

        trackForMemoryLeaks(on: sut, file: file, line: line)

        return sut
    }

    private func expect(_ sut: CodableFeedStore, toRetrieveTwice result: RetrieveCachedFeedResult) {
        expect(sut, toRetrieve: result)
        expect(sut, toRetrieve: result)
    }

    private func expect(_ sut: CodableFeedStore, toRetrieve result: RetrieveCachedFeedResult, file: StaticString = #filePath, line: UInt = #line) {
        let expectation = expectation(description: "Wait for retrieval completion")
        sut.retrieveCachedFeed { receivedResult in
            switch (receivedResult, result) {
            case (.empty, .empty):
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

    private func insert(_ cache: (feed: [LocalFeedImage], timestamp: Date), to sut: CodableFeedStore) {
        let expectation = expectation(description: "Wait for retrieval completion")
        sut.insert(cache.feed, timestamp: cache.timestamp) { error in
            XCTAssertNil(error, "Expected feed to be inserted successfully")
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
    }

    private func storeURL() -> URL {
        return FileManager.default
            .urls(for: .cachesDirectory, in: .userDomainMask).first!
            .appendingPathComponent("\(type(of: self)).cache")
    }

    private func setupEmptyStoreState() {
        deleteStoreArtifacts()
    }

    private func undoStoreSideEffects() {
        deleteStoreArtifacts()
    }

    private func deleteStoreArtifacts() {
        try? FileManager.default.removeItem(at: storeURL())
    }
}
