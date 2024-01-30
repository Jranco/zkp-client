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
		config: Config
	) throws {
		let builder = ZKPFlavorBuilder(flavor: flavor, connectionConfig: config)
		self.znp = try builder.createZKP()
	}

	/// Executes a `registration` request.
	/// Along with the registration payload it sends initial device secrets to be able to execute the identification scheme later during authentication.
	/// - Parameters:
	///   - payload: The registration payload required by the target api.
	///   - userID: Unique user identifier.
	public func sendRegistration(payload: Data, userID: String) throws {
		Task {
			do {
				try await znp.register(payload: payload, userID: userID)
				print("--- did register with success")
			} catch {
				print("--- error registering: \(error.localizedDescription)")
			}
		}
	}

	/// Executes an `authentication` request.
	/// Along with the authentication payload it sends device's public key to be able to select the already `binded` device and initate the `zkp` verification process.
	/// - Parameters:
	///   - payload: The registration payload required by the target api.
	///   - userID: Unique user identifier.
	public func sendAuthentication(payload: Data, userID: String) throws {
		Task {
			do {
				try await znp.authenticate(payload: payload, userID: userID)
			} catch {
				print("--- error authenticating: \(error.localizedDescription)")
			}
		}
	}
}

protocol ConnectionConfig {
	var baseURL: String {get }
}

public extension ZKPClient {
	struct Config: ConnectionConfig {
		let baseURL: String
		
		public init(baseURL: String) {
			self.baseURL = baseURL
		}
	}
}
