//
//  FeedCacheTestHelpers.swift
//  EssentialFeed
//
//  Created by Alessandro Moryta Suemasu on 14/04/26.
//

import Foundation
import EssentialFeed

func uniqueImageFeed() -> (models: [FeedImage], locals: [LocalFeedImage]) {
    let items = [uniqueImage()]
    let localItems = items.map { LocalFeedImage(id: $0.id, description: $0.description, location: $0.location, url: $0.url) }

    return (items, localItems)
}

func uniqueImage() -> FeedImage {
    return FeedImage(id: UUID(), description: nil, location: nil, url: anyURL())
}

extension Date {
    func adding(days: Int) -> Date {
        return Calendar(identifier: .gregorian)
            .date(byAdding: .day, value: days, to: self)!
    }

    func adding(seconds: TimeInterval) -> Date {
        return self + seconds
    }
}
