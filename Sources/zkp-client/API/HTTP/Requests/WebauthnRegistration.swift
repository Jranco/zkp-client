//
//  WebauthnRegistration.swift
//  zkp-client
//
//  Created by Thomas Segkoulis on 14.09.24.
//

import Foundation

public struct WebauthnRegistration: RestRequestProtocol {
	public var base: String
	public var path: String = "registerWebauthn"
	public var queryItems: [URLQueryItem]?
	public var method: HTTPMethod { .POST }
	public var body: Data?
	
	public init(
		base: String,
		path: String = "/registerWebauthn",
		queryItems: [URLQueryItem]? = nil,
		body: Data? = nil
	) {
		self.base = base
		self.path = path
		self.queryItems = queryItems
		self.body = body
	}
}
