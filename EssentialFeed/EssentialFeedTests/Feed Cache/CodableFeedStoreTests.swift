//
//  CodableFeedStoreTests.swift
//  EssentialFeed
//
//  Created by Alessandro Moryta Suemasu on 15/04/26.
//

import XCTest
import EssentialFeed

private final class CodableFeedStore: FeedStore {

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

    func deleteCachedFeed(completion: @escaping DeleteCompletion) {
        guard FileManager.default.fileExists(atPath: storeURL.path) else {
            return completion(nil)
        }

        do {
            try FileManager.default.removeItem(at: storeURL)
            completion(nil)
        } catch {
            completion(error)
        }
    }

    func insert(_ feed: [LocalFeedImage], timestamp: Date, completion: @escaping InsertCompletion) {
        let encoder = JSONEncoder()
        do {
            let encoded = try encoder.encode(Cache(feed: feed.map(CodableFeedImage.init), timestamp: timestamp))
            try encoded.write(to: storeURL)
            completion(nil)
        } catch {
            completion(error)
        }
    }

    func retrieveCachedFeed(completion: @escaping RetrieveCompletion) {
        guard let data = try? Data(contentsOf: storeURL) else {
            return completion(.empty)
        }

        let decoder = JSONDecoder()
        do {
            let cache = try decoder.decode(Cache.self, from: data)
            completion(.found(feed: cache.localFeed, timestamp: cache.timestamp))
        } catch {
            completion(.failure(error))
        }
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
        let cache = uniqueCache()
        let sut = makeSUT()

        insert(cache, to: sut)

        expect(sut, toRetrieve: .found(feed: cache.feed, timestamp: cache.timestamp))
    }

    func test_retrieveCachedFeed_withNonEmptyCache_whenCalledTwice_shouldHaveNoSideEffect() {
        let cache = uniqueCache()
        let sut = makeSUT()

        insert(cache, to: sut)

        expect(sut, toRetrieveTwice: .found(feed: cache.feed, timestamp: cache.timestamp))
    }

    func test_retrieveCachedFeed_withInvalidData_shouldDeliverFailureResult() {
        let storeURL = testSpecificStoreURL()
        let sut = makeSUT(storeURL: storeURL)

        try! "invalid data".write(to: storeURL, atomically: false, encoding: .utf8)

        expect(sut, toRetrieve: .failure(anyNSError()))
    }

    func test_retrieveCachedFeed_withInvalidData_whenCalledTwice_shouldHaveNoSideEffect() {
        let storeURL = testSpecificStoreURL()
        let sut = makeSUT(storeURL: storeURL)

        try! "invalid data".write(to: storeURL, atomically: false, encoding: .utf8)

        expect(sut, toRetrieveTwice: .failure(anyNSError()))
    }

    func test_insert_withPreviousInsertion_shouldOverridePreviousInsertion() {
        let sut = makeSUT()

        let firstCache = uniqueCache()
        let firstInsertionError = insert(firstCache, to: sut)
        XCTAssertNil(firstInsertionError)

        let secondCache = uniqueCache()
        let secondInsertionError = insert(secondCache, to: sut)
        XCTAssertNil(secondInsertionError)

        expect(sut, toRetrieve: .found(feed: secondCache.feed, timestamp: secondCache.timestamp))
    }

    func test_insert_whenInvalidStoreURL_shouldDeliverError() {
        let invalidStoreURL = URL(string: "invalid://store-url")
        let cache = uniqueCache()
        let sut = makeSUT(storeURL: invalidStoreURL)

        let insertionError = insert(cache, to: sut)

        XCTAssertNotNil(insertionError)
    }

    func test_deleteCachedFeed_whenEmptyCache_shouldHaveNoSideEffect() {
        let sut = makeSUT()

        let receivedError = deleteCache(from: sut)
        XCTAssertNil(receivedError)

        expect(sut, toRetrieve: .empty)
    }

    func test_deleteCachedFeed_whenNonEmptyCache_shouldResultInEmptyCache() {
        let sut = makeSUT()
        insert(uniqueCache(), to: sut)

        let receivedError = deleteCache(from: sut)
        XCTAssertNil(receivedError)

        expect(sut, toRetrieve: .empty)
    }

    func test_deleteCachedFeed_whenNoDeletionPermissionURL_shouldDeliverError() {
        let noDeletionPermissionURL = cachesDirectory()
        let sut = makeSUT(storeURL: noDeletionPermissionURL)

        let receivedError = deleteCache(from: sut)
        XCTAssertNotNil(receivedError)
    }

    // MARK: - Helpers

    private func makeSUT(storeURL: URL? = nil, file: StaticString = #filePath, line: UInt = #line) -> CodableFeedStore {
        let sut = CodableFeedStore(storeURL: storeURL ?? testSpecificStoreURL())

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
    private func insert(_ cache: (feed: [LocalFeedImage], timestamp: Date), to sut: CodableFeedStore) -> Error? {
        var receiverError: Error?
        let expectation = expectation(description: "Wait for retrieval completion")
        sut.insert(cache.feed, timestamp: cache.timestamp) { error in
            receiverError = error
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)

        return receiverError
    }

    private func deleteCache(from sut: CodableFeedStore) -> Error? {
        var receivedError: Error?
        let expectation = expectation(description: "Wait for deletion completion")
        sut.deleteCachedFeed { error in
            receivedError = error
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)

        return receivedError
    }

    private func uniqueCache() -> (feed: [LocalFeedImage], timestamp: Date) {
        let feed = uniqueImageFeed()
        let timestamp = Date()
        return (feed: feed.locals, timestamp: timestamp)
    }

    private func testSpecificStoreURL() -> URL {
        return cachesDirectory()
            .appendingPathComponent("\(type(of: self)).cache")
    }

    private func cachesDirectory() -> URL {
        return FileManager.default
            .urls(for: .cachesDirectory, in: .userDomainMask).first!
    }

    private func setupEmptyStoreState() {
        deleteStoreArtifacts()
    }

    private func undoStoreSideEffects() {
        deleteStoreArtifacts()
    }

    private func deleteStoreArtifacts() {
        try? FileManager.default.removeItem(at: testSpecificStoreURL())
    }
}
