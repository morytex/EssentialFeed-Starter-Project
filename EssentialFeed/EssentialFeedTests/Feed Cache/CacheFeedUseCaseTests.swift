//
//  CacheFeedUseCaseTests.swift
//  EssentialFeed
//
//  Created by Alessandro Moryta Suemasu on 09/04/26.
//

import XCTest

final class LocalFeedLoader {
    private let store: FeedStore

    init(store: FeedStore) {
        self.store = store
    }
}

final class FeedStore {
    var deleteCacheFeedCallCount: Int = 0
}

final class CacheFeedUseCaseTests: XCTestCase {
    func test_init_shouldNotDeleteCacheUponCreation() {
        let store = FeedStore()
        let _ = LocalFeedLoader(store: store)

        XCTAssertEqual(store.deleteCacheFeedCallCount, 0)
    }
}
