//
//  WSUserAuthentication.swift
//  zkp-client
//
//  Created by Thomas Segkoulis on 28.01.24.
//

import Foundation

/// A `WebSocket` connection authenticating a user.
struct WSUserAuthentication: WSConnectionConfig {
	typealias PayloadType = String

	var base: String
	var path: String
}
