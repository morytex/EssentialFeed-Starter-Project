//
//  URLSessionHTTPClientTests.swift
//  EssentialFeed
//
//  Created by Alessandro Moryta Suemasu on 07/04/26.
//

import XCTest
import EssentialFeed

final class URLSessionHTTPClient: HTTPClient {
    private let session: URLSession

    struct UnexpectedValueRepresentation: Error {}

    init(session: URLSession = .shared) {
        self.session = session
    }

    func get(from url: URL, completion: @escaping (HTTPClientResult) -> Void) {
        session.dataTask(with: url) { data, response, error in
            if let error {
                completion(.failure(error))
                return
            }

            if let data, let response = response as? HTTPURLResponse {
                completion(.success(data, response))
                return
            }

            completion(.failure(UnexpectedValueRepresentation()))
        }.resume()
    }
}

final class URLSessionHTTPClientTests: XCTestCase {

    override func setUp() {
        super.setUp()
        URLProtocolStub.startInterceptingRequests()
    }

    override func tearDown() {
        URLProtocolStub.stopInterceptingRequests()
        super.tearDown( )
    }

    func test_getFromURL_shouldPerformsGETWithTheCorrectURL() {
        let url = anyURL()

        let expectation = expectation(description: "Wait for completion")
        URLProtocolStub.observeRequest { request in
            XCTAssertEqual(request.url, url)
            XCTAssertEqual(request.httpMethod, "GET")
            expectation.fulfill( )
        }

        makeSUT().get(from: url) { _ in }

        wait(for: [expectation], timeout: 1.0)
    }

    func test_getFromURL_whenRequestError_shouldFail() {
        let error = anyNSError()
        let receivedError = resultErrorFor(data: nil, response: nil, error: error) as? NSError
        XCTAssertEqual(receivedError?.domain, error.domain)
        XCTAssertEqual(receivedError?.code, error.code)
    }

    func test_getFromURL_whenInvalidRepresentationCases_shouldFail() {
        XCTAssertNotNil(resultErrorFor(data: nil, response: nil, error: nil))
        XCTAssertNotNil(resultErrorFor(data: nil, response: nonHTTPURLResponse(), error: nil))
        XCTAssertNotNil(resultErrorFor(data: anyData(), response: nil, error: nil))
        XCTAssertNotNil(resultErrorFor(data: anyData(), response: nil, error: anyNSError()))
        XCTAssertNotNil(resultErrorFor(data: nil, response: nonHTTPURLResponse(), error: anyNSError()))
        XCTAssertNotNil(resultErrorFor(data: nil, response: anyHTTPURLResponse(), error: anyNSError()))
        XCTAssertNotNil(resultErrorFor(data: anyData(), response: nonHTTPURLResponse(), error: anyNSError()))
        XCTAssertNotNil(resultErrorFor(data: anyData(), response: anyHTTPURLResponse(), error: anyNSError()))
        XCTAssertNotNil(resultErrorFor(data: anyData(), response: nonHTTPURLResponse(), error: nil))
    }

    func test_getFromURL_whenHTTPURLResponse_withAnyData_shouldSucceed() {
        let data = anyData()
        let response = anyHTTPURLResponse()

        let (receivedData, receivedResponse) = resultValuesFor(data: data, response: response, error: nil)

        XCTAssertEqual(receivedData, data)
        XCTAssertEqual(receivedResponse?.statusCode, response.statusCode)
        XCTAssertEqual(receivedResponse?.url, response.url)
    }

    func test_getFromURL_whenHTTPURLResponse_withNilData_shouldSucceedWithEmptyData() {
        let response = anyHTTPURLResponse()

        let (receivedData, receivedResponse) = resultValuesFor(data: nil, response: response, error: nil)

        let emptyData = Data()
        XCTAssertEqual(receivedData, emptyData)
        XCTAssertEqual(receivedResponse?.statusCode, response.statusCode)
        XCTAssertEqual(receivedResponse?.url, response.url)
    }

    // MARK: - Helpers

    private func makeSUT(file: StaticString = #file, line: UInt = #line) -> HTTPClient {
        let sut = URLSessionHTTPClient()

        trackForMemoryLeaks(on: sut, file: file, line: line)

        return sut
    }

    private func resultValuesFor(data: Data?, response: URLResponse?, error: Error?, file: StaticString = #file, line: UInt = #line) -> (Data?, HTTPURLResponse?) {

        let result = resultFor(data: data, response: response, error: error, file: file, line: line)

        var receivedValues: (Data?, HTTPURLResponse?)
        switch result {
        case let .success(data, response):
            receivedValues = (data, response)
        default:
            XCTFail("Expected to succeed, but got result \(result) instead")
        }

        return receivedValues
    }

    private func resultErrorFor(data: Data?, response: URLResponse?, error: Error?, file: StaticString = #file, line: UInt = #line) -> Error? {

        let result = resultFor(data: data, response: response, error: error, file: file, line: line)

        var receivedError: Error?
        switch result {
        case let .failure(error):
            receivedError = error
        default:
            XCTFail("Expected to fail, but got result \(result) instead")
        }

        return receivedError
    }

    private func resultFor(data: Data?, response: URLResponse?, error: Error?, file: StaticString = #file, line: UInt = #line) -> HTTPClientResult {

        let url = anyURL()
        URLProtocolStub.stub(url, data: data, response: response, error: error)

        let expectation = expectation(description: "Wait for completion")
        var receivedResult: HTTPClientResult!
        makeSUT(file: file, line: line).get(from: url) { result in
            receivedResult = result
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 1.0)
        return receivedResult

    }

    private func anyNSError() -> NSError {
        return NSError(domain: "an error", code: 1)
    }

    private func nonHTTPURLResponse() -> URLResponse {
        return URLResponse(url: anyURL(), mimeType: nil, expectedContentLength: 0, textEncodingName: nil)
    }

    private func anyHTTPURLResponse() -> HTTPURLResponse {
        return HTTPURLResponse(url: anyURL(), statusCode: 200, httpVersion: nil, headerFields: nil)!
    }

    private func anyData() -> Data {
        return Data("any data".utf8)
    }

    private func anyURL() -> URL {
        return URL(string: "https://any-url.com")!
    }

    private class URLProtocolStub: URLProtocol {

        private static var stub: Stub?
        private static var requestObserver: ((URLRequest) -> Void)?

        private struct Stub {
            let data: Data?
            let response: URLResponse?
            let error: Error?
        }

        static func stub(_ url: URL, data: Data? , response: URLResponse?, error: Error?) {
            stub = Stub(data: data, response: response, error: error)
        }

        static func observeRequest(observer: @escaping (URLRequest) -> Void) {
            URLProtocolStub.requestObserver = observer
        }

        static func startInterceptingRequests() {
            URLProtocol.registerClass(URLProtocolStub.self)
        }

        static func stopInterceptingRequests() {
            URLProtocol.unregisterClass(URLProtocolStub.self)
            stub = nil
            requestObserver = nil
        }

        override class func canInit(with request: URLRequest) -> Bool {
            URLProtocolStub.requestObserver?(request)
            return true
        }

        override class func canonicalRequest(for request: URLRequest) -> URLRequest {
            return request
        }

        override func startLoading() {
            if let data = URLProtocolStub.stub?.data {
                client?.urlProtocol(self, didLoad: data)
            }

            if let response = URLProtocolStub.stub?.response {
                client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            }

            if let error = URLProtocolStub.stub?.error {
                client?.urlProtocol(self, didFailWithError: error)
            }

            client?.urlProtocolDidFinishLoading(self)
        }

        override func stopLoading() {}
    }
}
