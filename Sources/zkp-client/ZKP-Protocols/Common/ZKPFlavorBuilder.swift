//
//  ZKPFlavorBuilder.swift
//  zkp-client
//
//  Created by Thomas Segkoulis on 26.01.24.
//

import Foundation

/// Creates and returns the respective `zero-knowledge` protocol implementation given the required flavor.
struct ZKPFlavorBuilder: ZKPFlavorFactoryProtocol {
	/// The type of the supported zero-knowledge protocols. It contains additional required configuration.
	var flavor: ZkpFlavor
	/// Configuration of the remote service performing the `zkp`identification.
	var connectionConfig: ZKPClient.Config
	/// Returns the respective `zero-knowledge` flavor implementation.
	var factory: ZKPFlavorFactoryProtocol {
		switch flavor {
		case .fiatShamir(let config):
			FiatShamirFactory(zkpConfig: config, connectionConfig: connectionConfig)
		}
	}

	// MARK: - ZKPFlavorFactoryProtocol

	func createZKP() throws -> any ZeroKnowledgeProtocol {
		return try factory.createZKP()
	}
}
