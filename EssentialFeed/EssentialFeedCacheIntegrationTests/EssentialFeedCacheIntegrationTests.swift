//
//  EssentialFeedCacheIntegrationTests.swift
//  EssentialFeedCacheIntegrationTests
//
//  Created by Alessandro Moryta Suemasu on 17/04/26.
//

import XCTest
import EssentialFeed

final class EssentialFeedCacheIntegrationTests: XCTestCase {

    override func setUp() {
        super.setUp()

        setupEmptyStoreState()
    }

    override func tearDown() {
        undoStoreSideEffects()

        super.tearDown()
    }
    
    func test_load_withEmptyCache_shouldDeliverNoItems() throws {
        let sut = try makeSUT()

        expect(sut, toLoad: [])
    }

    func test_load_whenItemsSavedOnPreviousInstance_shouldDeliverSavedItemsOnCurrentInstance() throws {
        let sutToPerformSave = try makeSUT()
        let sutToPerformLoad = try makeSUT()
        let feed = uniqueImageFeed().models

        let saveExpectation = expectation(description: "Wait for save to complete")
        sutToPerformSave.save(feed) { saveError in
            XCTAssertNil(saveError, "Expected save to not fail")
            saveExpectation.fulfill()
        }
        wait(for: [saveExpectation], timeout: 1.0)

        expect(sutToPerformLoad, toLoad: feed)
    }

    // MARK: - Helpers

    private func makeSUT(file: StaticString = #filePath, line: UInt = #line) throws -> LocalFeedLoader {
        let storeBundle = Bundle(for: CoreDataFeedStore.self)
        let storeURL = testSpecificStoreURL()
        let store = try CoreDataFeedStore(storeURL: storeURL, bundle: storeBundle)
        let sut = LocalFeedLoader(store: store, currentDate: Date.init)

        trackForMemoryLeaks(on: sut, file: file, line: line)
        trackForMemoryLeaks(on: store, file: file, line: line)

        return sut
    }

    private func expect(_ sut: LocalFeedLoader, toLoad expectedFeed: [FeedImage], file: StaticString = #filePath, line: UInt = #line) {
        let expectation = expectation(description: "Wait for load completion")
        sut.load { result in
            switch result {
            case let .success(imageFeed):
                XCTAssertEqual(imageFeed, expectedFeed, file: file, line: line)
            case let .failure(error):
                XCTFail("Expected successful feed result, but got \(error) instead", file: file, line: line)
            }
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 1.0)
    }

    private func testSpecificStoreURL() -> URL {
        return cachesDirectory().appendingPathComponent("\(type(of: self)).store")
    }

    private func cachesDirectory() -> URL {
        FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
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
