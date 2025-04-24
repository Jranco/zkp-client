//
//  RestRequestProtocol.swift
//  zkp-client
//
//  Created by Thomas Segkoulis on 28.01.24.
//

import Foundation

/// A protocol defining requirements of an HTTP request.
public protocol RestRequestProtocol {
	var base: String { get }
	var path: String { get }
	var queryItems: [URLQueryItem]? { get }
	var method: HTTPMethod { get }
	var body: Data? { get }
}

public extension RestRequestProtocol {
	func execute() async throws -> (Data, URLResponse) {
		guard let url = URL(string: base+path) else {
			throw RestRequestError.malformedURLPath
		}
		var request = URLRequest(url: url)
		request.httpMethod = method.rawValue
		request.httpBody = body
		request.setValue("application/json", forHTTPHeaderField: "Content-Type")
		let data = try await URLSession.shared.data(for: request)
		return data
	}
}

/// Local errors thrown prior to executing a request.
enum RestRequestError: LocalizedError {
	case malformedURLPath

	var errorDescription: String? {
		switch self {
		case .malformedURLPath:
			return "The path of the url is malformed resulting in failure when creating the `URLRequest`"
		}
	}
}
