//
//  WSConnectionConfig.swift
//  zkp-client
//
//  Created by Thomas Segkoulis on 25.01.24.
//

/// Configuration of the remote `web-socket` service performing the `zkp`identification.
/// It encapsulates the payload of the request that requires additional device identification.
struct WSConnectionConfig {
	/// The target url's path.
	let path: String
}
