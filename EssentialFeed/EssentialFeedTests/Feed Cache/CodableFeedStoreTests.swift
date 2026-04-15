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

        expect(sut, toRetrieve: .empty)
        expect(sut, toRetrieve: .empty)
    }

    func test_retrieveCachedFeed_withNonEmptyCache_shouldDeliverStoredValue() {
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
                    XCTFail("Expected to retrieve \(feed) and \(timestamp), but got \(result)")
                }

                expectation.fulfill( )
            }
        }

        wait(for: [expectation], timeout: 1.0)
    }

    func test_retrieveCachedFeed_withNonEmptyCache_whenCalledTwice_shouldHaveNoSideEffect() {
        let feed = uniqueImageFeed()
        let timestamp = Date()
        let sut = makeSUT()

        let expectation = expectation(description: "Wait for retrieval completion")
        sut.insert(feed.locals, timestamp: timestamp) { error in
            XCTAssertNil(error, "Expected feed to be inserted successfully")
            sut.retrieveCachedFeed { firstResult in
                sut.retrieveCachedFeed { secondResult in
                    switch (firstResult, secondResult) {
                    case let (.found(firstFeed, firstTimestamp), .found(secondFeed, secondTimestamp)):
                        XCTAssertEqual(firstFeed, feed.locals)
                        XCTAssertEqual(firstTimestamp, timestamp)

                        XCTAssertEqual(secondFeed, feed.locals)
                        XCTAssertEqual(secondTimestamp, timestamp)
                    default:
                        XCTFail("Expected to retrieve \(feed) and \(timestamp), but got \(firstResult) and \(secondResult)")
                    }

                    expectation.fulfill( )
                }
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

    private func expect(_ sut: CodableFeedStore, toRetrieve result: RetrieveCachedFeedResult) {
        let expectation = expectation(description: "Wait for retrieval completion")
        sut.retrieveCachedFeed { receivedResult in
            switch (receivedResult, result) {
            case (.empty, .empty):
                break
            default:
                XCTFail("Expected result to be \(result), but got \(receivedResult)")
            }
            expectation.fulfill( )
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
