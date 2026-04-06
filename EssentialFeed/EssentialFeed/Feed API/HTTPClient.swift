//
//  HTTPClient.swift
//  EssentialFeed
//
//  Created by Alessandro Moryta Suemasu on 06/04/26.
//

import Foundation

public enum HTTPClientResult {
    case success(Data, HTTPURLResponse)
    case failure(Error)
}

public protocol HTTPCLient {
    func get(from url: URL, completion: @escaping (HTTPClientResult) -> Void)
}
