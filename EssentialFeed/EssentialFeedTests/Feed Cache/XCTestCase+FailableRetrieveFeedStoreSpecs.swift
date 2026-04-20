//
//  XCTestCase+FailableRetrieveFeedStoreSpecs.swift
//  EssentialFeed
//
//  Created by Alessandro Moryta Suemasu on 16/04/26.
//

import XCTest
import EssentialFeed

extension FailableRetrieveFeedStoreSpecs where Self: XCTestCase {
    func assertThatRetrieveDeliversFailureResultOnRetrievalError(on sut: FeedStore, file: StaticString = #filePath, line: UInt = #line) {
        expect(sut, toRetrieve: FeedStore.RetrieveResult.failure(anyNSError()), file: file, line: line)
    }

    func assertThatRetrieveHasNoSideEffectOnRetrievalError(on sut: FeedStore, file: StaticString = #filePath, line: UInt = #line) {
        expect(sut, toRetrieveTwice: FeedStore.RetrieveResult.failure(anyNSError()), file: file, line: line)
    }
}
