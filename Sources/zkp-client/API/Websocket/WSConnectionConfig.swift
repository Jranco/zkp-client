//
//  WSConnectionConfig.swift
//  zkp-client
//
//  Created by Thomas Segkoulis on 25.01.24.
//

/// Configuration of the remote `web-socket` service performing the `zkp`verification.
protocol WSConnectionConfig {
	associatedtype PayloadType: Codable
	var base: String { get }
	var path: String { get }
}
