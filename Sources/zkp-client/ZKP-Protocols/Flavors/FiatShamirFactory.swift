//
//  FiatShamirFactory.swift
//  zkp-client
//
//  Created by Thomas Segkoulis on 26.01.24.
//

import Foundation

/// A factory creating an instance of the basic `Fiat-Shamir` zero-knowledge protocol flavor.
struct FiatShamirFactory: ZKPFlavorFactoryProtocol {
	/// Config parameters required by the protocol.
	var zkpConfig: FiatShamir.Config
	/// Configuration of the remote service performing the `zkp`identification.
	var connectionConfig: ZKPClient.Config

	func createZKP() throws -> any ZeroKnowledgeProtocol {
//		let connection = try WSConnection(config: connectionConfig, path: "/register")
		return try FiatShamir(secretManager: SecretManager(), configuration: zkpConfig, config: connectionConfig)
	}
}
