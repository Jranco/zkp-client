//
//  ZKPClient.swift
//  zkp-client
//
//  Created by Thomas Segkoulis on 21.01.24.
//

import Foundation

/// Executes a zero-knowledge identification scheme.
public struct ZKPClient {

	// MARK: - Private properties

	private var znp: any ZeroKnowledgeProtocol

	// MARK: - Initialization

	/// Creates a client to execute a zero-knowledge identification scheme.
	/// - Parameters:
	///   - flavor: The various types of the supported zero-knowledge protocols. The respective configurations may vary, thus the usage of the associated values.
	///   - apiConfig: Remote server configuration providing the `api`  and `websocket` services.
	///   - userID: Unique user identifier.
	public init(
		flavor: ZkpFlavor,
		apiConfig: APIConfigurating,
		userID: String
	) throws {
		let builder = ZKPFlavorBuilder(flavor: flavor,
									   apiConfig: apiConfig,
									   userID: userID)
		self.znp = try builder.createZKP()
	}

// TODO: return result in both requests
	
	/// Executes a `registration` request.
	/// Along with the registration payload it sends initial device secrets to be able to execute the identification scheme later during authentication.
	/// - Parameters:
	///   - payload: The registration payload required by the target api.
	public func sendRegistration(payload: Data) async throws {
		try await znp.register(payload: payload)
	}

	/// Executes an `authentication` request.
	/// Along with the authentication payload it sends device's public key to be able to select the already `binded` device and initate the `zkp` verification process.
	/// - Parameters:
	///   - payload: The registration payload required by the target api.
	public func sendAuthentication(payload: Data) async throws {
		try await znp.authenticate(payload: payload)
	}
	
	public func getDevicePublicKey() throws -> Data {
		try znp.fetchDeviceKey()
	}
}
