//
//  FeedStoreSpecs.swift
//  EssentialFeed
//
//  Created by Alessandro Moryta Suemasu on 16/04/26.
//

protocol FeedStoreSpecs {
    func test_retrieveCachedFeed_withEmptyCache_shouldDeliverEmptyResult()
    func test_retrieveCachedFeed_withEmptyCache_shouldHaveNoSideEffect()
    func test_retrieveCachedFeed_withNonEmptyCache_shouldDeliverFoundResult()
    func test_retrieveCachedFeed_withNonEmptyCache_shouldHaveNoSideEffect()
    func test_insert_withPreviousInsertion_shouldOverridePreviousInsertion()
    func test_deleteCachedFeed_whenEmptyCache_shouldNotDeliverError()
    func test_deleteCachedFeed_whenEmptyCache_shouldHaveNoSideEffect()
    func test_deleteCachedFeed_whenNonEmptyCache_shouldNotResultInError()
    func test_deleteCachedFeed_whenNonEmptyCache_shouldResultInEmptyCache()
    func test_feedStore_shouldRunSideEffectsSerially()
}

protocol FailableRetrieveFeedStoreSpecs: FeedStoreSpecs {
    func test_retrieveCachedFeed_withInvalidData_shouldDeliverFailureResult()
    func test_retrieveCachedFeed_withInvalidData_shouldHaveNoSideEffect()
}

protocol FailableInsertFeedStoreSpecs: FeedStoreSpecs {
    func test_insert_whenInvalidStoreURL_shouldDeliverFailureResult()
    func test_insert_whenInvalidStoreURL_shouldHaveNoSideEffects()
}

protocol FailableDeleteFeedStoreSpecs: FeedStoreSpecs {
    func test_deleteCachedFeed_whenNoDeletionPermissionURL_shouldDeliverFailureResult()
    func test_deleteCachedFeed_whenNoDeletionPermissionURL_shouldHaveNoSideEffects()
}

typealias FailableFeedStoreSpecs = FailableRetrieveFeedStoreSpecs & FailableInsertFeedStoreSpecs & FailableDeleteFeedStoreSpecs
