//
//  ZeroKnowledgeProtocol.swift
//  zkp-client
//
//  Created by Thomas Segkoulis on 21.01.24.
//

import Foundation

protocol ZeroKnowledgeProtocol {
	
	associatedtype Key: Codable

	/// Executes CRUD operations regarding user's and device's secrets.
	var secretManager: SecretManaging { get }

	/// Calculates and returns the public key to be used by the respective zero knowledge protocol.
	/// It uses all the secrets inserted by the user along with locally generated unique device identifiers.
	///
	/// - Returns: The public key in raw bytes.
	func calculatePublicKey() throws -> Key

	/// Sends initial user registration payload attaching the `ZKP` public key.
	/// This `ZKP` public key will be used in the follow up authentication requests verifying that the sender is
	/// an eligible device.
	/// - Parameters:
	///   - payload: The registration payload required by the target api.
	///   - userID: Unique user identifier.
	func register(payload: Data, userID: String) async throws

	func authenticate(payload: Data, userID: String) async throws
}
