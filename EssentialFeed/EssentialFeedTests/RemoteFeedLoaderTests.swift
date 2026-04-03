//
//  RemoteFeedLoaderTests.swift
//  EssentialFeed
//
//  Created by Alessandro Moryta Suemasu on 02/04/26.
//

import XCTest
import EssentialFeed

final class HTTPClientSpy: HTTPCLient {
    var requestedURL: URL?
    
    func get(from url: URL) {
        requestedURL = url
    }
}

final class RemoteFeedLoaderTests: XCTestCase {
    
    func test_init_shouldNotRequestDataFromURL() {
        let (_, client) = makeSUT()
        
        XCTAssertNil(client.requestedURL)
    }
    
    func test_load_shouldRequestDataFromUrl() {
        let url = URL(string: "https://example.com")!
        let (sut, client) = makeSUT(url: url)
        sut.load()
        
        XCTAssertNotNil(client.requestedURL)
    }
    
    // MARK: - Helpers
    
    private func makeSUT(url: URL = URL(string: "https://example.com")!) -> (RemoteFeedLoader, HTTPClientSpy) {
        let client = HTTPClientSpy()
        let sut = RemoteFeedLoader(client: client, url: url)
        
        return (sut, client)
    }
}
