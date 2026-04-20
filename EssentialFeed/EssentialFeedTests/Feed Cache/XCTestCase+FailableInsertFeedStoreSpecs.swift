//
//  XCTestCase+FailableInsertFeedStoreSpecs.swift
//  EssentialFeed
//
//  Created by Alessandro Moryta Suemasu on 16/04/26.
//

import XCTest
import EssentialFeed

extension FailableInsertFeedStoreSpecs where Self: XCTestCase {
    func assertThatInsertDeliversFailureResultOnInsertionError(on sut: FeedStore, file: StaticString = #filePath, line: UInt = #line) {
        let cache = uniqueCache()

        let insertionError = insert(cache, to: sut)

        XCTAssertNotNil(insertionError, file: file, line: line)
    }

    func assertThatInsertHasNoSideEffectOnInsertionError(on sut: FeedStore, file: StaticString = #filePath, line: UInt = #line) {
        let cache = uniqueCache()

        insert(cache, to: sut)

        expect(sut, toRetrieve: .success(.empty), file: file, line: line)
    }
}
