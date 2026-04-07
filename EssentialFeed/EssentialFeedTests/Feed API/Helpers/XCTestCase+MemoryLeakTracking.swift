//
//  XCTestCase+MemoryLeakTracking.swift
//  EssentialFeed
//
//  Created by Alessandro Moryta Suemasu on 07/04/26.
//

import XCTest

extension XCTestCase {
    func trackForMemoryLeaks(on instance: AnyObject, file: StaticString = #filePath, line: UInt = #line) {
        addTeardownBlock { [weak instance] in
            XCTAssertNil(instance, "Instance should be deallocated. Potential memory leak.", file: file, line: line)
        }
    }
}
