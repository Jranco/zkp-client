//
//  FiatShamirFactory.swift
//  zkp-client
//
//  Created by Thomas Segkoulis on 26.01.24.
//

import Foundation

/// A factory creating an instance of the basic `Fiat-Shamir` zero-knowledge protocol flavor.
/// The `factory method` returns the respective `ZeroKnowledgeProtocol` implementation.
struct FiatShamirFactory: ZKPFlavorFactoryProtocol {
	/// Config parameters required by the protocol.
	var zkpConfig: FiatShamir.Config
	/// Remote server configuration providing the `api`  and `websocket` services.
	var apiConfig: APIConfigurating
	/// Unique user identifier.
	var userID: String

	func createZKP() throws -> any ZeroKnowledgeProtocol {
		try FiatShamir(
			userID: userID,
			secretManager: SecretManager(), 
			secureStorage: KeychainManager(userID: userID),
			configuration: zkpConfig,
			apiConfig: apiConfig
		)
	}
}
