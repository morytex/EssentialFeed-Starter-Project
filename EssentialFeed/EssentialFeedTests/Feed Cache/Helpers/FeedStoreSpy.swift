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
        deleteCompletions[index](.failure(error))
    }

    func completeDeletionWithSuccess(at index: Int = 0) {
        deleteCompletions[index](.success(()))
    }

    func completeInsertion(with error: NSError, at index: Int = 0) {
        insertCompletions[index](.failure(error))
    }

    func completeInsertionWithSuccess(at index: Int = 0) {
        insertCompletions[index](.success(()))
    }

    func completeRetrieval(with error: NSError, at index: Int = 0 ) {
        retrieveCompletions[index](.failure(error))
    }

    func completeRetrievalWithEmptyCache(at index: Int = 0) {
        retrieveCompletions[index](.success(.none))
    }

    func completeRetrieval(with feed: [LocalFeedImage], timestamp: Date, at index: Int = 0 ) {
        retrieveCompletions[index](.success(CachedFeed(feed: feed, timestamp: timestamp)))
    }
}
