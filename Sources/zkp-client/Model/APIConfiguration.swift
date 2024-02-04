//
//  APIConfiguration.swift
//  zkp-client
//
//  Created by Thomas Segkoulis on 31.01.24.
//

/// A protocol describing requirements to connect to the remote server providing the api  and websocket services.
public protocol APIConfigurating {
	/// Base url of the web-socket api.
	var baseWSURL: String {get }
	/// Base url of the restful api.
	var baseHTTPURL: String {get }
}

/// Remote server configuration providing the `api`  and `websocket` services.
public struct APIConfiguration: APIConfigurating {
	public let baseWSURL: String
	public let baseHTTPURL: String
	public init(
		baseWSURL: String,
		baseHTTPURL: String
	) {
		self.baseWSURL = baseWSURL
		self.baseHTTPURL = baseHTTPURL
	}
}
