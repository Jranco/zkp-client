//
//  APIConfiguration.swift
//  zkp-client
//
//  Created by Thomas Segkoulis on 31.01.24.
//

/// A protocol describing requirements to connect to the remote server providing the api  and websocket services.
public protocol APIConfigurating {
	/// Base url of the api.
	var baseURL: String {get }
}

/// Remote server configuration providing the `api`  and `websocket` services.
public struct APIConfiguration: APIConfigurating {
	public let baseURL: String
	public init(baseURL: String) {
		self.baseURL = baseURL
	}
}
