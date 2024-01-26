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
	///   - conectionConfig: Configuration of the remote `web-socket` service performing the `zkp`identification.
	public init(
		flavor: ZkpFlavor,
		conectionConfig: WSConnectionConfig
	) throws {
		let builder = ZKPFlavorBuilder(flavor: flavor, connectionConfig: conectionConfig)
		self.znp = try builder.createZKP()
	}

	/// Executes a `registration` request.
	/// Along with the registration payload it sends initial device secrets to be able to execute the identification scheme later during authentication.
	/// - Parameters:
	///   - payload: The registration payload required by the target api.
	///   - userID: Unique user identifier.
	public func sendRegistration(payload: Data, userID: String) throws {
		try znp.register(payload: payload, userID: userID)
	}
}
