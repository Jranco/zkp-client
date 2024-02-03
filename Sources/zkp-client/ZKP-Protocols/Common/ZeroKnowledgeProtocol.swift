//
//  ZeroKnowledgeProtocol.swift
//  zkp-client
//
//  Created by Thomas Segkoulis on 21.01.24.
//

import Foundation

/// A protocol defining requirements and operations of a zero knowledge implementation.
/// It could be a interactive or non-interactive scheme using the device's and user's secrets to identify the requesting device (`claimer`).
protocol ZeroKnowledgeProtocol {

	/// Sends initial user registration payload attaching the `ZKP` public key.
	/// This `ZKP` public key will be used in the follow up authentication requests verifying that the sender is
	/// an eligible device.
	/// - Parameters:
	///   - payload: The registration payload required by the target api.
	func register(payload: Data) async throws

	/// Sends a user authentication payload executing the `ZKP` identification scheme.
	///	The `ZKP` identification scheme ensures the device is an eligible one guarding the actual authentication.
	/// - Parameters:
	///   - payload: The registration payload required by the target api.
	func authenticate(payload: Data) async throws
}
