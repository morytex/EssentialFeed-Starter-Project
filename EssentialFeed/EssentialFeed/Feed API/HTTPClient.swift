//
//  HTTPClient.swift
//  EssentialFeed
//
//  Created by Alessandro Moryta Suemasu on 06/04/26.
//

import Foundation

public protocol HTTPClient {

    typealias Result = Swift.Result<(Data, HTTPURLResponse), Error>

    /// Executes GET operation on informed `url`.
    ///
    /// The completion handler can be invoked in any thread. Clients are responsible to dispatch to appropriate thread, if needed.
    /// - Parameters:
    ///   - url: URL to execute the operation.
    ///   - completion: It is invoked with ``HTTPClientResult``.
    func get(from url: URL, completion: @escaping (Result) -> Void)
}
