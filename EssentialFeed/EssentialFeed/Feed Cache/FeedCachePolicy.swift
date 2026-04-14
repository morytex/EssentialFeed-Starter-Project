//
//  FeedCachePolicy.swift
//  EssentialFeed
//
//  Created by Alessandro Moryta Suemasu on 14/04/26.
//

import Foundation

final class FeedCachePolicy {
    private static let calendar = Calendar(identifier: .gregorian)

    private init() { }

    private static var maxCacheAgeInDays: Int { 7 }

    static func validate(_ timestamp: Date, against date: Date) -> Bool {
        guard let maxCacheAge = calendar.date(byAdding: .day, value: maxCacheAgeInDays, to: timestamp) else {
            return false
        }

        return date < maxCacheAge
    }
}
