//
//  XCTestCase+FailableDeleteFeedStoreSpecs.swift
//  EssentialFeed
//
//  Created by Alessandro Moryta Suemasu on 16/04/26.
//

import XCTest
import EssentialFeed

extension FailableDeleteFeedStoreSpecs where Self: XCTestCase {
    func assertThatDeleteDeliversFailureResultOnDeletionError(on sut: FeedStore, file: StaticString = #filePath, line: UInt = #line) {
        let receivedError = deleteCache(from: sut)

        XCTAssertNotNil(receivedError, file: file, line: line)
    }

    func assertThatDeleteHasNoSideEffectOnDeletionError(on sut: FeedStore, file: StaticString = #filePath, line: UInt = #line) {
        deleteCache(from: sut)

        expect(sut, toRetrieve: FeedStore.RetrieveResult.success(.empty), file: file, line: line)
    }
}
