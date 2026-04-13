//
//  FeedStoreSpy.swift
//  EssentialFeed
//
//  Created by Alessandro Moryta Suemasu on 13/04/26.
//

import Foundation
import EssentialFeed

final class FeedStoreSpy: FeedStore {
    enum Messages: Equatable {
        case insert(feed: [LocalFeedImage], timestamp: Date)
        case retrieve
        case deletion
    }

    typealias Completion = (Error?) -> Void

    var receivedMessages = [Messages]()

    var deleteCompletions = [DeleteCompletion]()
    var insertCompletions = [InsertCompletion]()
    var retrieveCompletions = [RetrieveCompletion]()

    func deleteCachedFeed(completion: @escaping DeleteCompletion) {
        receivedMessages.append(.deletion)
        deleteCompletions.append(completion)
    }

    func insert(_ feed: [LocalFeedImage], timestamp: Date, completion: @escaping InsertCompletion) {
        receivedMessages.append(.insert(feed: feed, timestamp: timestamp))
        insertCompletions.append(completion)
    }

    func retrieveCachedFeed(completion: @escaping RetrieveCompletion) {
        receivedMessages.append(.retrieve)
        retrieveCompletions.append(completion)
    }

    func completeDeletion(with error: NSError, at index: Int = 0) {
        deleteCompletions[index](error)
    }

    func completeDeletionWithSuccess(at index: Int = 0) {
        deleteCompletions[index](nil)
    }

    func completeInsertion(with error: NSError, at index: Int = 0) {
        insertCompletions[index](error)
    }

    func completeInsertionWithSuccess(at index: Int = 0) {
        insertCompletions[index](nil)
    }

    func completeRetrieval(with error: NSError, at index: Int = 0 ) {
        retrieveCompletions[index](.failure(error))
    }

    func completeRetrievalWithEmptyCache(at index: Int = 0) {
        retrieveCompletions[index](.empty)
    }

    func completeRetrieval(with feed: [LocalFeedImage], timestamp: Date, at index: Int = 0 ) {
        retrieveCompletions[index](.found(feed: feed, timestamp: timestamp))
    }
}
