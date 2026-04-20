//
//  SharedTestHelpers.swift
//  EssentialFeed
//
//  Created by Alessandro Moryta Suemasu on 14/04/26.
//

import Foundation

func anyURL() -> URL {
    return URL(string: "https://any-url.com")!
}

func anyNSError() -> NSError {
    return NSError(domain: "an error", code: 1)
}
